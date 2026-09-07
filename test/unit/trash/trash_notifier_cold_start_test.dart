import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_providers.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';
import 'package:paperless_go/core/models/api_response.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/features/trash/trash_notifier.dart';

class _FakeApi extends PaperlessApi {
  _FakeApi() : super(Dio());

  @override
  Future<PaginatedResponse<Document>> getTrashedDocuments({
    int page = 1,
    int pageSize = 25,
  }) async =>
      const PaginatedResponse(count: 0, next: null, previous: null, results: []);
}

class _GatedAuth extends AuthState {
  static Completer<AuthStatus> gate = Completer<AuthStatus>();

  @override
  Future<AuthStatus> build() => gate.future;
}

void main() {
  test('Trash recovers once the session has been restored', () async {
    _GatedAuth.gate = Completer<AuthStatus>();
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(_GatedAuth.new),
        paperlessApiProvider.overrideWith((ref) {
          ref.watch(dioProvider);
          return _FakeApi();
        }),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(trashNotifierProvider, (_, __) {});
    addTearDown(sub.close);

    await expectLater(
      container.read(trashNotifierProvider.future),
      throwsA(isA<NotAuthenticatedException>()),
    );

    _GatedAuth.gate.complete(
      const AuthStatus.authenticated(serverUrl: 'https://p.example', token: 't'),
    );
    await container.read(authStateProvider.future);
    await container.pump();

    final state = await container.read(trashNotifierProvider.future);
    expect(state.documents, isEmpty);
  });
}
