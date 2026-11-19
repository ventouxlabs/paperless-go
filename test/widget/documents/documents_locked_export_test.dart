// The Library's long-press Share / Save to folder and bulk Share / Save must
// run the same biometric check as opening a locked document, and never name
// the exported file after a locked document's real title.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_providers.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/core/services/biometric_service.dart';
import 'package:paperless_go/core/services/document_lock_service.dart';
import 'package:paperless_go/features/documents/document_detail_notifier.dart';
import 'package:paperless_go/features/documents/documents_notifier.dart';
import 'package:paperless_go/features/documents/documents_screen.dart';
import 'package:paperless_go/features/upload_queue/upload_queue_notifier.dart';

const _lockedA = Document(id: 1, title: 'Medical report');
const _lockedB = Document(id: 2, title: 'Payslip');

class _TwoLockedDocs extends DocumentsNotifier {
  @override
  Future<DocumentsState> build() async =>
      const DocumentsState(documents: [_lockedA, _lockedB], totalCount: 2);
}

class _FakeLocks implements DocumentLockService {
  _FakeLocks(this.locked);
  final Set<int> locked;

  @override
  Future<Set<int>> getLockedIds() async => locked;

  @override
  Future<bool> isLocked(int documentId) async => locked.contains(documentId);

  @override
  Future<void> lock(int documentId) async {}

  @override
  Future<void> unlock(int documentId) async {}
}

class _FakeBiometrics implements BiometricService {
  _FakeBiometrics({required this.succeed});
  final bool succeed;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<BiometricResult> authenticateResult({String reason = ''}) async {
    prompts++;
    return succeed ? BiometricResult.success : BiometricResult.failed;
  }

  @override
  Future<bool> authenticate({String reason = ''}) async =>
      (await authenticateResult(reason: reason)) == BiometricResult.success;
}

/// Records every download the screen asks for, by (id, title it names the
/// file after). Each document can be asked for under its real or masked name.
List<Override> _downloadOverrides(List<(int, String)> downloads) => [
      for (final doc in const [_lockedA, _lockedB])
        for (final title in [doc.title, 'document_${doc.id}'])
          documentDownloadProvider(doc.id, title).overrideWith((ref) async {
            downloads.add((doc.id, title));
            return '/nonexistent/${doc.id}_$title.pdf';
          }),
    ];

Future<void> _pump(
  WidgetTester tester, {
  required _FakeBiometrics biometrics,
  required List<(int, String)> downloads,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        documentsNotifierProvider.overrideWith(_TwoLockedDocs.new),
        paperlessApiProvider.overrideWithValue(
          PaperlessApi(Dio(BaseOptions(baseUrl: 'http://localhost'))),
        ),
        documentLockServiceProvider.overrideWithValue(_FakeLocks({1, 2})),
        lockedDocumentIdsProvider.overrideWith((ref) async => {1, 2}),
        tagsProvider.overrideWith((ref) async => const {}),
        correspondentsProvider.overrideWith((ref) async => const {}),
        documentTypesProvider.overrideWith((ref) async => const {}),
        savedViewsProvider.overrideWith((ref) async => const []),
        pendingUploadsProvider.overrideWith((ref) => Stream.value(const [])),
        ..._downloadOverrides(downloads),
      ],
      child: MaterialApp(home: DocumentsScreen(biometrics: biometrics)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _longPressMenu(WidgetTester tester, String title, String item) async {
  await tester.longPress(find.text(title).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

Future<void> _selectBoth(WidgetTester tester) async {
  await _longPressMenu(tester, _lockedA.title, 'Select');
  await tester.tap(find.text(_lockedB.title).first);
  await tester.pumpAndSettle();
}

const _denied = 'Authentication required to export a locked document';

void main() {
  testWidgets('long-press Share of a locked document: denied auth, no download',
      (tester) async {
    final bio = _FakeBiometrics(succeed: false);
    final downloads = <(int, String)>[];
    await _pump(tester, biometrics: bio, downloads: downloads);

    await _longPressMenu(tester, _lockedA.title, 'Share');

    expect(bio.prompts, 1);
    expect(downloads, isEmpty);
    expect(find.text(_denied), findsOneWidget);
  });

  testWidgets('long-press Share of a locked document: masked name after auth',
      (tester) async {
    final bio = _FakeBiometrics(succeed: true);
    final downloads = <(int, String)>[];
    await _pump(tester, biometrics: bio, downloads: downloads);

    await _longPressMenu(tester, _lockedA.title, 'Share');

    expect(bio.prompts, 1);
    expect(downloads, [(1, 'document_1')]);
  });

  testWidgets(
      'long-press Save to folder of a locked document: denied auth, no download',
      (tester) async {
    final bio = _FakeBiometrics(succeed: false);
    final downloads = <(int, String)>[];
    await _pump(tester, biometrics: bio, downloads: downloads);

    await _longPressMenu(tester, _lockedA.title, 'Save to folder');

    expect(bio.prompts, 1);
    expect(downloads, isEmpty);
    expect(find.text(_denied), findsOneWidget);
  });

  testWidgets('bulk Share with locked documents: denied auth, no download',
      (tester) async {
    final bio = _FakeBiometrics(succeed: false);
    final downloads = <(int, String)>[];
    await _pump(tester, biometrics: bio, downloads: downloads);

    await _selectBoth(tester);
    await tester.tap(find.byTooltip('Share'));
    await tester.pumpAndSettle();

    expect(bio.prompts, 1);
    expect(downloads, isEmpty);
    expect(find.text(_denied), findsOneWidget);
  });

  testWidgets('bulk Share with locked documents: one prompt, masked names',
      (tester) async {
    final bio = _FakeBiometrics(succeed: true);
    final downloads = <(int, String)>[];
    await _pump(tester, biometrics: bio, downloads: downloads);

    await _selectBoth(tester);
    await tester.tap(find.byTooltip('Share'));
    await tester.pumpAndSettle();

    expect(bio.prompts, 1);
    expect(downloads, [(1, 'document_1'), (2, 'document_2')]);
  });

  testWidgets('bulk Save to folder with locked documents: denied auth, no download',
      (tester) async {
    final bio = _FakeBiometrics(succeed: false);
    final downloads = <(int, String)>[];
    await _pump(tester, biometrics: bio, downloads: downloads);

    await _selectBoth(tester);
    await tester.tap(find.byTooltip('Save to folder'));
    await tester.pumpAndSettle();

    expect(bio.prompts, 1);
    expect(downloads, isEmpty);
    expect(find.text(_denied), findsOneWidget);
  });
}
