import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/auth/secure_storage.dart';
import 'package:paperless_go/core/services/export_destination_providers.dart';
import 'package:paperless_go/core/services/export_destination_service.dart';
import 'package:paperless_go/shared/save_to_folder_action.dart';
import 'package:saf/saf.dart';

import '../../helpers/fake_saf.dart';

/// Hosts the helper behind a button so it runs with a real Scaffold,
/// dialogs, and ScaffoldMessenger.
class _Host extends ConsumerWidget {
  const _Host({required this.onPressed});

  final Future<SaveToFolderResult> Function(BuildContext, WidgetRef) onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => onPressed(context, ref),
          child: const Text('go'),
        ),
      ),
    );
  }
}

/// Taps [label] and lets the helper run to completion. The helper does real
/// file I/O (`File.exists`), which never resolves inside the default
/// fake-async test zone, so the interaction runs under [WidgetTester.runAsync].
///
/// pumpAndSettle only waits for frames, so after the tap this polls [until]
/// (a predicate on test state or the widget tree) with real delays, up to a
/// generous cap, before settling. A fixed sleep was flaky under CPU load.
Future<void> tapAndSettle(
  WidgetTester tester,
  String label, {
  required bool Function() until,
}) =>
    tester.runAsync(() async {
      await tester.tap(find.text(label));
      for (var i = 0; i < 500 && !until(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
      expect(until(), isTrue, reason: 'timed out waiting after tapping $label');
      await tester.pumpAndSettle();
    });

bool shown(String text) => find.text(text).evaluate().isNotEmpty;

void main() {
  late Directory tempDir;
  late FakeSaf saf;
  late ExportDestinationService service;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    tempDir = await Directory.systemTemp.createTemp('save_action_test_');
    saf = FakeSaf();
    service = ExportDestinationService(
      storage: SecureStorageService(storage: const FlutterSecureStorage()),
      saf: saf,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  /// A folder is configured and its grant is live.
  void configureReadyFolder() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'downloads_uri': pickedTreeUri,
      'downloads_name': 'Download',
    });
    saf.permissions = [grantFor(persistedTreeUri)];
  }

  List<ExportFile> makeFiles(int count) => [
        for (var i = 0; i < count; i++)
          (
            path: (File('${tempDir.path}/doc$i.pdf')..writeAsStringSync('pdf'))
                .path,
            name: 'doc$i.pdf',
          ),
      ];

  Future<SaveToFolderResult?> pumpAndTap(
    WidgetTester tester, {
    required ProduceExportFiles produce,
    ShareFiles? share,
  }) async {
    SaveToFolderResult? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [exportDestinationServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          home: _Host(
            onPressed: (context, ref) async {
              result = await saveToFolderWithFallback(
                context: context,
                ref: ref,
                produceFiles: produce,
                shareFiles: share ?? (_, __) async {},
              );
              return result!;
            },
          ),
        ),
      ),
    );
    await tapAndSettle(tester, 'go', until: () => result != null);
    return result;
  }

  group('saveToFolderWithFallback', () {
    testWidgets('writes every file when a folder is ready and reports it',
        (tester) async {
      configureReadyFolder();
      var produced = 0;
      final result = await pumpAndTap(tester, produce: () async {
        produced++;
        return makeFiles(2);
      });

      expect(produced, 1);
      expect(saf.pasted.map((p) => p.name), ['doc0.pdf', 'doc1.pdf']);
      expect(result?.saved, 2);
      expect(result?.failed, 0);
      expect(find.text('Saved 2 files to Download'), findsOneWidget);
    });

    testWidgets('cancelling the folder prompt produces nothing', (tester) async {
      var produced = 0;
      SaveToFolderResult? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exportDestinationServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            home: _Host(
              onPressed: (context, ref) async {
                result = await saveToFolderWithFallback(
                  context: context,
                  ref: ref,
                  produceFiles: () async {
                    produced++;
                    return makeFiles(1);
                  },
                );
                return result!;
              },
            ),
          ),
        ),
      );
      await tapAndSettle(tester, 'go',
          until: () => shown('Choose a download folder'));
      expect(find.text('Choose a download folder'), findsOneWidget);

      await tapAndSettle(tester, 'Cancel', until: () => result != null);

      expect(produced, 0, reason: 'a cancelled prompt must not download');
      expect(saf.pasted, isEmpty);
      expect(result?.didExport, isFalse);
      expect(result?.sharedInstead, isFalse);
    });

    testWidgets('"Share instead" produces the files and shares them',
        (tester) async {
      final shared = <ExportFile>[];
      SaveToFolderResult? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exportDestinationServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            home: _Host(
              onPressed: (context, ref) async {
                result = await saveToFolderWithFallback(
                  context: context,
                  ref: ref,
                  produceFiles: () async => makeFiles(2),
                  shareFiles: (files, _) async => shared.addAll(files),
                );
                return result!;
              },
            ),
          ),
        ),
      );
      await tapAndSettle(tester, 'go', until: () => shown('Share instead'));
      await tapAndSettle(tester, 'Share instead',
          until: () => result != null);

      expect(shared.map((f) => f.name), ['doc0.pdf', 'doc1.pdf']);
      expect(saf.pasted, isEmpty);
      expect(result?.sharedInstead, isTrue);
      expect(result?.saved, 2);
    });

    testWidgets('"Choose folder" runs the picker, then saves', (tester) async {
      saf.pickResult = pickedDir(pickedTreeUri);
      saf.permissions = [grantFor(persistedTreeUri)];
      SaveToFolderResult? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exportDestinationServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            home: _Host(
              onPressed: (context, ref) async {
                result = await saveToFolderWithFallback(
                  context: context,
                  ref: ref,
                  produceFiles: () async => makeFiles(1),
                );
                return result!;
              },
            ),
          ),
        ),
      );
      await tapAndSettle(tester, 'go', until: () => shown('Choose folder'));
      await tapAndSettle(tester, 'Choose folder',
          until: () => result != null);

      expect(saf.pickCalls, 1);
      expect(saf.pasted.single.name, 'doc0.pdf');
      expect(result?.saved, 1);
      expect(find.text('Saved doc0.pdf to Download'), findsOneWidget);
    });

    testWidgets(
        'a grant revoked mid-batch prompts once and retries the rest against '
        'the new folder', (tester) async {
      configureReadyFolder();
      // First file lands, second hits a revoked grant, then the re-pick
      // succeeds and the remaining two are retried.
      saf.pasteErrors = [
        null,
        const SafPermissionException(pickedTreeUri, 'revoked'),
      ];
      // The OS stops listing the grant at the same moment the write fails.
      saf.onPaste = (call) {
        if (call == 1) saf.permissions = [];
      };
      const newTree = 'content://com.android.externalstorage.documents/tree/'
          'primary%3ADocuments';
      saf.pickResult = pickedDir('$newTree/document/primary%3ADocuments',
          name: 'Documents');
      SaveToFolderResult? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exportDestinationServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            home: _Host(
              onPressed: (context, ref) async {
                result = await saveToFolderWithFallback(
                  context: context,
                  ref: ref,
                  produceFiles: () async => makeFiles(3),
                );
                return result!;
              },
            ),
          ),
        ),
      );
      await tapAndSettle(tester, 'go',
          until: () => shown('Download folder unavailable'));
      expect(find.text('Download folder unavailable'), findsOneWidget);

      // The re-pick must see the new grant as live.
      saf.permissions = [grantFor(newTree)];
      await tapAndSettle(tester, 'Choose folder',
          until: () => result != null);

      expect(saf.pasted.map((p) => p.name), ['doc0.pdf', 'doc1.pdf', 'doc2.pdf']);
      expect(saf.pasted.last.dir, contains('Documents'));
      expect(result?.saved, 3);
      expect(result?.failed, 0);
      expect(find.text('Saved 3 files to Documents'), findsOneWidget);
    });

    testWidgets(
        'a folder deleted while its grant is still listed prompts anyway',
        (tester) async {
      configureReadyFolder();
      // Grant stays in the table (Android does not always revoke it when the
      // tree is deleted); only the write knows the folder is gone.
      saf.pasteErrors = [
        null,
        const SafNotFoundException(pickedTreeUri, 'tree gone'),
      ];
      const newTree = 'content://com.android.externalstorage.documents/tree/'
          'primary%3ADocuments';
      saf.pickResult = pickedDir('$newTree/document/primary%3ADocuments',
          name: 'Documents');
      SaveToFolderResult? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exportDestinationServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            home: _Host(
              onPressed: (context, ref) async {
                result = await saveToFolderWithFallback(
                  context: context,
                  ref: ref,
                  produceFiles: () async => makeFiles(2),
                );
                return result!;
              },
            ),
          ),
        ),
      );
      await tapAndSettle(tester, 'go',
          until: () => shown('Download folder unavailable'));
      expect(find.text('Download folder unavailable'), findsOneWidget);

      saf.permissions = [grantFor(persistedTreeUri), grantFor(newTree)];
      await tapAndSettle(tester, 'Choose folder',
          until: () => result != null);

      expect(saf.pasted.map((p) => p.name), ['doc0.pdf', 'doc1.pdf']);
      expect(saf.pasted.last.dir, contains('Documents'));
      expect(result?.saved, 2);
    });

    testWidgets(
        'a picker failure during the mid-batch re-prompt is reported, not '
        'thrown, and the rest count as failed', (tester) async {
      configureReadyFolder();
      saf.pasteErrors = [
        null,
        const SafPermissionException(pickedTreeUri, 'revoked'),
      ];
      saf.onPaste = (call) {
        if (call == 1) saf.permissions = [];
      };
      saf.pickError = const SafIoException('', 'no DocumentsUI');
      SaveToFolderResult? result;
      Object? thrown;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exportDestinationServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(
            home: _Host(
              onPressed: (context, ref) async {
                try {
                  result = await saveToFolderWithFallback(
                    context: context,
                    ref: ref,
                    produceFiles: () async => makeFiles(3),
                  );
                } on Exception catch (e) {
                  thrown = e;
                }
                return result ?? SaveToFolderResult.cancelled;
              },
            ),
          ),
        ),
      );
      await tapAndSettle(tester, 'go',
          until: () => shown('Download folder unavailable'));
      await tapAndSettle(tester, 'Choose folder',
          until: () => result != null || thrown != null);

      expect(thrown, isNull);
      expect(find.text('Could not open the folder picker.'), findsOneWidget);
      expect(result?.saved, 1);
      expect(result?.failed, 2, reason: 'nothing to retry against');
      expect(saf.pasted.length, 1, reason: 'no writes after the cancel');
    });

    testWidgets('a wholesale failure reports the folder and saves nothing',
        (tester) async {
      configureReadyFolder();
      saf.pasteError = const SafIoException(pickedTreeUri, 'disk full');
      final result = await pumpAndTap(tester, produce: () async => makeFiles(2));

      expect(result?.saved, 0);
      expect(result?.failed, 2);
      expect(result?.didExport, isFalse);
      expect(
        find.text('Could not save to Download: the file could not be written.'),
        findsOneWidget,
      );
    });
  });

  group('saveSummaryMessage', () {
    test('covers every arm', () {
      String? msg(List<String> saved, int failed) => saveSummaryMessage(
            saved: saved,
            failedCount: failed,
            lastError: 'boom',
            folder: 'F',
          );
      expect(msg([], 0), isNull);
      expect(msg([], 2), 'Could not save to F: boom');
      expect(msg(['a.pdf'], 0), 'Saved a.pdf to F');
      expect(msg(['a', 'b'], 0), 'Saved 2 files to F');
      expect(msg(['a', 'b'], 1), 'Saved 2 to F, 1 failed');
    });
  });
}
