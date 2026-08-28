import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/database/app_database.dart';
import 'package:paperless_go/features/upload_queue/queue_error_text.dart';
import 'package:paperless_go/features/upload_queue/queue_row_status.dart';

/// The two pure pieces behind the queue screen. Both are string/enum functions
/// on purpose: the screen's real logic is "what do we say about this row", and
/// that should be answerable without pumping a widget.
void main() {
  PendingUpload row({
    bool isFailed = false,
    int retryCount = 0,
    String? serverUrl = 'https://paperless.example.com',
    String? lastError,
  }) {
    return PendingUpload(
      id: 1,
      filePath: '/queue/doc.pdf',
      filename: 'doc.pdf',
      queuedAt: DateTime(2026, 8, 18),
      retryCount: retryCount,
      isFailed: isFailed,
      serverUrl: serverUrl,
      lastError: lastError,
    );
  }

  group('queueRowStatus', () {
    test('a fresh row is waiting', () {
      expect(
        queueRowStatus(row(), activeServer: 'https://paperless.example.com'),
        QueueRowStatus.waiting,
      );
    });

    test('a row that has failed an attempt is retrying', () {
      expect(
        queueRowStatus(
          row(retryCount: 2),
          activeServer: 'https://paperless.example.com',
        ),
        QueueRowStatus.retrying,
      );
    });

    test('terminal failure outranks everything else', () {
      expect(
        queueRowStatus(
          row(isFailed: true, retryCount: 5),
          activeServer: 'https://paperless.example.com',
        ),
        QueueRowStatus.failed,
      );
    });

    test('a row for a different server is reported as such', () {
      expect(
        queueRowStatus(
          row(serverUrl: 'https://other.example.com'),
          activeServer: 'https://paperless.example.com',
        ),
        QueueRowStatus.otherServer,
      );
    });

    test('a row with no server at all is legacy, not other-server', () {
      expect(
        queueRowStatus(
          row(serverUrl: null),
          activeServer: 'https://paperless.example.com',
        ),
        QueueRowStatus.legacy,
      );
    });

    test('signed out, rows are waiting rather than stranded elsewhere', () {
      // Signing out must not relabel the whole queue as "queued for another
      // server" — alarming, and untrue: they are waiting for a session.
      expect(queueRowStatus(row(), activeServer: null), QueueRowStatus.waiting);
    });

    test('only failed and legacy rows ask for attention', () {
      expect(queueRowNeedsAttention(QueueRowStatus.failed), isTrue);
      expect(queueRowNeedsAttention(QueueRowStatus.legacy), isTrue);
      expect(queueRowNeedsAttention(QueueRowStatus.waiting), isFalse);
      expect(queueRowNeedsAttention(QueueRowStatus.retrying), isFalse);
      expect(queueRowNeedsAttention(QueueRowStatus.otherServer), isFalse);
    });
  });

  group('queueErrorDetail', () {
    test('a stringified exception is worth expanding', () {
      // A self-hoster debugging their own server wants this.
      const raw =
          'DioException [connectionError]: SocketException: '
          'Failed host lookup: paperless.private.lan';
      expect(queueErrorDetail(raw), raw);
    });

    test('our own plain-language messages are not', () {
      // Seen on a real device: the summary and the "Details" line said the
      // same thing in slightly different words, one directly under the other.
      expect(
        queueErrorDetail('Gave up after 30 days without reaching the server.'),
        isNull,
      );
      expect(
        queueErrorDetail(
          'The queued file is no longer available on this device.',
        ),
        isNull,
      );
      expect(
        queueErrorDetail('The queued tags for this document are unreadable.'),
        isNull,
      );
      expect(
        queueErrorDetail(
          'This file sat in the upload queue for over 30 days without '
          'reaching the server, and has been deleted from this device.',
        ),
        isNull,
      );
    });

    test('nothing to expand when there is no error', () {
      expect(queueErrorDetail(null), isNull);
      expect(queueErrorDetail('  '), isNull);
    });
  });

  group('queueErrorSummary', () {
    test('nothing to say when there is no error', () {
      expect(queueErrorSummary(null), isNull);
      expect(queueErrorSummary('   '), isNull);
    });

    test('an unreachable server reads as unreachable', () {
      expect(
        queueErrorSummary(
          "DioException [connectionError]: SocketException: Connection refused",
        ),
        'Could not reach the server.',
      );
    });

    test('the retention message is recognised', () {
      expect(
        queueErrorSummary('Gave up after 30 days without reaching the server.'),
        'Stopped trying after waiting too long to reach it.',
      );
    });

    test(
      'the released-file message says the file is gone, not just given up',
      () {
        // A row that reaches this state has actually lost its file, not just
        // stopped retrying — the generic retention summary would say less than
        // is true.
        expect(
          queueErrorSummary(
            'This file sat in the upload queue for over 30 days without '
            'reaching the server, and has been deleted from this device.',
          ),
          'Stopped trying after waiting too long to reach it, and the file was '
          'deleted from this device to free up storage.',
        );
      },
    );

    test('a missing file reads as a missing file', () {
      expect(
        queueErrorSummary(
          'The queued file is no longer available on this '
          'device.',
        ),
        'The file is no longer on this device.',
      );
    });

    test('an unrecognised error still says something useful', () {
      expect(queueErrorSummary('kaboom'), 'The upload did not complete.');
    });

    test('never echoes the raw error, which carries the server URL', () {
      // The stored string is a DioException dump including the full request
      // URL. The summary is what lands on the card, so it must not carry it.
      const raw =
          'DioException [badResponse]: '
          'https://paperless.private.example.com/api/documents/post_document/';
      final summary = queueErrorSummary(raw);
      expect(summary, isNotNull);
      expect(summary, isNot(contains('paperless.private.example.com')));
    });
  });
}
