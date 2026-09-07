import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_providers.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';
import 'package:paperless_go/core/models/api_response.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/features/documents/documents_notifier.dart';

class _FakeApi extends PaperlessApi {
  _FakeApi() : super(Dio());

  @override
  Future<PaginatedResponse<Document>> getDocuments({
    int page = 1,
    int pageSize = 25,
    String? query,
    String ordering = '-created',
    bool? isInInbox,
    List<int>? tagIds,
    int? correspondentId,
    int? documentTypeId,
    int? moreLikeId,
    bool truncateContent = true,
    DateTime? createdDateFrom,
    DateTime? createdDateTo,
  }) async =>
      const PaginatedResponse(count: 0, next: null, previous: null, results: []);
}

/// Auth that resolves only when the test says so — the keystore read on a
/// cold start, which the first tab's notifier races.
class _GatedAuth extends AuthState {
  static Completer<AuthStatus> gate = Completer<AuthStatus>();

  @override
  Future<AuthStatus> build() => gate.future;
}

void main() {
  test(
      'Library recovers once the session has been restored, instead of '
      'staying on the error it hit while auth was still loading', () async {
    _GatedAuth.gate = Completer<AuthStatus>();
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(_GatedAuth.new),
        // Real gating: the client provider throws until auth resolves.
        paperlessApiProvider.overrideWith((ref) {
          ref.watch(dioProvider);
          return _FakeApi();
        }),
      ],
    );
    addTearDown(container.dispose);

    // Keep the notifier alive the way a mounted screen would.
    final sub = container.listen(documentsNotifierProvider, (_, __) {});
    addTearDown(sub.close);

    await expectLater(
      container.read(documentsNotifierProvider.future),
      throwsA(isA<NotAuthenticatedException>()),
    );

    _GatedAuth.gate.complete(
      const AuthStatus.authenticated(serverUrl: 'https://p.example', token: 't'),
    );
    await container.read(authStateProvider.future);
    await container.pump();

    final state = await container.read(documentsNotifierProvider.future);
    expect(state.documents, isEmpty);
    expect(container.read(documentsNotifierProvider).hasError, isFalse);
  });
}
