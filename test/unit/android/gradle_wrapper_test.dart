import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gradle wrapper pins distributionSha256Sum', () {
    final lines = File('android/gradle/wrapper/gradle-wrapper.properties')
        .readAsLinesSync();
    final sums = lines
        .where((l) => l.startsWith('distributionSha256Sum='))
        .toList();
    expect(sums, hasLength(1));
    expect(
      sums.single.substring('distributionSha256Sum='.length),
      matches(RegExp(r'^[0-9a-f]{64}$')),
    );
  });
}
