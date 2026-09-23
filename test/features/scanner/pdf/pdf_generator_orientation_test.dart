import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:paperless_go/features/scanner/pdf/pdf_generator.dart';
import 'package:pdf/pdf.dart';

/// Covers the fix for issue #37: a page substituted from the raw camera
/// file (because its enhancement threw) travels under a batch-wide
/// `preProcessed: true`, even though — unlike real enhance-pipeline output —
/// it can carry an EXIF orientation tag. The `pdf` package's own renderer
/// honors that tag when drawing the image, so the fast path must not trust
/// the JPEG's stored SOF dimensions for orientation values that transpose
/// width and height (5-8), or the chosen page format disagrees with what
/// actually gets rendered.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfGenerator orientation handling', () {
    late Directory tempDir;
    late Directory outputDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pdf_orient_src_');
      outputDir = await Directory.systemTemp.createTemp('pdf_orient_out_');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall call) async {
          if (call.method == 'getTemporaryDirectory') return outputDir.path;
          return null;
        },
      );
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      if (outputDir.existsSync()) outputDir.deleteSync(recursive: true);
    });

    /// A physically wide (16x8, landscape) pixel buffer, JPEG-encoded with
    /// an EXIF orientation tag of 6 ("rotate 90 CW"). A viewer honoring that
    /// tag displays it as an 8x16 *portrait* image — exactly the raw-camera
    /// shape that triggers issue #37 when it's substituted under a
    /// `preProcessed: true` batch. Busy pixel content (not a flat fill), so
    /// the quality-sensitivity check below can detect a re-encode.
    Uint8List rotatedLandscapeSourceBytes() {
      final image = img.Image(width: 16, height: 8);
      for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 16; x++) {
          image.setPixelRgb(x, y, (x * 13) % 256, (y * 29) % 256, 100);
        }
      }
      image.exif.imageIfd[0x0112] = img.IfdValueShort(6);
      return Uint8List.fromList(img.encodeJpg(image, quality: 90));
    }

    /// Same physical shape and pixel content as [rotatedLandscapeSourceBytes]
    /// but with no EXIF orientation tag at all — the normal enhance-pipeline
    /// output shape this batch flag is actually meant for.
    Uint8List plainLandscapeSourceBytes() {
      final image = img.Image(width: 16, height: 8);
      for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 16; x++) {
          image.setPixelRgb(x, y, (x * 13) % 256, (y * 29) % 256, 100);
        }
      }
      return Uint8List.fromList(img.encodeJpg(image, quality: 90));
    }

    /// Same physical shape and pixel content again, but with orientation 3
    /// (180° rotation) — present, but one of the values that does NOT
    /// transpose width and height. Distinguishes "tag present" from "tag
    /// transposes dimensions": a predicate that gates on presence alone
    /// (e.g. "anything other than 1") would wrongly send this to the slow
    /// path too.
    Uint8List nonTransposingRotationSourceBytes() {
      final image = img.Image(width: 16, height: 8);
      for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 16; x++) {
          image.setPixelRgb(x, y, (x * 13) % 256, (y * 29) % 256, 100);
        }
      }
      image.exif.imageIfd[0x0112] = img.IfdValueShort(3);
      return Uint8List.fromList(img.encodeJpg(image, quality: 90));
    }

    Future<String> writeImage(String name, Uint8List bytes) async {
      final path = '${tempDir.path}/$name';
      await File(path).writeAsBytes(bytes);
      return path;
    }

    /// Extracts the (width, height) pair from the first `/MediaBox` entry
    /// found in raw generated PDF bytes. `pw.Page` writes each page's media
    /// box as a plain-ASCII `/MediaBox [0 0 W H]` array in the page object's
    /// dictionary (not inside a compressed content stream), so this reads
    /// the real page format the PDF asks a viewer to render — the same
    /// property a viewer bases the visible page shape on. This is why the
    /// assertion below can only pass if `_decodePageForPdf` actually chose
    /// portrait for this page: it's reading the format the generator wrote,
    /// not a stand-in for it.
    (double, double) firstMediaBoxSize(Uint8List pdfBytes) {
      final text = latin1.decode(pdfBytes, allowInvalid: true);
      final match = RegExp(r'/MediaBox\s*\[\s*[\d.]+\s+[\d.]+\s+'
              r'([\d.]+)\s+([\d.]+)\s*\]')
          .firstMatch(text);
      if (match == null) {
        fail('No /MediaBox found in generated PDF bytes');
      }
      return (double.parse(match.group(1)!), double.parse(match.group(2)!));
    }

    test(
        'fixture sanity check: rotatedLandscapeSourceBytes actually carries '
        'a transposing orientation, plainLandscapeSourceBytes carries none',
        () {
      // Don't assume img.encodeJpg preserves the tag we set — check it via
      // the same PdfJpegInfo the fix (and the pdf package's own renderer)
      // reads it back with, not our own parser.
      expect(PdfJpegInfo(rotatedLandscapeSourceBytes()).orientation,
          PdfImageOrientation.rightTop); // EXIF 6
      expect(PdfJpegInfo(plainLandscapeSourceBytes()).orientation,
          PdfImageOrientation.topLeft); // no tag -> topLeft, per PdfJpegInfo
      // And confirm the stored SOF dimensions are landscape in both cases —
      // it's specifically the *orientation*, not the stored dimensions,
      // that must change the fast path's decision.
      final rotatedDims =
          readJpegDimensions(rotatedLandscapeSourceBytes());
      final plainDims = readJpegDimensions(plainLandscapeSourceBytes());
      expect(rotatedDims, isNotNull);
      expect(plainDims, isNotNull);
      expect(rotatedDims!.$1 > rotatedDims.$2, isTrue);
      expect(plainDims!.$1 > plainDims.$2, isTrue);
      // Orientation 3 (180°) fixture: tag present, but not one of the
      // transposing values.
      expect(PdfJpegInfo(nonTransposingRotationSourceBytes()).orientation,
          PdfImageOrientation.bottomRight); // EXIF 3
    });

    test(
        'RED: preProcessed image with a transposing EXIF orientation '
        'produces a portrait PDF page, not landscape', () async {
      final path =
          await writeImage('rotated.jpg', rotatedLandscapeSourceBytes());

      final outputPath = await PdfGenerator.generatePdf(
        imagePaths: [path],
        preProcessed: true,
      );

      final pdfBytes = await File(outputPath).readAsBytes();
      final (width, height) = firstMediaBoxSize(pdfBytes);
      // A4 portrait has width < height; landscape swaps them. Only true if
      // _decodePageForPdf actually fell through to the full decoder and
      // derived isLandscape from the *baked* (rotation-applied) dimensions
      // instead of the stored SOF dimensions, which are landscape.
      expect(width, lessThan(height),
          reason: 'page should be portrait A4 (width < height); a '
              'landscape page here means the fast path trusted the '
              "JPEG's stored (unrotated) dimensions over its EXIF tag");
    });

    test(
        'un-rotated preProcessed image still takes the fast path: bytes '
        'pass through unchanged (no re-encode)', () async {
      final plain = plainLandscapeSourceBytes();

      final highQualityPath = await PdfGenerator.generatePdf(
        imagePaths: [await writeImage('high.jpg', plain)],
        preProcessed: true,
        jpegQuality: 95,
      );
      final lowQualityPath = await PdfGenerator.generatePdf(
        imagePaths: [await writeImage('low.jpg', plain)],
        preProcessed: true,
        jpegQuality: 5,
      );

      // A passthrough embeds the same source bytes regardless of
      // jpegQuality, so the two PDFs come out the same size. A quality
      // difference would mean a re-encode happened — i.e. the fast path
      // was NOT taken for an image that has no reason to skip it.
      final highSize = await File(highQualityPath).length();
      final lowSize = await File(lowQualityPath).length();
      expect(lowSize, highSize);

      // And the page format is landscape, matching the stored (and,
      // correctly here, actual) dimensions — this image was never rotated.
      final pdfBytes = await File(highQualityPath).readAsBytes();
      final (width, height) = firstMediaBoxSize(pdfBytes);
      expect(width, greaterThan(height));
    });

    test(
        'preProcessed image with a non-transposing EXIF orientation (tag '
        'present, but not 5-8) still takes the fast path', () async {
      // Distinguishes the chosen "transposes width/height" predicate from
      // the simpler-but-wrong "anything other than 1": this fixture's tag
      // is present (3, not absent) but must not send it down the slow path.
      final rotated180 = nonTransposingRotationSourceBytes();

      final highQualityPath = await PdfGenerator.generatePdf(
        imagePaths: [await writeImage('high.jpg', rotated180)],
        preProcessed: true,
        jpegQuality: 95,
      );
      final lowQualityPath = await PdfGenerator.generatePdf(
        imagePaths: [await writeImage('low.jpg', rotated180)],
        preProcessed: true,
        jpegQuality: 5,
      );

      final highSize = await File(highQualityPath).length();
      final lowSize = await File(lowQualityPath).length();
      expect(lowSize, highSize,
          reason: 'equal sizes only hold if the fast path (no re-encode) '
              'was taken; a gate that fires on tag presence alone (e.g. '
              '"anything other than 1") would re-encode this and the '
              'sizes would diverge, as in the transposing case below');

      // Stored dimensions are landscape and orientation 3 doesn't swap
      // them, so the correct page format is landscape here too.
      final pdfBytes = await File(highQualityPath).readAsBytes();
      final (width, height) = firstMediaBoxSize(pdfBytes);
      expect(width, greaterThan(height));
    });

    test(
        'transposing-orientation image DOES get re-encoded (fast path not '
        'taken), unlike the un-rotated case above', () async {
      final rotated = rotatedLandscapeSourceBytes();

      final highQualityPath = await PdfGenerator.generatePdf(
        imagePaths: [await writeImage('high.jpg', rotated)],
        preProcessed: true,
        jpegQuality: 95,
      );
      final lowQualityPath = await PdfGenerator.generatePdf(
        imagePaths: [await writeImage('low.jpg', rotated)],
        preProcessed: true,
        jpegQuality: 5,
      );

      final highSize = await File(highQualityPath).length();
      final lowSize = await File(lowQualityPath).length();
      expect(lowSize, lessThan(highSize));
    });

    // Canary on a dependency assumption, not on our own code. The fix relies
    // on the slow path's decode→re-encode producing bytes that carry no
    // transposing orientation: if they did, the renderer would rotate an
    // already-baked image a second time, and the MediaBox assertions above
    // would still pass because the page SHAPE would be right. image 4.5.4
    // clears the tag while baking (`bake_orientation.dart`), so this holds
    // today; a package bump that stopped doing so would regress the output
    // silently. This turns that into a failing test instead.
    test(
        'decode→re-encode strips the orientation tag, so a baked image is '
        'never rotated twice', () {
      final rotated = rotatedLandscapeSourceBytes();
      expect(
        PdfJpegInfo(rotated).orientation,
        PdfImageOrientation.rightTop,
        reason: 'fixture must start with a transposing tag, or this proves '
            'nothing',
      );

      final decoded = img.decodeImage(rotated);
      final reencoded =
          Uint8List.fromList(img.encodeJpg(img.bakeOrientation(decoded!)));

      expect(
        PdfJpegInfo(reencoded).orientation,
        PdfImageOrientation.topLeft,
        reason: 'the bytes the slow path embeds must carry no rotation for '
            'the renderer to apply on top of the baked pixels',
      );
    });
  });
}
