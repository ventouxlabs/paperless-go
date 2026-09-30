import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/api/api_providers.dart';
import '../../core/api/api_error_mapper.dart';
import '../../core/api/download_file_type.dart';

/// What the download turned out to be.
sealed class _Preview {
  const _Preview();
}

final class _PdfPreview extends _Preview {
  final PdfControllerPinch controller;
  const _PdfPreview(this.controller);
}

/// An original Paperless never archived (text, an image, …): the PDF viewer
/// can't show it, so offer to hand it to another app instead (#43).
final class _OtherFile extends _Preview {
  final String path;
  const _OtherFile(this.path);
}

class DocumentPreviewScreen extends ConsumerStatefulWidget {
  final int documentId;
  const DocumentPreviewScreen({super.key, required this.documentId});

  @override
  ConsumerState<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends ConsumerState<DocumentPreviewScreen> {
  late final Future<_Preview> _preview = _load();
  PdfControllerPinch? _pdfController;
  bool _disposed = false;

  Future<_Preview> _load() async {
    final api = ref.read(paperlessApiProvider);
    final dir = await getTemporaryDirectory();
    final file = await api.downloadDocumentTyped(
      widget.documentId,
      (extension) => '${dir.path}/preview_${widget.documentId}.$extension',
    );
    if (_disposed) throw Exception('Widget disposed during download');
    if (!isPdfFile(file.path)) return _OtherFile(file.path);
    final controller = PdfControllerPinch(
      document: PdfDocument.openFile(file.path),
    );
    _pdfController = controller;
    return _PdfPreview(controller);
  }

  @override
  void dispose() {
    _disposed = true;
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Preview>(
      future: _preview,
      builder: (context, snapshot) {
        final preview = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: switch (preview) {
              _PdfPreview(:final controller) => PdfPageNumber(
                  controller: controller,
                  builder: (context, loadingState, page, pagesCount) => Text(
                      pagesCount != null ? 'Page $page of $pagesCount' : 'Loading...'),
                ),
              _OtherFile() => const Text('Preview'),
              null => const Text('Loading...'),
            },
            backgroundColor: Colors.black, // Intentional: dark background for media viewing
            foregroundColor: Colors.white, // On forced-dark background
          ),
          backgroundColor: Colors.black, // Intentional: dark background for media viewing
          body: switch (preview) {
            _PdfPreview(:final controller) => _pdfView(controller),
            _OtherFile(:final path) => _NoPreview(path: path),
            null => snapshot.hasError
                ? _loadError(snapshot.error)
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white), // On forced-dark background
                  ),
          },
        );
      },
    );
  }

  Widget _pdfView(PdfControllerPinch controller) => PdfViewPinch(
        controller: controller,
        padding: 8,
        scrollDirection: Axis.vertical,
        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) => const Center(
            child: CircularProgressIndicator(color: Colors.white), // On forced-dark background
          ),
          pageLoaderBuilder: (_) => const Center(
            child: CircularProgressIndicator(color: Colors.white), // On forced-dark background
          ),
          errorBuilder: (_, error) => _loadError(error),
        ),
      );

  Widget _loadError(Object? error) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.white.withValues(alpha: 0.54)), // On forced-dark background
            const SizedBox(height: 16),
            Text('Failed to load PDF',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.70))), // On forced-dark background
            const SizedBox(height: 8),
            Text(friendlyApiMessage(error, fallback: 'Failed to load PDF.'),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 12)), // On forced-dark background
          ],
        ),
      );
}

class _NoPreview extends StatelessWidget {
  const _NoPreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final extension = fileExtensionOf(path);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_outlined,
                size: 48, color: Colors.white.withValues(alpha: 0.54)), // On forced-dark background
            const SizedBox(height: 16),
            Text(
              extension.isEmpty
                  ? 'No preview for this file type'
                  : 'No preview for .$extension files',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.70)), // On forced-dark background
            ),
            const SizedBox(height: 8),
            Text(
              "This document isn't a PDF. Share it to open it in another app.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 12), // On forced-dark background
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Share.shareXFiles(
                [XFile(path, mimeType: mimeTypeForFileName(path))],
              ),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share'),
            ),
          ],
        ),
      ),
    );
  }
}
