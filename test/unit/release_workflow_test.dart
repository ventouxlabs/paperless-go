import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release workflow pins every action to a full commit SHA', () {
    final uses = RegExp(r'^\s*-?\s*uses:\s*(\S+)', multiLine: true);
    final sha = RegExp(r'^[^@\s]+@[0-9a-f]{40}$');
    final source = File('.github/workflows/release.yml').readAsStringSync();
    final refs = uses.allMatches(source).map((m) => m.group(1)!).toList();

    expect(refs, isNotEmpty);
    final unpinned = refs.where((r) => !sha.hasMatch(r)).toList();
    expect(unpinned, isEmpty, reason: 'Pin to a commit SHA, not a tag: $unpinned');
  });
}
