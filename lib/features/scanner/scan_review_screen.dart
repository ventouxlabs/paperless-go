import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error_mapper.dart';
import '../../core/design_tokens.dart';
import 'crop_screen.dart';
import 'pdf/pdf_generator.dart';
import 'processing/crop_rotate.dart';
import 'processing/image_enhancer.dart';
import 'processing/presets.dart';
import 'providers/selected_preset_provider.dart';

/// The single "confirm" step: review scanned pages, then Continue straight to
/// upload (applying the chosen preset at default quality), or Adjust for the
/// full enhance → PDF-preview path.
class ScanReviewScreen extends ConsumerStatefulWidget {
  final List<String> imagePaths;
  const ScanReviewScreen({super.key, required this.imagePaths});

  @override
  ConsumerState<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends ConsumerState<ScanReviewScreen> {
  late List<String> _pages;
  int _currentPage = 0;
  late PageController _pageController;
  bool _isProcessing = false;
  String? _generatedPdfPath;

  @override
  void initState() {
    super.initState();
    _pages = List.from(widget.imagePaths);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cleanupPdf();
    super.dispose();
  }

  void _cleanupPdf() {
    final path = _generatedPdfPath;
    if (path != null) {
      try {
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
      _generatedPdfPath = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Review · ${_pages.length} ${_pages.length == 1 ? 'page' : 'pages'}',
        ),
      ),
      body: _pages.isEmpty
          ? const Center(child: Text('No pages'))
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.all(Spacing.lg),
                          child: InteractiveViewer(
                            child: Image.file(
                              File(_pages[i]),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Quiet page-management row — kept subordinate to Continue.
                    _PageControls(
                      currentPage: _currentPage,
                      pageCount: _pages.length,
                      enabled: !_isProcessing,
                      onDelete: () => _removePage(_currentPage),
                      onRotateLeft: () => _rotatePage(clockwise: false),
                      onRotateRight: () => _rotatePage(clockwise: true),
                      onCrop: _cropPage,
                      onMoveLeft: () =>
                          _movePage(_currentPage, _currentPage - 1),
                      onMoveRight: () =>
                          _movePage(_currentPage, _currentPage + 1),
                    ),

                    // Thumbnail strip.
                    SizedBox(
                      height: 76,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.md),
                        itemCount: _pages.length,
                        itemBuilder: (_, i) => Semantics(
                          label: 'Page ${i + 1}',
                          button: true,
                          child: GestureDetector(
                            onTap: () => _pageController.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                            child: Container(
                              width: 56,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: Spacing.xs, vertical: Spacing.sm),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: i == _currentPage
                                      ? tokens.accentEmphasis
                                      : tokens.line,
                                  width: i == _currentPage ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(Radii.sm),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(Radii.sm - 1),
                                child: Image.file(File(_pages[i]),
                                    fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Primary + secondary actions.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          Spacing.lg, Spacing.sm, Spacing.lg, Spacing.lg),
                      child: Column(
                        children: [
                          FilledButton.icon(
                            onPressed: _isProcessing ? null : _onContinue,
                            icon: const Icon(Icons.arrow_forward, size: 18),
                            label: const Text('Continue'),
                          ),
                          TextButton(
                            onPressed: _isProcessing ? null : _onAdjust,
                            child: const Text('Adjust enhancement & quality'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_isProcessing)
                  Positioned.fill(
                    child: ColoredBox(
                      color: tokens.paper.withValues(alpha: 0.7),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
    );
  }

  /// Happy path: apply the chosen preset, build the PDF at default quality, and
  /// go straight to upload — reusing the enhance/PDF logic, not their screens.
  Future<void> _onContinue() async {
    if (_isProcessing || _pages.isEmpty) return;
    setState(() => _isProcessing = true);

    final preset = ref.read(selectedPresetProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final processed = await _processPages(preset);
      _cleanupPdf();
      final pdfPath = await PdfGenerator.generatePdf(
        imagePaths: processed,
        jpegQuality: 85,
        preProcessed: preset != ProcessingPreset.none,
      );
      if (!mounted) return;
      _generatedPdfPath = pdfPath;
      setState(() => _isProcessing = false);
      context.push('/scan/upload', extra: {
        'filePath': pdfPath,
        'filename': 'scan_${DateTime.now().millisecondsSinceEpoch}.pdf',
        // We own this temp PDF; upload_notifier won't delete the source.
        '_isTempPdf': true,
        'ocrImagePath': processed.first,
      });
    } on PdfPageDecodeException catch (e) {
      // friendlyApiMessage() only maps DioException and would otherwise fall
      // through to its generic fallback, swallowing the specific
      // "page N could not be read" message.
      if (!mounted) return;
      setState(() => _isProcessing = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Could not prepare document: ${friendlyApiMessage(e)}')),
      );
    }
  }

  /// Secondary path for users who want manual control over enhancement/quality.
  void _onAdjust() {
    if (_pages.isEmpty) return;
    context.push('/scan/enhance', extra: _pages);
  }

  /// Enhance every page with [preset], in bounded-concurrency batches. Falls
  /// back to the original page on a per-page failure so upload never blocks.
  Future<List<String>> _processPages(ProcessingPreset preset) async {
    if (preset == ProcessingPreset.none) return List.of(_pages);

    final results = List<String>.from(_pages);
    const maxConcurrent = 3;
    for (var start = 0; start < _pages.length; start += maxConcurrent) {
      final end = (start + maxConcurrent).clamp(0, _pages.length);
      await Future.wait([
        for (var i = start; i < end; i++) _enhanceOne(i, preset, results),
      ]);
    }
    return results;
  }

  Future<void> _enhanceOne(
    int index,
    ProcessingPreset preset,
    List<String> results,
  ) async {
    try {
      results[index] = await ImageEnhancer.enhanceImage(
        inputPath: _pages[index],
        preset: preset,
      );
    } catch (_) {
      results[index] = _pages[index];
    }
  }

  Future<void> _rotatePage({required bool clockwise}) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final oldPath = _pages[_currentPage];
      final newPath = await CropRotate.rotateImage90(
        inputPath: oldPath,
        clockwise: clockwise,
      );
      if (!mounted) return;
      // Evict only the old image from Flutter's cache instead of clearing
      // the entire cache, which would affect unrelated screens.
      final oldFileKey = FileImage(File(oldPath));
      imageCache.evict(oldFileKey);
      File(oldPath).delete().ignore(); // clean up temp file
      setState(() {
        _pages[_currentPage] = newPath;
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Rotate failed: ${friendlyApiMessage(e)}')));
    }
  }

  Future<void> _cropPage() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CropScreen(imagePath: _pages[_currentPage]),
      ),
    );
    if (result != null && mounted) {
      // Evict only the old image from Flutter's cache
      final oldPath = _pages[_currentPage];
      final oldFileKey = FileImage(File(oldPath));
      imageCache.evict(oldFileKey);
      File(oldPath).delete().ignore(); // clean up temp file
      setState(() {
        _pages[_currentPage] = result;
      });
    }
  }

  void _removePage(int index) {
    if (_pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot remove the last page')),
      );
      return;
    }
    setState(() {
      File(_pages[index]).delete().ignore(); // clean up temp file
      _pages.removeAt(index);
      if (_currentPage >= _pages.length) {
        _currentPage = _pages.length - 1;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _currentPage < _pages.length) {
        _pageController.jumpToPage(_currentPage);
      }
    });
  }

  void _movePage(int from, int to) {
    if (to < 0 || to >= _pages.length) return;
    setState(() {
      final page = _pages.removeAt(from);
      _pages.insert(to, page);
      _currentPage = to;
    });
    _pageController.animateToPage(
      to,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

/// Subordinate page-management controls: icon-only, low emphasis.
class _PageControls extends StatelessWidget {
  const _PageControls({
    required this.currentPage,
    required this.pageCount,
    required this.enabled,
    required this.onDelete,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onCrop,
    required this.onMoveLeft,
    required this.onMoveRight,
  });

  final int currentPage;
  final int pageCount;
  final bool enabled;
  final VoidCallback onDelete;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onCrop;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    Widget iconBtn(IconData icon, String tip, VoidCallback? onTap) => IconButton(
          onPressed: enabled ? onTap : null,
          icon: Icon(icon, size: 20),
          color: tokens.inkSoft,
          tooltip: tip,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
      child: Row(
        children: [
          iconBtn(Icons.delete_outline, 'Remove page', onDelete),
          iconBtn(Icons.rotate_left, 'Rotate left', onRotateLeft),
          iconBtn(Icons.rotate_right, 'Rotate right', onRotateRight),
          iconBtn(Icons.crop, 'Crop', onCrop),
          const Spacer(),
          Text(
            '${currentPage + 1} / $pageCount',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: tokens.inkSoft),
          ),
          const Spacer(),
          iconBtn(Icons.arrow_back, 'Move left',
              currentPage > 0 ? onMoveLeft : null),
          iconBtn(Icons.arrow_forward, 'Move right',
              currentPage < pageCount - 1 ? onMoveRight : null),
        ],
      ),
    );
  }
}
