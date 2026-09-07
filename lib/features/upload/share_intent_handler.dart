import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

const _methodChannel = MethodChannel('com.ventoux.paperlessgo/share');
const _eventChannel = EventChannel('com.ventoux.paperlessgo/share_stream');

/// A file shared into the app, resolved natively via ContentResolver
/// (see android/.../SharePlugin.kt — not receive_sharing_intent, whose
/// legacy path lookup fails for SAF DocumentsProvider content:// URIs).
@immutable
class SharedFile {
  const SharedFile({required this.path, required this.filename, this.mimeType});

  final String path;
  final String filename;
  final String? mimeType;

  bool get isImage => mimeType?.startsWith('image/') ?? false;

  factory SharedFile.fromJson(Map<String, dynamic> json) => SharedFile(
        path: json['path'] as String? ?? '',
        filename: json['filename'] as String? ?? '',
        mimeType: json['mimeType'] as String?,
      );
}

/// One delivery from the native side: the files it could read, and how
/// many the intent actually carried. The gap between the two is a file the
/// user handed us that we could not open (a provider that refused the read,
/// a grant that did not arrive) — and that must be said out loud, not
/// swallowed into "the app just opened on its start screen".
@immutable
class ShareBatch {
  const ShareBatch({required this.files, required this.requested});

  final List<SharedFile> files;
  final int requested;

  int get unreadable => requested - files.length;
}

/// Parses the `{files, requested}` payload SharePlugin.kt emits on both
/// channels. A payload that is not JSON is treated as no share at all
/// rather than thrown from inside a channel callback.
@visibleForTesting
ShareBatch parseShare(String raw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException catch (e) {
    debugPrint('Share payload was not JSON: $e');
    return const ShareBatch(files: [], requested: 0);
  }
  final map = decoded as Map<String, dynamic>;
  final files = (map['files'] as List<dynamic>? ?? const [])
      .map((e) => SharedFile.fromJson(e as Map<String, dynamic>))
      .toList();
  return ShareBatch(
    files: files,
    requested: map['requested'] as int? ?? files.length,
  );
}

class ShareIntentHandler {
  StreamSubscription? _subscription;
  bool _initialized = false;
  final GlobalKey<NavigatorState> _navigatorKey;
  final bool Function() _isAuthenticated;
  /// Outcomes waiting for a Navigator, a resumed lifecycle, or a login.
  /// A list, in arrival order: a notice for a file that failed to copy must
  /// never displace a route for one that copied fine.
  final List<ShareOutcome> _pending = [];

  ShareIntentHandler(this._navigatorKey, this._isAuthenticated);

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Handle shared files when app is already running
    _subscription = _eventChannel.receiveBroadcastStream().listen((raw) {
      _handleShare(parseShare(raw as String));
    });

    // Handle shared files when app is opened via share
    _methodChannel.invokeMethod<String>('getInitialShare').then((raw) {
      if (raw == null) return;
      _handleShare(parseShare(raw));
    });
  }

  void _handleShare(ShareBatch batch) {
    final route = resolveShare(batch);
    if (route == null) return;

    // #24: a share/open-with arriving while logged out must not push
    // straight through onto /login. Queue it and wait for flushPendingShare()
    // once login succeeds, called by the app shell on the auth transition.
    if (!_isAuthenticated()) {
      _pending.add(route);
      return;
    }

    _pushRoute(route);
  }

  /// Pushes a share that arrived while logged out, or while the app
  /// lifecycle hadn't settled back to `resumed` yet. Call once auth state
  /// transitions to authenticated, or once the app lifecycle transitions
  /// to resumed.
  void flushPendingShare() {
    if (_pending.isEmpty) return;
    final queued = List<ShareOutcome>.of(_pending);
    _pending.clear();
    // _pushRoute may re-queue an item if the app is still not ready; the
    // list keeps arrival order either way.
    for (final outcome in queued) {
      _pushRoute(outcome);
    }
  }

  void _pushRoute(ShareOutcome route) {
    final context = _navigatorKey.currentContext;
    // No Navigator yet (first frame still building): keep the share for the
    // same resume/auth flush the branches below use, rather than dropping
    // it with nothing to show for a file the user just handed us.
    if (context == null || !context.mounted) {
      _pending.add(route);
      // Nothing else is guaranteed to fire once the Navigator exists (auth
      // may already be settled, the lifecycle already resumed), so retry on
      // the next frame ourselves.
      WidgetsBinding.instance.addPostFrameCallback((_) => flushPendingShare());
      return;
    }
    // A share/open-with arriving via onNewIntent on a warm resume (task
    // switched back to via "Open with") reaches here while the app
    // lifecycle is still `inactive` — measured on a Pixel 9 Pro Fold,
    // context.push() "succeeds" (no exception, mounted context, a frame
    // even fires) but the navigation is silently lost by the time the
    // render pipeline finishes reattaching on resume. Queue it and retry
    // once resumed, same mechanism #24 uses for the auth-gating case.
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      _pending.add(route);
      return;
    }
    // Notices go through the MaterialApp's root ScaffoldMessenger, reached
    // from the root navigator context. Every shell route has a Scaffold, so
    // the SnackBar always has somewhere to render; a route without one would
    // trip showSnackBar's assertion, which is why the tests give theirs one.
    switch (route) {
      case ShareRoute(:final location, :final extra, :final unreadable):
        context.push(location, extra: extra);
        if (unreadable > 0) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text(partialShareMessage(unreadable))),
          );
        }
      case ShareUnreadable(:final count):
        // Nothing to navigate to. Say so where the user is looking.
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(unreadableShareMessage(count))),
        );
    }
  }

  void dispose() {
    _subscription?.cancel();
  }

  @visibleForTesting
  void debugHandleSharedFiles(List<SharedFile> files) =>
      _handleShare(ShareBatch(files: files, requested: files.length));

  @visibleForTesting
  void debugHandleShare(ShareBatch batch) => _handleShare(batch);

  @visibleForTesting
  ShareOutcome? get debugPendingRoute => _pending.firstOrNull;

  @visibleForTesting
  List<ShareOutcome> get debugPending => List.unmodifiable(_pending);
}

/// What a share turned into: somewhere to go, or something to say.
@immutable
sealed class ShareOutcome {
  const ShareOutcome();
}

/// The navigation target resolved from a batch of shared files.
class ShareRoute extends ShareOutcome {
  const ShareRoute(this.location, {this.extra, this.unreadable = 0});

  final String location;
  final Object? extra;

  /// Files in the same share that could not be read. The readable ones are
  /// routed; this many are reported as skipped once the screen is up.
  final int unreadable;
}

/// The intent carried [count] file(s) and none could be read.
class ShareUnreadable extends ShareOutcome {
  const ShareUnreadable(this.count);

  final int count;
}

String partialShareMessage(int count) => count == 1
    ? '1 shared file could not be read and was skipped.'
    : '$count shared files could not be read and were skipped.';

String unreadableShareMessage(int count) => count == 1
    ? 'Could not read the shared file. Try sharing it again from the app '
        'it came from.'
    : 'Could not read the $count shared files. Try sharing them again from '
        'the app they came from.';

/// Resolves a whole delivery: a route when anything was readable, a notice
/// when the intent carried files but none could be read, null for nothing.
ShareOutcome? resolveShare(ShareBatch batch) {
  final route = resolveShareRoute(batch.files);
  if (route != null) {
    return ShareRoute(
      route.location,
      extra: route.extra,
      unreadable: batch.unreadable,
    );
  }
  if (batch.requested > 0) return ShareUnreadable(batch.requested);
  return null;
}

/// Decide where shared files should go.
///
/// Images — one or many — are routed into the scan pipeline
/// (`/scan/review` → enhance → PDF) so they get wrapped into a PDF before
/// upload, matching the in-app scanner flow. A non-image file (PDF, etc.) is
/// uploaded directly as-is. Routing keys off the file *type*, not the file
/// *count*, so a single shared image still launches the PDF pipeline.
///
/// Returns null when there is nothing valid to handle.
ShareRoute? resolveShareRoute(List<SharedFile> files) {
  // Filter to files with valid paths.
  final validFiles = files.where((f) => f.path.isNotEmpty).toList();
  if (validFiles.isEmpty) return null;

  final imagePaths =
      validFiles.where((f) => f.isImage).map((f) => f.path).toList();

  if (imagePaths.isNotEmpty) {
    // One or more images → multi-page scan/enhance/PDF pipeline.
    return ShareRoute('/scan/review', extra: imagePaths);
  }

  // No images: upload the first non-image file (e.g. a PDF) directly.
  final file = validFiles.first;
  return ShareRoute(
    '/scan/upload',
    extra: {'filePath': file.path, 'filename': file.filename},
  );
}
