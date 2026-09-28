// A restored document must reappear in the Documents and Inbox lists without
// a manual pull-to-refresh — both stay mounted under the pushed /trash route.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_providers.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/core/models/api_response.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/features/documents/documents_notifier.dart';
import 'package:paperless_go/features/inbox/inbox_notifier.dart';
import 'package:paperless_go/features/trash/trash_notifier.dart';

class _FakeApi extends PaperlessApi {
  _FakeApi() : super(Dio());

  @override
  Future<PaginatedResponse<Document>> getTrashedDocuments({
    int page = 1,
    int pageSize = 25,
  }) async =>
      const PaginatedResponse(count: 0, next: null, previous: null, results: []);

  @override
  Future<void> restoreFromTrash(List<int> documentIds) async {}
}

class _CountingDocuments extends DocumentsNotifier {
  static int builds = 0;

  @override
  Future<DocumentsState> build() async {
    builds++;
    return const DocumentsState();
  }
}

class _CountingInbox extends InboxNotifier {
  static int builds = 0;

  @override
  Future<InboxState> build() async {
    builds++;
    return const InboxState();
  }
}

void main() {
  test('restoring documents rebuilds the Documents and Inbox lists', () async {
    _CountingDocuments.builds = 0;
    _CountingInbox.builds = 0;
    final container = ProviderContainer(
      overrides: [
        paperlessApiProvider.overrideWith((ref) => _FakeApi()),
        documentsNotifierProvider.overrideWith(_CountingDocuments.new),
        inboxNotifierProvider.overrideWith(_CountingInbox.new),
      ],
    );
    addTearDown(container.dispose);
    final subs = [
      container.listen(trashNotifierProvider, (_, __) {}),
      container.listen(documentsNotifierProvider, (_, __) {}),
      container.listen(inboxNotifierProvider, (_, __) {}),
    ];
    addTearDown(() {
      for (final sub in subs) {
        sub.close();
      }
    });
    await container.read(trashNotifierProvider.future);
    await container.read(documentsNotifierProvider.future);
    await container.read(inboxNotifierProvider.future);
    expect(_CountingDocuments.builds, 1);
    expect(_CountingInbox.builds, 1);

    final error = await container
        .read(trashNotifierProvider.notifier)
        .restoreDocuments([7]);
    await container.read(documentsNotifierProvider.future);
    await container.read(inboxNotifierProvider.future);

    expect(error, isNull);
    expect(_CountingDocuments.builds, 2);
    expect(_CountingInbox.builds, 2);
  });
}
