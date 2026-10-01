import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';

/// What a downloaded document really is, decided from the download response.
///
/// `/api/documents/<id>/download/` (and `/preview/`) serve the archived PDF
/// only when the document has one. Otherwise they serve the original as-is —
/// plain text, CSV, an image — with its own Content-Type (#43). Nothing here
/// may assume PDF.

/// Only a short lowercase alphanumeric suffix is ever taken from the server:
/// the headers are untrusted and must not put a path or junk in a file name.
final _safeExtension = RegExp(r'^[a-z0-9]{1,8}$');

/// Types whose `extensionFromMime` answer is wrong for a saved file.
/// `application/octet-stream` means "unknown", which the package maps to
/// "so" (a shared library).
const _mimeExtensionOverrides = <String, String?>{
  'message/rfc822': 'eml',
  'application/octet-stream': null,
};

/// The extension (no dot) to save a download under.
///
/// Tries, in order: the file name in Content-Disposition, the Content-Type,
/// then [originalFileName]. Falls back to `bin`, never to `pdf`.
String downloadExtension({
  String? contentDisposition,
  String? contentType,
  String? originalFileName,
}) =>
    _extensionOfName(_dispositionFileName(contentDisposition)) ??
    _extensionOfMime(contentType) ??
    _extensionOfName(originalFileName) ??
    'bin';

/// Whether a downloaded file (named by [downloadExtension]) is a PDF.
bool isPdfFile(String path) => path.toLowerCase().endsWith('.pdf');

/// The extension (no dot) a downloaded file was saved under, or `''`.
String fileExtensionOf(String path) {
  final base = path.split(RegExp(r'[/\\]')).last;
  final dot = base.lastIndexOf('.');
  return dot <= 0 ? '' : base.substring(dot + 1).toLowerCase();
}

/// A PDF-only feature (annotate, compress) was asked to work on a document
/// Paperless serves as something else — an original it never archived.
class NotPdfDocumentException implements Exception {
  const NotPdfDocumentException(this.extension, this.action);

  /// Extension of the file the server actually sent, e.g. `txt`.
  final String extension;

  /// What could not be done, phrased to follow "can't be", e.g. `annotated`.
  final String action;

  /// User-facing message: plain language, no internals.
  String get message => extension.isEmpty
      ? "This document isn't a PDF, so it can't be $action."
      : "This document is a .$extension file, not a PDF, so it can't be "
          '$action.';

  @override
  String toString() => 'NotPdfDocumentException: $message';
}

/// Throws [NotPdfDocumentException] unless [path] is a PDF.
void ensurePdfFile(String path, {required String action}) {
  if (!isPdfFile(path)) {
    throw NotPdfDocumentException(fileExtensionOf(path), action);
  }
}

/// Delete copies of [path] saved under another extension, e.g. the cached
/// `preview_5.txt` once the document is archived and `preview_5.pdf` arrives.
///
/// Only a sibling named exactly `<same stem>.<ext>` is removed, where `<ext>`
/// is a name [downloadExtension] could have produced (so lowercase only, by
/// design: nothing else in the temp dir is ours to remove). A file that can't be
/// deleted is logged and skipped: it is only a stale cache entry, and the
/// download it trails has already succeeded.
Future<void> deleteOtherTypeVariants(String path) async {
  final file = File(path);
  final name = file.uri.pathSegments.last;
  final dot = name.lastIndexOf('.');
  if (dot <= 0) return;
  final stem = name.substring(0, dot + 1);
  try {
    await for (final entry in file.parent.list(followLinks: false)) {
      if (entry is! File) continue;
      final other = entry.uri.pathSegments.last;
      if (other == name || !other.startsWith(stem)) continue;
      if (!_safeExtension.hasMatch(other.substring(stem.length))) continue;
      try {
        await entry.delete();
      } on FileSystemException catch (e) {
        debugPrint('Could not delete stale download $other: ${e.message}');
      }
    }
  } on FileSystemException catch (e) {
    debugPrint('Could not list ${file.parent.path} for stale downloads: '
        '${e.message}');
  }
}

/// The MIME type to declare for a file saved or shared under [fileName].
String mimeTypeForFileName(String fileName) =>
    lookupMimeType(fileName.toLowerCase()) ?? 'application/octet-stream';

String? _dispositionFileName(String? header) {
  if (header == null) return null;
  // RFC 6266 prefers the extended filename*= form when both are present.
  // It is left percent-encoded: only the extension is used, which is plain
  // ASCII, and decoding would throw on non-UTF-8 charsets (RFC 5987 allows
  // e.g. iso-8859-1). An encoded char in the extension just fails _safe.
  final extended =
      RegExp(r"filename\*\s*=\s*[^']*'[^']*'([^;]+)", caseSensitive: false)
          .firstMatch(header);
  if (extended != null) return extended.group(1)!.trim();
  final plain = RegExp(r'filename\s*=\s*"([^"]*)"|filename\s*=\s*([^;]+)',
          caseSensitive: false)
      .firstMatch(header);
  return (plain?.group(1) ?? plain?.group(2))?.trim();
}

String? _extensionOfName(String? name) {
  if (name == null) return null;
  final base = name.split(RegExp(r'[/\\]')).last;
  final dot = base.lastIndexOf('.');
  if (dot < 0) return null;
  return _safe(base.substring(dot + 1));
}

String? _extensionOfMime(String? contentType) {
  if (contentType == null) return null;
  final mime = contentType.split(';').first.trim().toLowerCase();
  if (mime.isEmpty) return null;
  final extension = _mimeExtensionOverrides.containsKey(mime)
      ? _mimeExtensionOverrides[mime]
      : extensionFromMime(mime);
  return extension == null ? null : _safe(extension);
}

String? _safe(String extension) {
  final lower = extension.toLowerCase();
  return _safeExtension.hasMatch(lower) ? lower : null;
}
