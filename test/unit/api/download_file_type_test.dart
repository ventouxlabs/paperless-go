// Regression tests for #43: a download is named after the type the server
// actually sent, not an assumed `.pdf`.
//
// Header values below are copied from a Paperless-ngx 3.2.1 server
// (Accept: application/json; version=9), for a text document with no
// archive version and for an archived PDF.
//
// Run: flutter test test/unit/api/download_file_type_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/download_file_type.dart';

void main() {
  group('downloadExtension', () {
    test('text document without an archive version is .txt, not .pdf', () {
      expect(
        downloadExtension(
          contentDisposition: 'attachment; '
              'filename="2026-09-30 TXT-TEST-43 (delete me).txt"; '
              "filename*=utf-8''2026-09-30%20TXT-TEST-43%20%28delete%20me%29.txt",
          contentType: 'text/plain; charset=utf-8',
        ),
        'txt',
      );
    });

    test('archived document is .pdf', () {
      expect(
        downloadExtension(
          contentDisposition: 'attachment; '
              'filename="2026-05-01 sample-utility-bill.pdf"; '
              "filename*=utf-8''2026-05-01%20sample-utility-bill.pdf",
          contentType: 'application/pdf',
        ),
        'pdf',
      );
    });

    test('falls back to Content-Type when there is no filename', () {
      expect(downloadExtension(contentType: 'image/jpeg'), 'jpg');
      expect(downloadExtension(contentType: 'TEXT/CSV; charset=utf-8'), 'csv');
    });

    test('corrects the mime package quirks for e-mail and binary types', () {
      expect(downloadExtension(contentType: 'message/rfc822'), 'eml');
      // octet-stream says nothing about the type; the package maps it to
      // "so" (a shared library), which must never become the file name.
      expect(
        downloadExtension(
          contentType: 'application/octet-stream',
          originalFileName: 'scan.TIFF',
        ),
        'tiff',
      );
    });

    test('falls back to the original file name, then to bin', () {
      expect(downloadExtension(originalFileName: 'Notes 43.txt'), 'txt');
      expect(downloadExtension(), 'bin');
      expect(downloadExtension(contentType: 'application/octet-stream'), 'bin');
    });

    test('a filename* that is not valid UTF-8 never aborts the download', () {
      // RFC 5987 allows other charsets; Uri.decodeComponent would throw a
      // FormatException on these. The extension part is plain ASCII anyway.
      expect(
        downloadExtension(
          contentDisposition: "attachment; filename*=iso-8859-1''caf%E9.txt",
        ),
        'txt',
      );
      expect(
        downloadExtension(
          contentDisposition: "attachment; filename*=utf-8''a%FF.pdf",
          contentType: 'text/plain',
        ),
        'pdf',
      );
    });

    test('only ever takes a short alphanumeric extension from the headers', () {
      // A hostile or malformed header must not smuggle a path or a long
      // suffix into the local file name.
      expect(
        downloadExtension(
          contentDisposition: 'attachment; filename="../../x.sh/../evil"',
          contentType: 'application/pdf',
        ),
        'pdf',
      );
      expect(
        downloadExtension(
          contentDisposition: 'attachment; filename="a.pdf;rm -rf"',
          contentType: 'text/plain',
        ),
        'txt',
      );
      expect(
        downloadExtension(
          contentDisposition: 'attachment; filename="a.averyveryverylongext"',
        ),
        'bin',
      );
    });
  });

  group('ensurePdfFile', () {
    test('accepts a PDF download', () {
      expect(() => ensurePdfFile('/tmp/1_bill.PDF', action: 'annotated'),
          returnsNormally);
    });

    test('refuses anything else with a plain-language reason', () {
      expect(
        () => ensurePdfFile('/tmp/20_notes.txt', action: 'annotated'),
        throwsA(isA<NotPdfDocumentException>().having(
          (e) => e.message,
          'message',
          "This document is a .txt file, not a PDF, so it can't be annotated.",
        )),
      );
    });
  });

  group('mimeTypeForFileName', () {
    test('derives the type from the extension', () {
      expect(mimeTypeForFileName('1_note.txt'), 'text/plain');
      expect(mimeTypeForFileName('invoice.pdf'), 'application/pdf');
      expect(mimeTypeForFileName('photo.JPG'), 'image/jpeg');
    });

    test('unknown or missing extension is a generic binary', () {
      expect(mimeTypeForFileName('file.bin'), 'application/octet-stream');
      expect(mimeTypeForFileName('noext'), 'application/octet-stream');
    });
  });

  // A document first downloaded as its .txt original and later archived is
  // then downloaded as .pdf. The .txt copy must not linger in the cache.
  group('deleteOtherTypeVariants', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('variants_test_'));
    tearDown(() => dir.deleteSync(recursive: true));

    File touch(String name) =>
        File('${dir.path}/$name')..writeAsStringSync(name);

    Set<String> remaining() =>
        dir.listSync().map((e) => e.path.split('/').last).toSet();

    test('deletes the same name saved under another extension', () async {
      touch('preview_5.txt');
      touch('preview_5.bin');
      final kept = touch('preview_5.pdf');

      await deleteOtherTypeVariants(kept.path);

      expect(remaining(), {'preview_5.pdf'});
    });

    test('leaves other documents and other prefixes alone', () async {
      touch('preview_12.txt');
      touch('preview_5x.txt');
      touch('annotate_5.txt');
      touch('5_preview_5.txt');
      final kept = touch('preview_5.pdf');

      await deleteOtherTypeVariants(kept.path);

      expect(remaining(), {
        'preview_5.pdf',
        'preview_12.txt',
        'preview_5x.txt',
        'annotate_5.txt',
        '5_preview_5.txt',
      });
    });

    test('only treats a short alphanumeric suffix as an extension', () async {
      // A title containing a dot must not make another title look like a
      // variant: "5_invoice.v2.pdf" is not "5_invoice" + extension.
      touch('5_invoice.v2.pdf');
      touch('5_invoice.toolongextension');
      touch('5_invoice.TXT');
      final kept = touch('5_invoice.pdf');

      await deleteOtherTypeVariants(kept.path);

      expect(remaining(), {
        '5_invoice.pdf',
        '5_invoice.v2.pdf',
        '5_invoice.toolongextension',
        '5_invoice.TXT',
      });
    });

    test('does nothing for a file without an extension', () async {
      touch('preview_5.txt');
      final kept = touch('preview_5');

      await deleteOtherTypeVariants(kept.path);

      expect(remaining(), {'preview_5', 'preview_5.txt'});
    });
  });
}
