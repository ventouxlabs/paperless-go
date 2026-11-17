import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every workflow pins every action to a full commit SHA', () {
    final uses = RegExp(r'^\s*-?\s*uses:\s*(\S+)', multiLine: true);
    final sha = RegExp(r'^[^@\s]+@[0-9a-f]{40}$');
    final workflows = Directory('.github/workflows')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.yml') || f.path.endsWith('.yaml'))
        .toList();

    expect(workflows, isNotEmpty);
    for (final file in workflows) {
      final source = file.readAsStringSync();
      final refs = uses.allMatches(source).map((m) => m.group(1)!).toList();
      final unpinned = refs.where((r) => !sha.hasMatch(r)).toList();
      expect(unpinned, isEmpty,
          reason: '${file.path}: pin to a commit SHA, not a tag: $unpinned');
    }
  });

  test('dependabot keeps pinned github-actions SHAs up to date', () {
    final config = File('.github/dependabot.yml');
    expect(config.existsSync(), isTrue, reason: '.github/dependabot.yml is missing');
    final source = config.readAsStringSync();
    expect(source, contains('package-ecosystem: "github-actions"'));
    expect(source, contains('directory: "/"'));
  });
}
