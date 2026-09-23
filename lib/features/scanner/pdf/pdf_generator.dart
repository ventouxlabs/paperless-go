import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Thrown when one or more scanned pages could not be decoded, rather than
/// letting them silently vanish from the generated PDF.
class PdfPageDecodeException implements Exception {
  PdfPageDecodeException(List<int> pageNumbers)
      : pageNumbers = List.unmodifiable(pageNumbers);

  /// 1-based page positions, in order, that could not be read.
  final List<int> pageNumbers;

  /// User-facing message: plain language, no internals, singular/plural aware.
  String get message {
    if (pageNumbers.length == 1) {
      return 'Page ${pageNumbers.first} could not be read, so it would be '
          'missing from the PDF. Re-scan that page and try again.';
    }
    return 'Pages ${pageNumbers.join(', ')} could not be read, so they '
        'would be missing from the PDF. Re-scan those pages and try again.';
  }

  @override
  String toString() => 'PdfPageDecodeException: $message';
}

/// Generates a well-formed PDF from a list of image files.
class PdfGenerator {
  /// Generate a PDF from image file paths.
  /// Returns the path to the generated PDF file.
  static Future<String> generatePdf({
    required List<String> imagePaths,
    int jpegQuality = 85,
    bool preProcessed = false,
    String? title,
  }) async {
    // Read all image files in parallel
    final imageBytesList = await Future.wait(
      imagePaths.map((path) => File(path).readAsBytes()),
    );

    final pdfBytes = await Isolate.run(() => _buildPdf(
          imageBytesList: imageBytesList,
          jpegQuality: jpegQuality,
          preProcessed: preProcessed,
          title: title,
        ));

    final dir = await getTemporaryDirectory();
    // Microsecond precision + page count discriminator so two generations
    // started in quick succession (e.g. rapid quality-slider drags) cannot
    // collide on the same output path.
    final outputPath =
        '${dir.path}/scan_${DateTime.now().microsecondsSinceEpoch}_${imagePaths.length}.pdf';
    await File(outputPath).writeAsBytes(pdfBytes);
    return outputPath;
  }

  /// Get the estimated file size for given images at a quality level.
  /// Returns size in bytes.
  static Future<int> estimateSize({
    required List<String> imagePaths,
    int jpegQuality = 85,
  }) async {
    var totalSize = 0;
    for (final path in imagePaths) {
      final file = File(path);
      final size = await file.length();
      // Rough estimate: JPEG at quality Q is approximately Q/100 * original
      totalSize += (size * jpegQuality / 100).round();
    }
    // PDF overhead is roughly 1KB per page + headers
    totalSize += imagePaths.length * 1024 + 2048;
    return totalSize;
  }
}

Future<Uint8List> _buildPdf({
  required List<Uint8List> imageBytesList,
  required int jpegQuality,
  bool preProcessed = false,
  String? title,
}) async {
  final pdf = pw.Document(
    creator: 'Paperless Go',
    title: title ?? 'Scanned Document',
    producer: 'Paperless Go Scanner',
  );

  final failedPages = <int>[];

  for (var i = 0; i < imageBytesList.length; i++) {
    final page = _decodePageForPdf(
      imageBytes: imageBytesList[i],
      preProcessed: preProcessed,
      jpegQuality: jpegQuality,
    );
    if (page == null) {
      failedPages.add(i + 1);
      continue;
    }

    final pdfImage = pw.MemoryImage(page.bytes);
    final format =
        page.isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Center(
            child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
          );
        },
      ),
    );
  }

  // Fail loudly instead of silently returning a PDF with fewer pages than
  // were scanned — thrown before pdf.save() so no truncated file is ever
  // produced or written to disk by the caller.
  if (failedPages.isNotEmpty) {
    throw PdfPageDecodeException(failedPages);
  }

  return pdf.save();
}

/// Decode one scanned page's bytes for embedding in the PDF, returning its
/// orientation and final JPEG bytes, or null if the page could not be read
/// at all.
///
/// When [preProcessed], first tries the header-only fast path
/// ([readJpegDimensions]) and uses the bytes unchanged if it parses. A null
/// there isn't necessarily a corrupt file — the scanner only recognizes the
/// SOF0/1/2 markers and can desync on a marker layout it wasn't built to
/// handle, e.g. fill bytes before a marker, which the JPEG spec permits —
/// so fall back to the full decoder below instead of hard-blocking the
/// upload over a page that may well be fine. Only when that also fails is
/// the page truly unreadable.
({bool isLandscape, Uint8List bytes})? _decodePageForPdf({
  required Uint8List imageBytes,
  required bool preProcessed,
  required int jpegQuality,
}) {
  if (preProcessed) {
    // Images from the enhance pipeline are already EXIF-oriented and
    // JPEG-encoded at quality 92. Skip the expensive decode→encode cycle
    // when the header parses cleanly.
    final dims = readJpegDimensions(imageBytes);
    if (dims != null) {
      return (isLandscape: dims.$1 > dims.$2, bytes: imageBytes);
    }
  }
  // Raw camera images always need this; preProcessed images fall back to it
  // only when the fast header-only path above couldn't read the file.
  return _decodeAndReencode(imageBytes, jpegQuality);
}

/// Decode [imageBytes] for EXIF orientation and re-encode as JPEG at
/// [jpegQuality]. Returns null if the bytes could not be decoded at all.
/// Re-encodes rather than trusting the original bytes: when this runs as
/// [_decodePageForPdf]'s fallback, our own header parser already rejected
/// them, so don't hand them to the PDF library's parser unchanged either.
({bool isLandscape, Uint8List bytes})? _decodeAndReencode(
  Uint8List imageBytes,
  int jpegQuality,
) {
  var decoded = img.decodeImage(imageBytes);
  if (decoded == null) return null;
  decoded = img.bakeOrientation(decoded);
  return (
    isLandscape: decoded.width > decoded.height,
    bytes: Uint8List.fromList(img.encodeJpg(decoded, quality: jpegQuality)),
  );
}

/// Read JPEG width and height from the SOF marker without full decode.
/// Returns (width, height) or null if not a valid JPEG.
///
/// Visible for testing so tests can assert directly on this parser's
/// behavior instead of maintaining a separate copy of its logic, which
/// would silently drift out of sync with any future change here.
@visibleForTesting
(int, int)? readJpegDimensions(Uint8List data) {
  if (data.length < 4 || data[0] != 0xFF || data[1] != 0xD8) return null;
  var i = 2;
  while (i < data.length - 1) {
    if (data[i] != 0xFF) return null;
    final marker = data[i + 1];
    // SOF0, SOF1, SOF2 markers contain image dimensions
    if (marker == 0xC0 || marker == 0xC1 || marker == 0xC2) {
      if (i + 9 > data.length) return null;
      final height = (data[i + 5] << 8) | data[i + 6];
      final width = (data[i + 7] << 8) | data[i + 8];
      return (width, height);
    }
    // Skip this marker segment
    if (i + 3 >= data.length) return null;
    final segLen = (data[i + 2] << 8) | data[i + 3];
    i += 2 + segLen;
  }
  return null;
}
