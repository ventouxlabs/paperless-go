import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_providers.dart';
import 'package:paperless_go/core/theme.dart';
import 'package:paperless_go/features/documents/documents_notifier.dart';
import 'package:paperless_go/features/documents/documents_screen.dart';
import 'package:paperless_go/features/upload_queue/upload_queue_notifier.dart';

import '../../test_utils/golden_surface.dart';
import '../../test_utils/load_app_fonts.dart';

/// Never resolves, so the screen stays on its loading skeleton for the
/// duration of the test.
class _LoadingForeverNotifier extends DocumentsNotifier {
  @override
  Future<DocumentsState> build() => Completer<DocumentsState>().future;
}

class _EmptyNotifier extends DocumentsNotifier {
  @override
  Future<DocumentsState> build() async => const DocumentsState(documents: []);
}

class _ErrorNotifier extends DocumentsNotifier {
  @override
  Future<DocumentsState> build() async {
    throw Exception('Connection refused');
  }
}

Widget _harness(
  Override notifierOverride, {
  Brightness brightness = Brightness.light,
}) {
  return ProviderScope(
    overrides: [
      notifierOverride,
      tagsProvider.overrideWith((ref) async => const {}),
      correspondentsProvider.overrideWith((ref) async => const {}),
      documentTypesProvider.overrideWith((ref) async => const {}),
      savedViewsProvider.overrideWith((ref) async => const []),
      // The Library carries the upload-queue banner; an empty queue renders
      // nothing, but the real provider would open a Drift stream whose
      // close timer outlives the test.
      pendingUploadsProvider.overrideWith((ref) => Stream.value(const [])),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.light
          ? AppTheme.light()
          : AppTheme.dark(),
      home: const DocumentsScreen(),
    ),
  );
}

void main() {
  setUpAll(loadAppFontsOnce);

  testWidgets('documents list — loading skeleton', (tester) async {
    setGoldenSurfaceSize(tester, const Size(400, 800));
    await tester.pumpWidget(
      _harness(
        documentsNotifierProvider.overrideWith(_LoadingForeverNotifier.new),
      ),
    );
    // One pump only — the notifier never resolves, so pumpAndSettle would
    // hang waiting for the (nonexistent) settle point.
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/documents_list_loading.png'),
    );
  });

  testWidgets('documents list — empty state', (tester) async {
    setGoldenSurfaceSize(tester, const Size(400, 800));
    await tester.pumpWidget(
      _harness(documentsNotifierProvider.overrideWith(_EmptyNotifier.new)),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/documents_list_empty.png'),
    );
  });

  testWidgets('documents list — error state', (tester) async {
    setGoldenSurfaceSize(tester, const Size(400, 800));
    await tester.pumpWidget(
      _harness(documentsNotifierProvider.overrideWith(_ErrorNotifier.new)),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/documents_list_error.png'),
    );
  });

  testWidgets('documents list — empty state, dark', (tester) async {
    setGoldenSurfaceSize(tester, const Size(400, 800));
    await tester.pumpWidget(
      _harness(
        documentsNotifierProvider.overrideWith(_EmptyNotifier.new),
        brightness: Brightness.dark,
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/documents_list_empty_dark.png'),
    );
  });
}
