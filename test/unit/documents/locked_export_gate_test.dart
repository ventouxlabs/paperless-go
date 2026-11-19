import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/documents/locked_export_gate.dart';

void main() {
  group('clearForExport', () {
    test('no locked document: allowed without prompting', () async {
      var prompts = 0;
      final clearance = await clearForExport(
        documentIds: const [1, 2],
        loadLockedIds: () async => {7},
        authenticate: () async {
          prompts++;
          return true;
        },
      );
      expect(clearance.allowed, isTrue);
      expect(prompts, 0);
      expect(clearance.exportTitleFor(1, 'Invoice'), 'Invoice');
    });

    test('locked document: prompts once and allows on success', () async {
      var prompts = 0;
      final clearance = await clearForExport(
        documentIds: const [1, 2, 3],
        loadLockedIds: () async => {2, 3},
        authenticate: () async {
          prompts++;
          return true;
        },
      );
      expect(prompts, 1);
      expect(clearance.allowed, isTrue);
    });

    test('locked document: denied when authentication fails', () async {
      final clearance = await clearForExport(
        documentIds: const [1, 2],
        loadLockedIds: () async => {2},
        authenticate: () async => false,
      );
      expect(clearance.allowed, isFalse);
    });

    test('authentication throwing is a denial', () async {
      final clearance = await clearForExport(
        documentIds: const [2],
        loadLockedIds: () async => {2},
        authenticate: () async => throw Exception('platform'),
      );
      expect(clearance.allowed, isFalse);
    });

    test('unreadable lock set fails closed: prompts and masks all', () async {
      var prompts = 0;
      final clearance = await clearForExport(
        documentIds: const [1, 2],
        loadLockedIds: () async => throw Exception('db'),
        authenticate: () async {
          prompts++;
          return true;
        },
      );
      expect(prompts, 1);
      expect(clearance.allowed, isTrue);
      expect(clearance.exportTitleFor(1, 'Invoice'), 'document_1');
      expect(clearance.exportTitleFor(2, 'Payslip'), 'document_2');
    });
  });

  group('ExportClearance.exportTitleFor', () {
    test('locked document never exposes its real title', () async {
      final clearance = await clearForExport(
        documentIds: const [5, 6],
        loadLockedIds: () async => {5},
        authenticate: () async => true,
      );
      expect(clearance.exportTitleFor(5, 'Medical report'), 'document_5');
      expect(clearance.exportTitleFor(6, 'Receipt'), 'Receipt');
    });

    test('locked set is not mutable from outside', () async {
      final clearance = await clearForExport(
        documentIds: const [5],
        loadLockedIds: () async => {5},
        authenticate: () async => true,
      );
      expect(() => clearance.lockedIds.add(9), throwsUnsupportedError);
    });
  });
}
