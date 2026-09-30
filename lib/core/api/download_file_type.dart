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

/// The MIME type to declare for a file saved or shared under [fileName].
String mimeTypeForFileName(String fileName) =>
    lookupMimeType(fileName.toLowerCase()) ?? 'application/octet-stream';

String? _dispositionFileName(String? header) {
  if (header == null) return null;
  // RFC 6266 prefers the extended filename*= form when both are present.
  final extended =
      RegExp(r"filename\*\s*=\s*[^']*'[^']*'([^;]+)", caseSensitive: false)
          .firstMatch(header);
  if (extended != null) {
    try {
      return Uri.decodeComponent(extended.group(1)!.trim());
    } on ArgumentError {
      // Malformed percent-encoding: fall through to the plain form.
    }
  }
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
