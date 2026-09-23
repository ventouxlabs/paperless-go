import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dio/dio.dart';

import '../../core/api/api_error_mapper.dart';
import '../../core/api/api_providers.dart';
import '../../core/api/upload_retry_policy.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/database/cache_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/pending_upload_store.dart';
import 'pdf/pdf_generator.dart';

part 'upload_notifier.g.dart';

enum UploadStatus { idle, uploading, processing, success, failure, queued }

class UploadState {
  final UploadStatus status;
  final String? taskId;
  final String? errorMessage;
  final double? progress;
  final int? documentId;

  const UploadState({
    this.status = UploadStatus.idle,
    this.taskId,
    this.errorMessage,
    this.progress,
    this.documentId,
  });

  UploadState copyWith({
    UploadStatus? status,
    String? taskId,
    String? errorMessage,
    double? progress,
    int? documentId,
  }) {
    // When status changes, clear stale fields from the previous state
    // to prevent the UI from showing e.g. an old errorMessage after retry.
    final newStatus = status ?? this.status;
    final statusChanged = newStatus != this.status;
    return UploadState(
      status: newStatus,
      taskId: taskId ?? this.taskId,
      errorMessage: statusChanged
          ? errorMessage
          : (errorMessage ?? this.errorMessage),
      progress: statusChanged ? progress : (progress ?? this.progress),
      documentId: documentId ?? this.documentId,
    );
  }
}

@Riverpod(keepAlive: true)
class UploadNotifier extends _$UploadNotifier {
  Timer? _pollTimer;
  bool _disposed = false;

  /// Temp PDF generated from scanned images, kept alive until polling reaches
  /// a terminal state so the source survives until the server confirms.
  String? _pendingTempPdf;

  @override
  UploadState build() {
    _disposed = false;
    ref.onDispose(() {
      _pollTimer?.cancel();
      _cleanupPendingTempFile();
      _disposed = true;
    });
    return const UploadState();
  }

  /// Convert scanned images to a single PDF and upload.
  Future<void> uploadScannedImages({
    required List<String> imagePaths,
    bool preProcessed = false,
    String? title,
    int? correspondent,
    int? documentType,
    List<int>? tags,
    DateTime? created,
  }) async {
    // A prior upload may still be polling on this keepAlive singleton. Stop it
    // and drop its deferred temp PDF before starting a new one, otherwise the
    // old temp file is orphaned when _pendingTempPdf is overwritten below.
    _pollTimer?.cancel();
    _cleanupPendingTempFile();
    state = const UploadState(status: UploadStatus.uploading);

    String? pdfPath;
    String? safeFilename;
    try {
      pdfPath = await _imagesToPdf(imagePaths, preProcessed: preProcessed);
      safeFilename = _safeFilename(title ?? 'scan');

      final api = ref.read(paperlessApiProvider);
      final taskId = await api.uploadDocument(
        filePath: pdfPath,
        filename: '$safeFilename.pdf',
        title: title,
        correspondent: correspondent,
        documentType: documentType,
        tags: tags,
        created: created,
        onSendProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(progress: sent / total);
          }
        },
      );

      // Defer temp PDF cleanup until polling reaches a terminal state. The
      // bytes are already on the server, but keeping the source until the
      // server confirms processing leaves room to retry a failed job.
      _pendingTempPdf = pdfPath;

      state = UploadState(status: UploadStatus.processing, taskId: taskId);

      _startPolling(taskId);
    } on PdfPageDecodeException catch (e) {
      // Thrown by _imagesToPdf before any file is written, so there is no
      // pdfPath to clean up here. friendlyApiMessage() has no mapping for
      // this type and would otherwise show its generic fallback, swallowing
      // the specific "page N could not be read" message.
      state = UploadState(
        status: UploadStatus.failure,
        errorMessage: e.message,
      );
    } catch (e) {
      // Clean up temp PDF on failure too (unless queuing for later)
      if (shouldQueueForLater(e) && pdfPath != null && safeFilename != null) {
        await _enqueueForLater(
          filePath: pdfPath,
          filename: '$safeFilename.pdf',
          title: title,
          correspondent: correspondent,
          documentType: documentType,
          tags: tags,
          created: created,
        );
        return;
      }
      if (pdfPath != null) _deleteTempFile(pdfPath);
      state = UploadState(
        status: UploadStatus.failure,
        errorMessage: friendlyApiMessage(e),
      );
    }
  }

  /// Upload a file directly (from file picker).
  Future<void> uploadFile({
    required String filePath,
    required String filename,
    String? title,
    int? correspondent,
    int? documentType,
    List<int>? tags,
    DateTime? created,
  }) async {
    state = const UploadState(status: UploadStatus.uploading);

    try {
      final api = ref.read(paperlessApiProvider);
      final taskId = await api.uploadDocument(
        filePath: filePath,
        filename: filename,
        title: title,
        correspondent: correspondent,
        documentType: documentType,
        tags: tags,
        created: created,
        onSendProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(progress: sent / total);
          }
        },
      );

      state = UploadState(status: UploadStatus.processing, taskId: taskId);

      _startPolling(taskId);
    } catch (e) {
      if (shouldQueueForLater(e)) {
        await _enqueueForLater(
          filePath: filePath,
          filename: filename,
          title: title,
          correspondent: correspondent,
          documentType: documentType,
          tags: tags,
          created: created,
        );
        return;
      }
      state = UploadState(
        status: UploadStatus.failure,
        errorMessage: friendlyApiMessage(e),
      );
    }
  }

  /// Whether a failed upload should be parked in the queue rather than
  /// surfaced as a dead end.
  ///
  /// Delegates to [isUnreachableServerError] so this and the drain's
  /// retry-accounting cannot drift apart — they have to agree on what counts as
  /// "the server was unreachable" or a document either gets dropped here or
  /// burns retries there.
  static bool shouldQueueForLater(Object e) => isUnreachableServerError(e);

  Future<void> _enqueueForLater({
    required String filePath,
    required String filename,
    String? title,
    int? correspondent,
    int? documentType,
    List<int>? tags,
    DateTime? created,
  }) async {
    // Nothing below may throw past this method. It runs inside the catch block
    // of a failed upload, so an escaping exception would skip the state
    // assignment entirely and leave the screen spinning on `uploading` forever
    // — with the file neither uploaded, nor queued, nor reported.
    if (!await File(filePath).exists()) {
      state = const UploadState(
        status: UploadStatus.failure,
        errorMessage: 'The file is no longer available on this device.',
      );
      return;
    }

    // The queue holds a bare path, and every path that reaches here points at
    // evictable storage — Android's cacheDir for shares, getTemporaryDirectory
    // for generated PDFs. Copy into app-private documents storage first, or a
    // document queued overnight can be deleted by the OS before the retry.
    var queuedPath = filePath;
    try {
      final store = await ref.read(pendingUploadStoreProvider.future);
      queuedPath = await store.persist(filePath);
    } on FileSystemException catch (_) {
      // Out of space. Queue the original path anyway: an evictable copy is a
      // worse guarantee than a durable one, but far better than dropping it.
    } catch (e) {
      // Storage unavailable entirely — getApplicationDocumentsDirectory throws
      // MissingPlatformDirectoryException, and a missing plugin registration
      // throws MissingPluginException. Both `implements Exception` rather than
      // extending FileSystemException, so the narrow catch above lets them
      // through, out of the catch block this method runs inside, and the
      // screen stays on `uploading` forever. Same fallback: queue the original.
      assert(() {
        debugPrint('Pending-upload store unavailable: $e');
        return true;
      }());
    }

    try {
      final cache = ref.read(cacheRepositoryProvider);
      await cache.enqueueUpload(
        filePath: queuedPath,
        filename: filename,
        // Binds the row to the account it was queued for. Switching profiles
        // triggers a drain, and without this the drain would send it to
        // whichever server is active then.
        serverUrl: ref.read(authStateProvider).valueOrNull?.serverUrl,
        title: title,
        correspondent: correspondent,
        documentType: documentType,
        tags: tags,
        created: created,
      );
      state = const UploadState(status: UploadStatus.queued);
    } catch (e) {
      // Catches Error too, not just Exception: a drift failure here surfaces as
      // a StateError, which `on Exception` would let escape and wedge the UI.
      //
      // Release the persisted copy first. No queue row references it now, so
      // neither a successful drain nor terminal-failure cleanup could ever
      // reach it — it would sit in app-documents storage, holding the user's
      // document, until they cleared app data.
      if (queuedPath != filePath) {
        try {
          final store = await ref.read(pendingUploadStoreProvider.future);
          await store.discard(queuedPath);
        } catch (_) {
          // Best effort; the enqueue failure below is what the user sees.
        }
      }
      state = UploadState(
        status: UploadStatus.failure,
        errorMessage: friendlyApiMessage(
          e,
          fallback: 'Could not save the upload for later.',
        ),
      );
    }
  }

  static const _maxPollAttempts = 150; // 150 * 2s = 5 minutes

  void _startPolling(String taskId) {
    _pollTimer?.cancel();
    var attempts = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_disposed) {
        timer.cancel();
        return;
      }
      attempts++;
      if (attempts > _maxPollAttempts) {
        timer.cancel();
        _cleanupPendingTempFile();
        state = UploadState(
          status: UploadStatus.failure,
          taskId: taskId,
          errorMessage:
              'Processing timed out after 5 minutes. The document may still be processing on the server.',
        );
        return;
      }
      try {
        final api = ref.read(paperlessApiProvider);
        final result = await api.getTaskStatus(taskId);
        final status = result['status'] as String? ?? 'PENDING';

        if (status == 'SUCCESS') {
          timer.cancel();
          _cleanupPendingTempFile();
          final rawDocId = result['related_document'];
          final docId = rawDocId is int
              ? rawDocId
              : rawDocId is String
                  ? int.tryParse(rawDocId)
                  : null;
          state = UploadState(
            status: UploadStatus.success,
            taskId: taskId,
            documentId: docId,
          );
          NotificationService.showUploadComplete(
            title: 'Document processed',
            body: 'Your document has been added to Paperless.',
          );
        } else if (status == 'FAILURE') {
          timer.cancel();
          _cleanupPendingTempFile();
          final errorMsg =
              result['result'] as String? ?? 'Upload processing failed';
          state = UploadState(
            status: UploadStatus.failure,
            taskId: taskId,
            errorMessage: errorMsg,
          );
          NotificationService.showUploadFailed(
            title: 'Document processing failed',
            error: errorMsg,
          );
        }
        // PENDING / STARTED → keep polling
      } on DioException catch (e) {
        // Stop polling on auth errors — token likely expired or revoked.
        // Continuing to poll would just waste 5 minutes of retries.
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          timer.cancel();
          _cleanupPendingTempFile();
          state = UploadState(
            status: UploadStatus.failure,
            taskId: taskId,
            errorMessage:
                'Authentication error while checking status. Please re-login.',
          );
        }
        // Other errors (network blip, 500) → keep polling
      } catch (_) {
        // Unexpected non-Dio error → keep polling
      }
    });
  }

  void reset() {
    _pollTimer?.cancel();
    _cleanupPendingTempFile();
    state = const UploadState();
  }

  /// Convert a list of image paths to a single PDF file.
  /// If images came from the enhance pipeline, they're already EXIF-oriented
  /// and JPEG-encoded, so we skip the expensive decode→encode cycle.
  Future<String> _imagesToPdf(
    List<String> imagePaths, {
    bool preProcessed = false,
  }) async {
    return PdfGenerator.generatePdf(
      imagePaths: imagePaths,
      jpegQuality: 85,
      preProcessed: preProcessed,
    );
  }

  String _safeFilename(String name) {
    var safe = name.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    if (safe.isEmpty) safe = 'document';
    return safe;
  }

  void _deleteTempFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {
      // Best-effort cleanup
    }
  }

  /// Delete the deferred scanned-images temp PDF, if any, exactly once.
  void _cleanupPendingTempFile() {
    final path = _pendingTempPdf;
    if (path != null) {
      _deleteTempFile(path);
      _pendingTempPdf = null;
    }
  }
}
