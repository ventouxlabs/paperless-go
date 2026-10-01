// The Trash row must never present a document's created date as the date it
// was deleted.

import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/features/trash/trash_screen.dart';

void main() {
  test('parses deleted_at from the trash endpoint', () {
    final doc = Document.fromJson({
      'id': 1,
      'title': 't',
      'deleted_at': '2026-09-30T10:00:00Z',
    });

    expect(doc.deletedAt, DateTime.utc(2026, 9, 30, 10));
  });

  test('prefers deleted_at over modified', () {
    final doc = Document(
      id: 1,
      title: 't',
      created: DateTime(2020, 1, 2),
      modified: DateTime(2026, 9, 28),
      deletedAt: DateTime(2026, 9, 30),
    );

    expect(trashDeletedLabel(doc), 'Deleted Sep 30, 2026');
  });

  test('falls back to modified — set when the document was moved to trash', () {
    final doc = Document(
      id: 1,
      title: 't',
      created: DateTime(2020, 1, 2),
      modified: DateTime(2026, 9, 28),
    );

    expect(trashDeletedLabel(doc), 'Deleted Sep 28, 2026');
  });

  test('says just "Deleted" when both dates are missing, not the created date',
      () {
    final doc = Document(id: 1, title: 't', created: DateTime(2020, 1, 2));

    expect(trashDeletedLabel(doc), 'Deleted');
  });
}
