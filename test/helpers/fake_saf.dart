import 'package:saf/saf.dart';

/// A controllable [Saf] double: every plugin call the export service touches
/// can be made to succeed, return null (user cancelled), or throw.
///
/// [pasteErrors] is consumed one entry per `pasteLocalFile` call (null means
/// "succeed"), so a batch can fail on a specific file; once drained, calls
/// fall back to [pasteError].
class FakeSaf extends Saf {
  SafDocumentFile? pickResult;
  Object? pickError;
  List<SafPersistedPermission> permissions = [];
  Object? permissionsError;
  Object? pasteError;
  List<Object?> pasteErrors = [];
  Object? releaseError;
  final released = <String>[];
  final pasted = <({String src, String dir, String name})>[];
  int pickCalls = 0;

  /// Runs before each paste with its 0-based call index, so a test can
  /// change [permissions] mid-batch the way a real revocation would.
  void Function(int callIndex)? onPaste;
  int _pasteCalls = 0;

  @override
  Future<SafDocumentFile?> pickDirectory({
    String? initialUri,
    bool writePermission = true,
    bool persistablePermission = true,
  }) async {
    pickCalls++;
    if (pickError != null) throw pickError!;
    return pickResult;
  }

  @override
  Future<List<SafPersistedPermission>> persistedPermissions() async {
    if (permissionsError != null) throw permissionsError!;
    return permissions;
  }

  @override
  Future<void> releasePersistedPermission(String uri) async {
    released.add(uri);
    if (releaseError != null) throw releaseError!;
  }

  @override
  Future<SafDocumentFile> pasteLocalFile(
    String srcPath,
    String destDirUri,
    String name,
    String mime, {
    bool overwrite = false,
    SafProgressCallback? onProgress,
  }) async {
    onPaste?.call(_pasteCalls++);
    final error =
        pasteErrors.isNotEmpty ? pasteErrors.removeAt(0) : pasteError;
    if (error != null) throw error;
    pasted.add((src: srcPath, dir: destDirUri, name: name));
    return SafDocumentFile(
      uri: '$destDirUri/document/$name',
      name: name,
      isDir: false,
      length: 0,
      lastModified: 0,
    );
  }
}

/// The form `pickDirectory()` returns: `tree/<id>/document/<id>`.
const pickedTreeUri =
    'content://com.android.externalstorage.documents/tree/primary%3ADownload'
    '/document/primary%3ADownload';

/// The form `persistedPermissions()` reports: the bare `tree/<id>`.
const persistedTreeUri =
    'content://com.android.externalstorage.documents/tree/primary%3ADownload';

SafPersistedPermission grantFor(String uri, {bool write = true}) =>
    SafPersistedPermission(
      uri: uri,
      read: true,
      write: write,
      persistedTime: 0,
    );

SafDocumentFile pickedDir(String uri, {String name = 'Download'}) =>
    SafDocumentFile(
      uri: uri,
      name: name,
      isDir: true,
      length: 0,
      lastModified: 0,
    );
