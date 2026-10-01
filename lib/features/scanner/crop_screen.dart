import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'processing/crop_rotate.dart';
import 'widgets/crop_overlay.dart';
import '../../core/api/api_error_mapper.dart';

/// Fullscreen screen for cropping a single scanned page.
/// Returns the new cropped image path on apply, or null on cancel.
class CropScreen extends StatefulWidget {
  final String imagePath;
  const CropScreen({super.key, required this.imagePath});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  Rect _cropRect = const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
  bool _isProcessing = false;
  Size? _imageSize;
  Uint8List? _imageBytes;
  final GlobalKey<_CropOverlayWrapperState> _overlayKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _imageSize = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
        _imageBytes = bytes;
      });
    }
    frame.image.dispose();
    codec.dispose();
  }

  Future<void> _apply() async {
    setState(() => _isProcessing = true);
    try {
      final path = await CropRotate.cropImage(
        inputPath: widget.imagePath,
        cropNormalized: _cropRect,
      );
      if (mounted) Navigator.pop(context, path);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Crop failed: ${friendlyApiMessage(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Intentional: dark background for image editing
      appBar: AppBar(
        backgroundColor: Colors.black, // Intentional: dark background for image editing
        foregroundColor: Colors.white, // On forced-dark background
        // The theme's title style carries the ink colour and beats foregroundColor.
        titleTextStyle: Theme.of(context)
            .appBarTheme
            .titleTextStyle
            ?.copyWith(color: Colors.white),
        title: const Text('Crop'),
        actions: [
          TextButton(
            onPressed: _isProcessing
                ? null
                : () => _overlayKey.currentState?.reset(),
            child: const Text('Reset', style: TextStyle(color: Colors.white70)), // On forced-dark background
          ),
          IconButton(
            onPressed: _isProcessing ? null : _apply,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white), // On forced-dark background
                  )
                : const Icon(Icons.check, color: Colors.white), // On forced-dark background
            tooltip: 'Apply crop',
          ),
        ],
      ),
      body: _imageSize == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final imageAspect = _imageSize!.width / _imageSize!.height;
                final boxAspect = constraints.maxWidth / constraints.maxHeight;

                double displayWidth, displayHeight;
                if (imageAspect > boxAspect) {
                  displayWidth = constraints.maxWidth;
                  displayHeight = constraints.maxWidth / imageAspect;
                } else {
                  displayHeight = constraints.maxHeight;
                  displayWidth = constraints.maxHeight * imageAspect;
                }

                final displaySize = Size(displayWidth, displayHeight);
                final offsetX = (constraints.maxWidth - displayWidth) / 2;
                final offsetY = (constraints.maxHeight - displayHeight) / 2;

                return Stack(
                  children: [
                    Positioned(
                      left: offsetX,
                      top: offsetY,
                      width: displayWidth,
                      height: displayHeight,
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      left: offsetX,
                      top: offsetY,
                      width: displayWidth,
                      height: displayHeight,
                      child: _CropOverlayWrapper(
                        key: _overlayKey,
                        imageSize: _imageSize!,
                        displaySize: displaySize,
                        onCropChanged: (rect) => _cropRect = rect,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

/// Wrapper to expose [reset] via a GlobalKey.
class _CropOverlayWrapper extends StatefulWidget {
  final Size imageSize;
  final Size displaySize;
  final ValueChanged<Rect> onCropChanged;

  const _CropOverlayWrapper({
    super.key,
    required this.imageSize,
    required this.displaySize,
    required this.onCropChanged,
  });

  @override
  State<_CropOverlayWrapper> createState() => _CropOverlayWrapperState();
}

class _CropOverlayWrapperState extends State<_CropOverlayWrapper> {
  final GlobalKey<CropOverlayState> _overlayKey = GlobalKey();

  void reset() => _overlayKey.currentState?.reset();

  @override
  Widget build(BuildContext context) {
    return CropOverlay(
      key: _overlayKey,
      imageSize: widget.imageSize,
      displaySize: widget.displaySize,
      onCropChanged: widget.onCropChanged,
    );
  }
}
