// Regression tests for #43: a download is named after the type the server
// actually sent, not an assumed `.pdf`.
//
// Header values below are copied from a Paperless-ngx 3.2.1 server
// (Accept: application/json; version=9), for a text document with no
// archive version and for an archived PDF.
//
// Run: flutter test test/unit/api/download_file_type_test.dart

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
}
