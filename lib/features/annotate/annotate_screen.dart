import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/pdf_renderer_channel.dart';
import '../../core/api/api_error_mapper.dart';
import '../../core/services/export_destination_service.dart';
import '../../shared/save_to_folder_action.dart';
import 'annotation_export.dart';
import 'annotation_model.dart';
import 'annotation_painter.dart';

class AnnotateScreen extends ConsumerStatefulWidget {
  final String pdfPath;
  final String title;

  const AnnotateScreen({
    super.key,
    required this.pdfPath,
    required this.title,
  });

  @override
  ConsumerState<AnnotateScreen> createState() => _AnnotateScreenState();
}

class _AnnotateScreenState extends ConsumerState<AnnotateScreen> {
  List<Uint8List> _pages = [];
  bool _loading = true;
  String? _error;

  int _currentPage = 0;
  AnnotationTool _currentTool = AnnotationTool.pen;
  Color _penColor = Colors.red;
  double _penWidth = 3.0;

  final AnnotationState _annotationState = AnnotationState();
  Stroke? _activeStroke;

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  Future<void> _loadPages() async {
    try {
      final pages = await PdfRendererChannel.renderPages(
        widget.pdfPath,
        scale: 2.0,
      );
      if (mounted) {
        setState(() {
          _pages = pages;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _onPanStart(DragStartDetails details) {
    final tool = _currentTool;
    if (tool == AnnotationTool.eraser) return;
    setState(() {
      _activeStroke = Stroke(
        tool: tool,
        points: [details.localPosition],
        color: tool == AnnotationTool.redact ? Colors.black : _penColor,
        strokeWidth: _penWidth,
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeStroke == null) return;
    setState(() {
      _activeStroke = Stroke(
        tool: _activeStroke!.tool,
        points: [..._activeStroke!.points, details.localPosition],
        color: _activeStroke!.color,
        strokeWidth: _activeStroke!.strokeWidth,
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_activeStroke == null) return;
    final stroke = _activeStroke!;
    setState(() {
      _annotationState.addStroke(_currentPage, stroke);
      _activeStroke = null;

    });
  }

  void _onTap() {
    if (_currentTool == AnnotationTool.eraser) {
      if (_annotationState.canUndo) {
        setState(() {
          _annotationState.undo();
    
        });
      }
    }
  }

  void _undo() {
    if (_annotationState.canUndo) {
      setState(() {
        _annotationState.undo();
  
      });
    }
  }

  void _redo() {
    if (_annotationState.canRedo) {
      setState(() {
        _annotationState.redo();
  
      });
    }
  }

  /// Flattens the annotations into a PDF written to a temp file.
  Future<String> _renderAnnotatedPdf() async {
    final compositeImages = <Uint8List>[];
    for (int i = 0; i < _pages.length; i++) {
      final strokes = _annotationState.strokes(i);
      final decoded = img.decodePng(_pages[i]);
      final width = decoded?.width ?? 800;
      final height = decoded?.height ?? 1200;
      final composited = await compositePageImage(
        pageImagePng: _pages[i],
        strokes: strokes,
        pageWidth: width,
        pageHeight: height,
      );
      compositeImages.add(composited);
    }
    final pdfBytes = await buildAnnotatedPdf(
      compositeImages: compositeImages,
      jpegQuality: 85,
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/annotated.pdf');
    await file.writeAsBytes(pdfBytes);
    return file.path;
  }

  Future<void> _saveAndShare() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saving annotated PDF...')),
    );
    try {
      final path = await _renderAnnotatedPdf();
      await Share.shareXFiles([XFile(path, mimeType: 'application/pdf')]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: ${friendlyApiMessage(e)}')),
        );
      }
    }
  }

  Future<void> _saveToFolder() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saving annotated PDF...')),
    );
    try {
      final path = await _renderAnnotatedPdf();
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await saveToFolderWithFallback(
        context: context,
        ref: ref,
        localPaths: [path],
        fileNames: [
          '${sanitizeExportName(widget.title, fallback: 'annotated')}'
              '_annotated.pdf',
        ],
      );
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: ${friendlyApiMessage(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: _annotationState.canUndo ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
            onPressed: _annotationState.canRedo ? _redo : null,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: _saveAndShare,
          ),
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: 'Save to folder',
            onPressed: _saveToFolder,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.white54),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load PDF',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _pages.isEmpty
                  ? const Center(
                      child: Text(
                        'No pages found',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : Column(
                      children: [
                        // Page canvas
                        Expanded(
                          child: GestureDetector(
                            onPanStart: _onPanStart,
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            onTap: _onTap,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // PDF page image
                                InteractiveViewer(
                                  minScale: 0.5,
                                  maxScale: 4.0,
                                  child: Image.memory(
                                    _pages[_currentPage],
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                // Annotation overlay
                                IgnorePointer(
                                  ignoring: false,
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      painter: AnnotationPainter(
                                        strokes: _annotationState
                                            .strokes(_currentPage),
                                        activeStroke: _activeStroke,
                                      ),
                                      child: const SizedBox.expand(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Page navigation row
                        if (_pages.length > 1)
                          Container(
                            color: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left,
                                      color: Colors.white),
                                  onPressed: _currentPage > 0
                                      ? () => setState(
                                          () => _currentPage--)
                                      : null,
                                ),
                                Text(
                                  'Page ${_currentPage + 1} of ${_pages.length}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right,
                                      color: Colors.white),
                                  onPressed:
                                      _currentPage < _pages.length - 1
                                          ? () => setState(
                                              () => _currentPage++)
                                          : null,
                                ),
                              ],
                            ),
                          ),
                        // Toolbar
                        _AnnotationToolbar(
                          currentTool: _currentTool,
                          penColor: _penColor,
                          penWidth: _penWidth,
                          onToolChanged: (tool) =>
                              setState(() => _currentTool = tool),
                          onColorChanged: (color) =>
                              setState(() => _penColor = color),
                          onWidthChanged: (width) =>
                              setState(() => _penWidth = width),
                        ),
                      ],
                    ),
    );
  }
}

class _AnnotationToolbar extends StatelessWidget {
  final AnnotationTool currentTool;
  final Color penColor;
  final double penWidth;
  final ValueChanged<AnnotationTool> onToolChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onWidthChanged;

  const _AnnotationToolbar({
    required this.currentTool,
    required this.penColor,
    required this.penWidth,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onWidthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ToolButton(
              icon: Icons.edit,
              label: 'Pen',
              selected: currentTool == AnnotationTool.pen,
              onTap: () => onToolChanged(AnnotationTool.pen),
            ),
            _ToolButton(
              icon: Icons.highlight,
              label: 'Highlight',
              selected: currentTool == AnnotationTool.highlight,
              onTap: () => onToolChanged(AnnotationTool.highlight),
            ),
            _ToolButton(
              icon: Icons.rectangle,
              label: 'Redact',
              selected: currentTool == AnnotationTool.redact,
              onTap: () => onToolChanged(AnnotationTool.redact),
            ),
            _ToolButton(
              icon: Icons.cleaning_services,
              label: 'Eraser',
              selected: currentTool == AnnotationTool.eraser,
              onTap: () => onToolChanged(AnnotationTool.eraser),
            ),
            if (currentTool == AnnotationTool.pen) ...[
              _ColorPicker(
                currentColor: penColor,
                onColorChanged: onColorChanged,
              ),
              _WidthPicker(
                currentWidth: penWidth,
                onWidthChanged: onWidthChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? Colors.white24 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final Color currentColor;
  final ValueChanged<Color> onColorChanged;

  static const _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.black,
  ];

  const _ColorPicker({
    required this.currentColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _colors.map((color) {
        final selected = currentColor.toARGB32() == color.toARGB32();
        return Semantics(
          label: 'Color ${_colors.indexOf(color) + 1}',
          button: true,
          selected: selected,
          child: GestureDetector(
            onTap: () => onColorChanged(color),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: selected
                  ? Border.all(color: Colors.white, width: 2)
                  : Border.all(color: Colors.white38, width: 1),
            ),
          ),
          ),
        );
      }).toList(),
    );
  }
}

class _WidthPicker extends StatelessWidget {
  final double currentWidth;
  final ValueChanged<double> onWidthChanged;

  static const _widths = [2.0, 4.0, 7.0];

  const _WidthPicker({
    required this.currentWidth,
    required this.onWidthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _widths.map((w) {
        final selected = currentWidth == w;
        return Semantics(
          label: 'Stroke width ${w.round()}',
          button: true,
          selected: selected,
          child: GestureDetector(
            onTap: () => onWidthChanged(w),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: w + 10,
              height: w + 10,
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.white38,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
