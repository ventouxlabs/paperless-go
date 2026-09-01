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

List<SharedFile> _parseSharedFiles(String raw) {
  final decoded = jsonDecode(raw) as List<dynamic>;
  return decoded
      .map((e) => SharedFile.fromJson(e as Map<String, dynamic>))
      .toList();
}

class ShareIntentHandler {
  StreamSubscription? _subscription;
  bool _initialized = false;
  final GlobalKey<NavigatorState> _navigatorKey;
  final bool Function() _isAuthenticated;
  ShareRoute? _pendingRoute;

  ShareIntentHandler(this._navigatorKey, this._isAuthenticated);

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Handle shared files when app is already running
    _subscription = _eventChannel.receiveBroadcastStream().listen((raw) {
      _handleSharedFiles(_parseSharedFiles(raw as String));
    });

    // Handle shared files when app is opened via share
    _methodChannel.invokeMethod<String>('getInitialShare').then((raw) {
      if (raw == null) return;
      final files = _parseSharedFiles(raw);
      if (files.isNotEmpty) _handleSharedFiles(files);
    });
  }

  void _handleSharedFiles(List<SharedFile> files) {
    final route = resolveShareRoute(files);
    if (route == null) return;

    // #24: a share/open-with arriving while logged out must not push
    // straight through onto /login. Queue it and wait for flushPendingShare()
    // once login succeeds, called by the app shell on the auth transition.
    if (!_isAuthenticated()) {
      _pendingRoute = route;
      return;
    }

    _pushRoute(route);
  }

  /// Pushes a share that arrived while logged out, or while the app
  /// lifecycle hadn't settled back to `resumed` yet. Call once auth state
  /// transitions to authenticated, or once the app lifecycle transitions
  /// to resumed.
  void flushPendingShare() {
    final route = _pendingRoute;
    if (route == null) return;
    _pendingRoute = null;
    _pushRoute(route);
  }

  void _pushRoute(ShareRoute route) {
    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    // A share/open-with arriving via onNewIntent on a warm resume (task
    // switched back to via "Open with") reaches here while the app
    // lifecycle is still `inactive` — measured on a Pixel 9 Pro Fold,
    // context.push() "succeeds" (no exception, mounted context, a frame
    // even fires) but the navigation is silently lost by the time the
    // render pipeline finishes reattaching on resume. Queue it and retry
    // once resumed, same mechanism #24 uses for the auth-gating case.
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      _pendingRoute = route;
      return;
    }
    context.push(route.location, extra: route.extra);
  }

  void dispose() {
    _subscription?.cancel();
  }

  @visibleForTesting
  void debugHandleSharedFiles(List<SharedFile> files) => _handleSharedFiles(files);

  @visibleForTesting
  ShareRoute? get debugPendingRoute => _pendingRoute;
}

/// The navigation target resolved from a batch of shared files.
@immutable
class ShareRoute {
  const ShareRoute(this.location, {this.extra});

  final String location;
  final Object? extra;
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
