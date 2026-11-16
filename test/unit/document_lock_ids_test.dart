import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/services/document_lock_service.dart';

void main() {
  group('LockedIdsX.isLocked', () {
    test('fails closed while loading', () {
      expect(const AsyncValue<Set<int>>.loading().isLocked(1), isTrue);
    });

    test('fails closed on error', () {
      final v = AsyncValue<Set<int>>.error('boom', StackTrace.empty);
      expect(v.isLocked(1), isTrue);
    });

    test('uses the loaded set', () {
      const v = AsyncValue<Set<int>>.data({1});
      expect(v.isLocked(1), isTrue);
      expect(v.isLocked(2), isFalse);
    });
  });
}
