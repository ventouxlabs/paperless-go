import 'dart:io';

import 'package:saf/saf.dart';

import '../auth/secure_storage.dart';

/// A canonical identity for a SAF tree grant.
///
/// `pickDirectory()` returns a URI in `tree/<id>/document/<id>` form while
/// `persistedPermissions()` reports the bare `tree/<id>` form, so the two can
/// never be compared with `==`. Keying on the decoded tree id sidesteps both
/// that mismatch and any percent-encoding differences between the two sources.
class SafTreeKey {
  final String scheme;
  final String authority;
  final String treeId;

  const SafTreeKey({
    required this.scheme,
    required this.authority,
    required this.treeId,
  });

  /// Returns the grant key for [uri], or null if it is not a SAF tree URI.
  static SafTreeKey? parse(String? uri) {
    if (uri == null || uri.isEmpty) return null;
    final parsed = Uri.tryParse(uri);
    if (parsed == null) return null;
    final segments = parsed.pathSegments;
    if (segments.length < 2 || segments[0] != 'tree') return null;
    if (segments[1].isEmpty) return null;
    return SafTreeKey(
      scheme: parsed.scheme,
      authority: parsed.authority,
      treeId: segments[1],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SafTreeKey &&
      other.scheme == scheme &&
      other.authority == authority &&
      other.treeId == treeId;

  @override
  int get hashCode => Object.hash(scheme, authority, treeId);
}

/// Whether a configured downloads folder is usable right now.
enum DestinationStatus {
  /// No folder has been chosen yet.
  unset,

  /// A folder is configured and the OS still grants write access.
  ready,

  /// A folder was configured but its grant is gone (revoked, uninstalled SD
  /// card, cleared defaults). The user must pick again.
  unavailable,
}

/// The resolved state of the configured downloads destination.
class ExportDestination {
  final DestinationStatus status;

  /// The stored SAF URI, present whenever a folder was ever configured.
  final String? uri;

  /// The folder's display name, for showing in the UI.
  final String? name;

  const ExportDestination._({required this.status, this.uri, this.name});

  const ExportDestination.unset() : this._(status: DestinationStatus.unset);

  const ExportDestination.ready({required String uri, String? name})
      : this._(status: DestinationStatus.ready, uri: uri, name: name);

  const ExportDestination.unavailable({required String uri, String? name})
      : this._(status: DestinationStatus.unavailable, uri: uri, name: name);

  bool get isReady => status == DestinationStatus.ready;

  /// Display text for a settings row or prompt.
  String get displayName => name?.isNotEmpty == true ? name! : 'Selected folder';
}

/// Raised when a save to the chosen folder cannot be completed.
///
/// SAF failures are not `DioException`s, so `friendlyApiMessage` would flatten
/// them into a generic API error and discard the actionable "reselect the
/// folder" signal.
class ExportSaveException implements Exception {
  final String message;

  /// True when the folder itself is the problem, so the caller should offer to
  /// pick a new one rather than just reporting a failure.
  final bool needsReselect;

  const ExportSaveException(this.message, {this.needsReselect = false});

  @override
  String toString() => message;
}

/// Resolves [storedUri] against the grants the OS actually still holds.
///
/// Pure so it can be unit tested without a device: callers pass in the list
/// from `Saf.persistedPermissions()`.
ExportDestination resolveDestination({
  required String? storedUri,
  required String? storedName,
  required List<SafPersistedPermission> permissions,
}) {
  final key = SafTreeKey.parse(storedUri);
  if (key == null) return const ExportDestination.unset();

  final granted = permissions.any(
    (p) => p.write && SafTreeKey.parse(p.uri) == key,
  );

  return granted
      ? ExportDestination.ready(uri: storedUri!, name: storedName)
      : ExportDestination.unavailable(uri: storedUri!, name: storedName);
}

/// Strips characters that SAF providers reject in a document name.
///
/// A deny-list rather than the word-character allow-list `documentDownload`
/// used to apply to the temp file: an allow-list erases every non-ASCII
/// title (`Rechnung Müller` -> `Rechnung Mller`), and that mangled name is
/// now visible to the user in the folder they picked rather than hidden in
/// an app-private cache path. Also caps length — some SAF providers reject a
/// display name past ~255 bytes, and a long title plus a suffix like
/// `_compressed.pdf` can get there.
String sanitizeExportName(String title, {required String fallback}) {
  final safe = title.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '').trim();
  final result = safe.isEmpty ? fallback : safe;
  return result.length > 100 ? result.substring(0, 100) : result;
}

/// Saves already-downloaded local files into a user-chosen SAF folder.
class ExportDestinationService {
  final SecureStorageService _storage;
  final Saf _saf;

  ExportDestinationService({
    required SecureStorageService storage,
    Saf? saf,
  })  : _storage = storage,
        _saf = saf ?? Saf();

  /// Reads the stored destination and validates it against live OS grants.
  ///
  /// A folder was configured (there is a stored [uri]), so a SAF failure
  /// here is reported as `unavailable`, not `unset` — the UI should say
  /// "no longer available", not lie that nothing was ever chosen.
  Future<ExportDestination> resolve() async {
    final uri = await _storage.getDownloadsUri();
    if (uri == null || uri.isEmpty) return const ExportDestination.unset();
    final name = await _storage.getDownloadsName();
    try {
      final permissions = await _saf.persistedPermissions();
      return resolveDestination(
        storedUri: uri,
        storedName: name,
        permissions: permissions,
      );
    } on SafException {
      return ExportDestination.unavailable(uri: uri, name: name);
    }
  }

  /// Prompts for a folder and persists it once the grant is confirmed.
  ///
  /// Returns null if the user cancelled. The plugin swallows a failed
  /// `takePersistableUriPermission`, so the grant is re-read rather than
  /// assumed from a successful pick. A SAF failure at either platform call
  /// (picker busy, no DocumentsUI on the device, etc.) is translated to
  /// [ExportSaveException] rather than escaping raw, since callers only
  /// handle that type.
  Future<ExportDestination?> chooseFolder() async {
    final SafDocumentFile? picked;
    try {
      picked = await _saf.pickDirectory();
    } on SafException catch (e) {
      throw ExportSaveException(
        'Could not open the folder picker: ${e.message}',
      );
    }
    if (picked == null) return null;

    final List<SafPersistedPermission> permissions;
    try {
      permissions = await _saf.persistedPermissions();
    } on SafException catch (e) {
      throw ExportSaveException(
        'Could not confirm folder access: ${e.message}',
      );
    }

    final resolved = resolveDestination(
      storedUri: picked.uri,
      storedName: picked.name,
      permissions: permissions,
    );

    if (!resolved.isReady) {
      throw const ExportSaveException(
        'Android did not grant lasting access to that folder. Try another one.',
      );
    }

    // Release the superseded grant so switching folders doesn't accumulate
    // persisted permissions against Android's per-package cap.
    final previousUri = await _storage.getDownloadsUri();
    if (previousUri != null &&
        previousUri.isNotEmpty &&
        SafTreeKey.parse(previousUri) != SafTreeKey.parse(picked.uri)) {
      try {
        await _saf.releasePersistedPermission(previousUri);
      } on SafException {
        // Already released or revoked by the OS — nothing to undo.
      }
    }

    await _storage.saveDownloadsUri(picked.uri);
    await _storage.saveDownloadsName(picked.name);
    return resolved;
  }

  /// Clears the configured folder and releases the OS-held write grant.
  ///
  /// Clearing only the stored hint would leave the app holding a live
  /// persisted write grant on the folder even though Settings tells the
  /// user "Downloads will ask each time" — a least-privilege mismatch.
  Future<void> forget() async {
    final uri = await _storage.getDownloadsUri();
    await _storage.clearDownloadsDestination();
    if (uri != null && uri.isNotEmpty) {
      try {
        await _saf.releasePersistedPermission(uri);
      } on SafException {
        // Already released or revoked by the OS — nothing to undo.
      }
    }
  }

  /// Copies [localPath] into the configured folder, returning the name the
  /// file actually landed under.
  ///
  /// SAF auto-renames on collision (`invoice (1).pdf`), so no existing
  /// document is ever truncated. Throws [ExportSaveException] with
  /// `needsReselect` set when the folder is not usable.
  ///
  /// [known] skips re-resolving when the caller has just validated the folder
  /// — a bulk save would otherwise make one platform round-trip per file.
  Future<String> saveToDestination({
    required String localPath,
    required String fileName,
    String mimeType = 'application/pdf',
    ExportDestination? known,
  }) async {
    final destination = known ?? await resolve();
    if (destination.status == DestinationStatus.unset) {
      throw const ExportSaveException(
        'No download folder chosen yet.',
        needsReselect: true,
      );
    }
    if (destination.status == DestinationStatus.unavailable) {
      throw const ExportSaveException(
        'That download folder is no longer available.',
        needsReselect: true,
      );
    }

    // The native side throws the same SafNotFoundException for "source file
    // is gone" as for "destination folder is gone" (e.g. the temp file was
    // evicted from cache while the folder picker backgrounded the app).
    // Checked up front so that case is never misreported as a folder
    // problem — re-picking a folder would not fix a missing source file.
    if (!await File(localPath).exists()) {
      throw const ExportSaveException(
        'The downloaded file is no longer available. Try again.',
      );
    }

    try {
      final written = await _saf.pasteLocalFile(
        localPath,
        destination.uri!,
        fileName,
        mimeType,
      );
      return written.name;
    } on SafPermissionException {
      throw const ExportSaveException(
        'Access to the download folder was revoked.',
        needsReselect: true,
      );
    } on SafNotFoundException {
      throw const ExportSaveException(
        'The download folder no longer exists.',
        needsReselect: true,
      );
    } on SafException catch (e) {
      throw ExportSaveException('Could not save the file: ${e.message}');
    }
  }
}
