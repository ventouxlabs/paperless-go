/// Turns a stored `pending_uploads.lastError` into something worth showing.
///
/// The queue stores `e.toString()`, so the raw value is a `DioException` dump
/// (with the full request URL) or a bare `SocketException`. `friendlyApiMessage`
/// cannot help here — it keys off the live exception object, and by the time a
/// row reaches this screen the exception is long gone and only its string
/// survives.
///
/// Pure and string-only so it can be table-tested without a database.
library;

/// A one-line summary of [rawError], suitable for a queue row.
///
/// Returns null when there is nothing useful to say, so callers can omit the
/// line entirely rather than render "An unexpected error occurred." under every
/// row that is simply still waiting.
String? queueErrorSummary(String? rawError) {
  if (rawError == null) return null;
  final raw = rawError.trim();
  if (raw.isEmpty) return null;

  // Ordered most-specific first: a DioException wrapping a SocketException
  // matches several of these, and "could not reach the server" is the more
  // useful of the two readings. The two retention messages also need this
  // ordering — 'has been deleted from this device' must be checked before the
  // generic 'Gave up after' match would otherwise never fire.
  const patterns = <String, String>{
    'has been deleted from this device':
        'Stopped trying after waiting too long to reach it, and the file was '
        'deleted from this device to free up storage.',
    'Gave up after': 'Stopped trying after waiting too long to reach it.',
    'no longer available': 'The file is no longer on this device.',
    'unreadable': 'The saved tags for this document could not be read.',
    'SocketException': 'Could not reach the server.',
    'Failed host lookup': 'Could not find that server address.',
    'connectionTimeout': 'The server took too long to respond.',
    'receiveTimeout': 'The server took too long to respond.',
    'sendTimeout': 'The upload timed out.',
    'connectionError': 'Could not reach the server.',
    'NotAuthenticatedException': 'You were not signed in.',
    '401': 'Your server rejected the sign-in for this upload.',
    '403': 'Your account is not allowed to upload this document.',
    '413': 'The server rejected this document as too large.',
    '500': 'The server had a problem accepting this document.',
  };

  for (final entry in patterns.entries) {
    if (raw.contains(entry.key)) return entry.value;
  }
  return 'The upload did not complete.';
}

/// Messages this app wrote itself, in plain language, into `lastError`.
///
/// These need no "Details" expander: the stored string IS the explanation, so
/// showing it under a summary of itself just says the same thing twice in
/// slightly different words — which is exactly how it read on a real device.
const _ownMessages = [
  'Gave up after',
  'has been deleted from this device',
  'The queued file is no longer available',
  'The queued tags for this document are unreadable',
];

/// The raw error, or null when there is nothing a summary has not already said.
///
/// Only a stringified exception earns the expander. That is the case where the
/// detail genuinely helps — a self-hoster wants to see `Failed host lookup` and
/// their own server address; nobody needs to expand a row to re-read a sentence
/// this app composed.
String? queueErrorDetail(String? rawError) {
  final raw = rawError?.trim();
  if (raw == null || raw.isEmpty) return null;
  if (_ownMessages.any(raw.contains)) return null;
  return raw;
}
