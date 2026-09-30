// #43: a document Paperless never archived (plain text, an image, …) must not
// be fed to the PDF viewer. The preview says what the file is and offers to
// share it instead of failing with "Failed to load PDF".

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_providers.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/features/documents/document_preview_screen.dart';

/// Serves a text original, the way /download/ does for an unarchived document.
class _TextDocumentApi extends PaperlessApi {
  _TextDocumentApi(this.dir) : super(Dio());

  final Directory dir;

  @override
  Future<File> downloadDocumentTyped(
    int id,
    String Function(String extension) pathFor, {
    String? originalFileName,
  }) async =>
      File(pathFor('txt'))..writeAsStringSync('plain text');
}

void main() {
  testWidgets('a text document shows a no-preview panel with Share',
      (tester) async {
    final dir = Directory.systemTemp.createTempSync('preview_test_');
    addTearDown(() => dir.deleteSync(recursive: true));
    // path_provider has no platform implementation under flutter_test.
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'getTemporaryDirectory' ? dir.path : null,
    );
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            paperlessApiProvider.overrideWith((ref) => _TextDocumentApi(dir)),
          ],
          child: const MaterialApp(home: DocumentPreviewScreen(documentId: 20)),
        ),
      );
      for (var i = 0; i < 100 && find.byType(FilledButton).evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
    });

    expect(find.text('No preview for .txt files'), findsOneWidget);
    expect(find.text('Failed to load PDF'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Share'), findsOneWidget);
  });
}
