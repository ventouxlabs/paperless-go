import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:paperless_go/features/scanner/pdf/pdf_generator.dart';

/// Covers the fix for silent page loss: a scanned page that fails to decode
/// must never just vanish from the generated PDF. `_buildPdf` must instead
/// throw [PdfPageDecodeException] naming every failed page, before any bytes
/// are written to disk.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfGenerator decode failure handling', () {
    late Directory tempDir; // holds the source scanned-page fixtures
    late Directory outputDir; // stands in for path_provider's temp dir

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pdf_decode_src_');
      outputDir = await Directory.systemTemp.createTemp('pdf_decode_out_');
      // generatePdf calls path_provider's getTemporaryDirectory(), which has
      // no real platform implementation under flutter_test. Mock the channel
      // so the happy path can exercise generatePdf end to end.
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

    Uint8List validJpegBytes() {
      final image = img.Image(width: 8, height: 8);
      return Uint8List.fromList(img.encodeJpg(image));
    }

    Uint8List garbageBytes() => Uint8List.fromList(List.filled(64, 0));

    /// A well-formed JPEG that `readJpegDimensions`'s hand-rolled SOF scanner
    /// cannot parse, but `img.decodeImage` reads fine — a JPEG whose marker
    /// layout the minimal scanner (SOF0/1/2 only) wasn't built to handle,
    /// e.g. one with fill bytes before a marker, which the JPEG spec
    /// permits and real decoders skip.
    ///
    /// Constructed by inserting a single 0xFF fill byte right after the SOI
    /// marker (FFD8). `readJpegDimensions` doesn't skip it: it reads the
    /// byte after the fill as the marker code (here, the *next* real
    /// marker's own 0xFF), then misreads that marker's payload as a segment
    /// length and walks off the end of the buffer, returning null.
    Uint8List headerDesyncButDecodableBytes() {
      final valid = validJpegBytes();
      return Uint8List.fromList([valid[0], valid[1], 0xFF, ...valid.sublist(2)]);
    }

    /// Same corruption as [headerDesyncButDecodableBytes], applied to a
    /// larger image with varied pixel content instead of a flat 8x8 block.
    /// Needed only for the quality-sensitivity check below: a flat image's
    /// JPEG size barely changes with quality (confirmed: ~1 byte across the
    /// full 5–95 range), so it can't prove a re-encode happened. A busy
    /// 32x32 image's size does.
    Uint8List desyncedNoisyJpegBytes() {
      final noisy = img.Image(width: 32, height: 32);
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          noisy.setPixelRgb(
              x, y, (x * 37) % 256, (y * 61) % 256, ((x + y) * 17) % 256);
        }
      }
      final valid = Uint8List.fromList(img.encodeJpg(noisy, quality: 100));
      return Uint8List.fromList([valid[0], valid[1], 0xFF, ...valid.sublist(2)]);
    }

    Future<String> writeImage(String name, Uint8List bytes) async {
      final path = '${tempDir.path}/$name';
      await File(path).writeAsBytes(bytes);
      return path;
    }

    test('all-valid images, preProcessed: false → completes with output',
        () async {
      final paths = [
        await writeImage('a.jpg', validJpegBytes()),
        await writeImage('b.jpg', validJpegBytes()),
        await writeImage('c.jpg', validJpegBytes()),
      ];

      final outputPath = await PdfGenerator.generatePdf(
        imagePaths: paths,
        preProcessed: false,
      );

      final outFile = File(outputPath);
      expect(outFile.existsSync(), isTrue);
      expect(await outFile.length(), greaterThan(0));
    });

    test(
        'one garbage image among three, preProcessed: false → throws '
        'PdfPageDecodeException naming page 2', () async {
      final paths = [
        await writeImage('a.jpg', validJpegBytes()),
        await writeImage('b.jpg', garbageBytes()),
        await writeImage('c.jpg', validJpegBytes()),
      ];

      await expectLater(
        () => PdfGenerator.generatePdf(imagePaths: paths, preProcessed: false),
        throwsA(
          isA<PdfPageDecodeException>()
              .having((e) => e.pageNumbers, 'pageNumbers', [2])
              .having((e) => e.message, 'message', contains('Page 2')),
        ),
      );
    });

    test(
        'one garbage image among three, preProcessed: true → throws '
        'PdfPageDecodeException naming page 2 (dimension-read branch)',
        () async {
      final paths = [
        await writeImage('a.jpg', validJpegBytes()),
        await writeImage('b.jpg', garbageBytes()),
        await writeImage('c.jpg', validJpegBytes()),
      ];
      // garbageBytes() must be rejected by BOTH decoders for this to be a
      // meaningful assertion post-fallback — confirm readJpegDimensions
      // rejects it (img.decodeImage's rejection is exercised by the
      // equivalent non-preProcessed test case above using the same bytes).
      expect(readJpegDimensions(garbageBytes()), isNull);

      await expectLater(
        () => PdfGenerator.generatePdf(imagePaths: paths, preProcessed: true),
        throwsA(
          isA<PdfPageDecodeException>()
              .having((e) => e.pageNumbers, 'pageNumbers', [2])
              .having((e) => e.message, 'message', contains('Page 2')),
        ),
      );
    });

    test(
        'header-desync JPEG that img.decodeImage still reads, '
        'preProcessed: true → completes without throwing', () async {
      // Sanity-check the fixture itself before relying on it: it must
      // desync readJpegDimensions while img.decodeImage still accepts it,
      // or this test would pass without ever exercising the fallback path.
      final desynced = headerDesyncButDecodableBytes();
      expect(readJpegDimensions(desynced), isNull);
      expect(img.decodeImage(desynced), isNotNull);

      final paths = [
        await writeImage('a.jpg', validJpegBytes()),
        await writeImage('b.jpg', desynced),
        await writeImage('c.jpg', validJpegBytes()),
      ];

      final outputPath = await PdfGenerator.generatePdf(
        imagePaths: paths,
        preProcessed: true,
      );

      final outFile = File(outputPath);
      expect(outFile.existsSync(), isTrue);
      expect(await outFile.length(), greaterThan(0));
    });

    test(
        'header-desync JPEG fallback actually re-encodes rather than '
        'passing the original bytes through', () async {
      // Belt and braces on top of the test above: that one only proves
      // generation didn't throw, which would also be true of a (wrong)
      // fallback that just embedded the original bytes verbatim. A
      // passthrough would ignore jpegQuality entirely, so it would produce
      // the same output size regardless of quality. Only a genuine
      // decode→re-encode is quality-sensitive — proving the fallback path
      // really ran. Needs pixel content complex enough for quality to
      // matter (see desyncedNoisyJpegBytes doc).
      final desynced = desyncedNoisyJpegBytes();
      expect(readJpegDimensions(desynced), isNull);
      expect(img.decodeImage(desynced), isNotNull);

      final highQualityPath = await PdfGenerator.generatePdf(
        imagePaths: [await writeImage('high.jpg', desynced)],
        preProcessed: true,
        jpegQuality: 95,
      );
      final lowQualityPath = await PdfGenerator.generatePdf(
        imagePaths: [await writeImage('low.jpg', desynced)],
        preProcessed: true,
        jpegQuality: 5,
      );

      final highSize = await File(highQualityPath).length();
      final lowSize = await File(lowQualityPath).length();
      expect(lowSize, lessThan(highSize));
    });

    test('two garbage images → pageNumbers [2, 4], plural message wording',
        () async {
      final paths = [
        await writeImage('a.jpg', validJpegBytes()),
        await writeImage('b.jpg', garbageBytes()),
        await writeImage('c.jpg', validJpegBytes()),
        await writeImage('d.jpg', garbageBytes()),
      ];

      await expectLater(
        () => PdfGenerator.generatePdf(imagePaths: paths, preProcessed: false),
        throwsA(
          isA<PdfPageDecodeException>()
              .having((e) => e.pageNumbers, 'pageNumbers', [2, 4])
              .having((e) => e.message, 'message', contains('Pages 2, 4'))
              .having((e) => e.message, 'message', contains('they'))
              .having((e) => e.message, 'message', contains('those pages')),
        ),
      );
    });

    test('after a decode failure, no output file is left behind', () async {
      final paths = [
        await writeImage('a.jpg', validJpegBytes()),
        await writeImage('b.jpg', garbageBytes()),
      ];

      await expectLater(
        () => PdfGenerator.generatePdf(imagePaths: paths, preProcessed: false),
        throwsA(isA<PdfPageDecodeException>()),
      );

      // generatePdf writes its output under the (mocked) temp directory only
      // after _buildPdf returns successfully. A decode failure must throw
      // before that write happens, so the directory stays empty.
      expect(outputDir.listSync(), isEmpty);
    });
  });
}
