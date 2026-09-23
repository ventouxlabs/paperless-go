import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pdf/pdf_generator.dart';
import '../../core/api/api_error_mapper.dart';

/// Preview the generated PDF before uploading.
/// Shows page count, file size estimate, and quality slider.
class PdfPreviewScreen extends StatefulWidget {
  final List<String> imagePaths;
  final bool preProcessed;
  final String? ocrImagePath;
  const PdfPreviewScreen({
    super.key,
    required this.imagePaths,
    this.preProcessed = false,
    this.ocrImagePath,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  double _quality = 85;
  String? _pdfPath;
  int? _fileSizeBytes;
  bool _isGenerating = false;
  int _currentPage = 0;
  int _generation = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _generatePdf();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cleanupPdf();
    super.dispose();
  }

  void _cleanupPdf() {
    if (_pdfPath != null) {
      try {
        final file = File(_pdfPath!);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
    }
  }

  Future<void> _generatePdf() async {
    // Guards against concurrent generation: dragging the quality slider
    // (onChangeEnd) can fire while the initState generation is still running.
    // Only the newest request is allowed to commit its result.
    final generation = ++_generation;
    setState(() => _isGenerating = true);
    _cleanupPdf();

    try {
      final path = await PdfGenerator.generatePdf(
        imagePaths: widget.imagePaths,
        jpegQuality: _quality.round(),
        preProcessed: widget.preProcessed,
      );
      if (!mounted || generation != _generation) {
        // A newer generation superseded this one — delete its orphaned output.
        // Skip if it collides with the committed path (PdfGenerator names by
        // timestamp): never delete a file a newer generation already kept.
        if (path != _pdfPath) {
          try {
            final stale = File(path);
            if (stale.existsSync()) stale.deleteSync();
          } catch (_) {}
        }
        return;
      }
      final file = File(path);
      final size = await file.length();
      setState(() {
        _pdfPath = path;
        _fileSizeBytes = size;
        _isGenerating = false;
      });
    } on PdfPageDecodeException catch (e) {
      // friendlyApiMessage() only has a mapping for DioException — anything
      // else falls through to its generic fallback, which would swallow the
      // specific "page N could not be read" message. Show it directly.
      if (!mounted || generation != _generation) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF generation failed: ${friendlyApiMessage(e)}')),
      );
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _onUpload() {
    if (_pdfPath == null) return;
    context.push('/scan/upload', extra: {
      'filePath': _pdfPath!,
      'filename': 'scan_${DateTime.now().millisecondsSinceEpoch}.pdf',
      // Signal that we own this temp file so upload_notifier won't delete the source
      '_isTempPdf': true,
      if (widget.ocrImagePath != null) 'ocrImagePath': widget.ocrImagePath,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.imagePaths.length} ${widget.imagePaths.length == 1 ? 'page' : 'pages'}',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
              ),
              onPressed: _pdfPath != null && !_isGenerating ? _onUpload : null,
              child: const Text('Upload'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Page preview
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imagePaths.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.all(16),
                child: InteractiveViewer(
                  child: Image.file(
                    File(widget.imagePaths[i]),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // Page indicator
          if (widget.imagePaths.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${_currentPage + 1} / ${widget.imagePaths.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),

          // File size and quality controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // File size info
                if (_isGenerating)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Generating PDF...'),
                      ],
                    ),
                  )
                else if (_fileSizeBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.picture_as_pdf, size: 20, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'PDF ready — ${_formatFileSize(_fileSizeBytes!)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),

                // Quality slider
                Row(
                  children: [
                    Text(
                      'Quality',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Expanded(
                      child: Slider(
                        value: _quality,
                        min: 30,
                        max: 100,
                        divisions: 14,
                        label: '${_quality.round()}%',
                        onChanged: _isGenerating
                            ? null
                            : (v) => setState(() => _quality = v),
                        onChangeEnd: _isGenerating ? null : (_) => _generatePdf(),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${_quality.round()}%',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
