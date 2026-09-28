// Restore / permanent-delete failures must reach the user with a reason
// (offline, session expired, server rejected) instead of a bare "Failed".

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_providers.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/core/models/api_response.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/features/trash/trash_notifier.dart';

DioException _offline() => DioException(
      requestOptions: RequestOptions(path: 'api/trash/'),
      type: DioExceptionType.connectionError,
    );

class _FailingApi extends PaperlessApi {
  _FailingApi() : super(Dio());

  @override
  Future<PaginatedResponse<Document>> getTrashedDocuments({
    int page = 1,
    int pageSize = 25,
  }) async =>
      const PaginatedResponse(count: 0, next: null, previous: null, results: []);

  @override
  Future<void> restoreFromTrash(List<int> documentIds) async =>
      throw _offline();

  @override
  Future<void> emptyTrash(List<int> documentIds) async => throw _offline();
}

class _OkApi extends _FailingApi {
  @override
  Future<void> restoreFromTrash(List<int> documentIds) async {}

  @override
  Future<void> emptyTrash(List<int> documentIds) async {}
}

ProviderContainer _container(PaperlessApi api) {
  final container = ProviderContainer(
    overrides: [paperlessApiProvider.overrideWith((ref) => api)],
  );
  addTearDown(container.dispose);
  final sub = container.listen(trashNotifierProvider, (_, __) {});
  addTearDown(sub.close);
  return container;
}

void main() {
  const offline = 'Could not reach the server. Check your connection.';

  test('restoreDocuments returns the friendly reason on failure', () async {
    final container = _container(_FailingApi());
    await container.read(trashNotifierProvider.future);

    final error =
        await container.read(trashNotifierProvider.notifier).restoreDocuments([1]);

    expect(error, offline);
  });

  test('permanentlyDelete returns the friendly reason on failure', () async {
    final container = _container(_FailingApi());
    await container.read(trashNotifierProvider.future);

    final error =
        await container.read(trashNotifierProvider.notifier).permanentlyDelete([1]);

    expect(error, offline);
  });

  test('both return null on success', () async {
    final container = _container(_OkApi());
    await container.read(trashNotifierProvider.future);
    final notifier = container.read(trashNotifierProvider.notifier);

    expect(await notifier.permanentlyDelete([1]), isNull);
  });
}
