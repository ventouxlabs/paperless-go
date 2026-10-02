// Golden baselines are rendered on CI's pinned Flutter (see README.md). A
// different local Flutter rasterises text slightly differently, so exact
// comparison fails locally on every run. Off CI, accept diffs up to
// [_localTolerance]; on CI (`CI=true`, set by GitHub Actions) stay exact.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fraction of pixels (0–1) allowed to differ off CI. Version drift observed
/// so far peaks at 0.68% (3.47 vs 3.41.3).
const double _localTolerance = 0.01;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final comparator = goldenFileComparator;
  if (Platform.environment['CI'] != 'true' &&
      comparator is LocalFileComparator) {
    goldenFileComparator = _TolerantComparator(
      comparator.basedir.resolve('placeholder_test.dart'),
      _localTolerance,
    );
  }
  await testMain();
}

class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile, this.tolerance);

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
