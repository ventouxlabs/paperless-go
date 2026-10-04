// State for "Suggest with AI" (native AI #44, Phase 1): explicit request only,
// cancellable, cancelled when nobody listens any more; the app's lists load
// before (and apart from) the model call; unknown IDs re-load their list
// once; the prefill is built on a fresh copy of the document.
//
// Run: flutter test test/unit/documents/ai_suggestions_notifier_test.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_providers.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/core/models/ai_suggestions.dart';
import 'package:paperless_go/core/models/correspondent.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/core/models/document_type.dart';
import 'package:paperless_go/core/models/storage_path.dart';
import 'package:paperless_go/core/models/tag.dart';
import 'package:paperless_go/features/documents/ai_suggestions/ai_suggestions_error.dart';
import 'package:paperless_go/features/documents/ai_suggestions/ai_suggestions_notifier.dart';
import 'package:paperless_go/features/documents/document_detail_notifier.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('test/fixtures/api/ai/$name').readAsStringSync())
        as Map<String, dynamic>;

/// Answers each getAiSuggestions call only when the test says so; a cancel on
/// the CancelToken fails the call the way Dio does.
class _FakeApi extends PaperlessApi {
  _FakeApi() : super(Dio());

  final tokens = <CancelToken?>[];
  final _replies = <Completer<AiSuggestions>>[];

  /// Simulates a reply that was already on its way when the user cancelled.
  bool ignoreCancel = false;

  /// What re-fetching the document returns; null makes the re-fetch fail.
  Document? nextDocument;
  int documentFetches = 0;

  @override
  Future<Document> getDocument(int id) async {
    documentFetches++;
    final next = nextDocument;
    if (next == null) {
      throw DioException(
        requestOptions: RequestOptions(path: 'api/documents/$id/'),
        type: DioExceptionType.connectionError,
      );
    }
    return next;
  }

  int get calls => tokens.length;
  CancelToken? get lastToken => tokens.lastOrNull;

  void succeed(AiSuggestions s, {int call = -1}) =>
      _reply(call).complete(s);
  void fail(DioException e, {int call = -1}) => _reply(call).completeError(e);
  Completer<AiSuggestions> _reply(int call) =>
      call < 0 ? _replies.last : _replies[call];

  @override
  Future<AiSuggestions> getAiSuggestions(
    int documentId, {
    CancelToken? cancelToken,
  }) {
    final reply = Completer<AiSuggestions>();
    _replies.add(reply);
    tokens.add(cancelToken);
    cancelToken?.whenCancel.then((e) {
      if (!ignoreCancel && !reply.isCompleted) reply.completeError(e);
    });
    return reply.future;
  }
}

const _utilities = Tag(id: 2, name: 'Utilities', slug: 'utilities');

DioException _forbidden(String path) {
  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: 403),
  );
}

DioException _status(int status, Object body, String contentType) {
  final options = RequestOptions(path: 'api/documents/1/ai_suggestions/');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: body,
      headers: Headers.fromMap({
        Headers.contentTypeHeader: [contentType],
      }),
    ),
  );
}

void main() {
  late _FakeApi api;
  late ProviderContainer container;
  late List<AiSuggestionsState> states;
  late ProviderSubscription<AiSuggestionsState> subscription;
  late Future<Map<int, Tag>> Function() loadTags;
  late Future<Map<int, StoragePath>> Function() loadStoragePaths;
  final doc = Document.fromJson(_json('document_detail_admin.json'));
  final provider = aiSuggestionsControllerProvider(doc.id);

  setUp(() {
    api = _FakeApi()..nextDocument = doc;
    loadTags = () async => {2: _utilities};
    loadStoragePaths = () async => const <int, StoragePath>{};
    container = ProviderContainer(overrides: [
      paperlessApiProvider.overrideWithValue(api),
      tagsProvider.overrideWith((ref) => loadTags()),
      correspondentsProvider.overrideWith((ref) async => {
            1: const Correspondent(
                id: 1, name: 'Acme Energy', slug: 'acme-energy'),
          }),
      documentTypesProvider.overrideWith((ref) async => {
            1: const DocumentType(id: 1, name: 'Bill', slug: 'bill'),
          }),
      storagePathsProvider.overrideWith((ref) => loadStoragePaths()),
    ]);
    addTearDown(container.dispose);
    states = [];
    subscription = container.listen<AiSuggestionsState>(
      provider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
  });

  test('starts idle and never fetches on its own', () async {
    await Future<void>.delayed(Duration.zero);
    expect(container.read(provider), isA<AiSuggestionsIdle>());
    expect(api.calls, 0);
  });

  test('request: loading, then success with the pre-fill', () async {
    final pending = container.read(provider.notifier).request(doc);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(provider), isA<AiSuggestionsLoading>());

    api.succeed(AiSuggestions.fromJson(_json('ai_suggestions_bill.json')));
    await pending;

    final state = container.read(provider);
    expect(state, isA<AiSuggestionsSuccess>());
    final prefill = (state as AiSuggestionsSuccess).prefill;
    expect(state.document, doc);
    expect(prefill.correspondentId, 1);
    expect(prefill.documentTypeId, 1);
    expect(prefill.tagIds, [2]);
    expect(prefill.suggestedTitle, 'Electricity Bill - March 2026');
    expect(api.calls, 1);
    expect(api.lastToken, isNotNull);
    expect(states.map((s) => s.runtimeType), [
      AiSuggestionsIdle,
      AiSuggestionsLoading,
      AiSuggestionsSuccess,
    ]);
  });

  test('a second request while loading is ignored (one model call)',
      () async {
    final notifier = container.read(provider.notifier);
    final first = notifier.request(doc);
    await Future<void>.delayed(Duration.zero);
    await notifier.request(doc);
    api.succeed(const AiSuggestions());
    await first;
    expect(api.calls, 1);
  });

  test('a server error becomes a failure with the mapped message', () async {
    final pending = container.read(provider.notifier).request(doc);
    await Future<void>.delayed(Duration.zero);
    api.fail(_status(
        403, 'Insufficient permissions', 'text/html; charset=utf-8'));
    await pending;

    final state = container.read(provider);
    expect(state, isA<AiSuggestionsFailure>());
    expect((state as AiSuggestionsFailure).kind,
        AiSuggestionsErrorKind.cannotEdit);
  });

  test('cancel: back to idle, the request is cancelled, and its late '
      'failure writes nothing', () async {
    final notifier = container.read(provider.notifier);
    final pending = notifier.request(doc);
    await Future<void>.delayed(Duration.zero);

    notifier.cancel();
    await pending;

    expect(api.lastToken?.isCancelled, isTrue);
    expect(container.read(provider), isA<AiSuggestionsIdle>());
    expect(states.map((s) => s.runtimeType), [
      AiSuggestionsIdle,
      AiSuggestionsLoading,
      AiSuggestionsIdle,
    ]);
  });

  test('disposing (no listener left) cancels the in-flight request',
      () async {
    final pending = container.read(provider.notifier).request(doc);
    await Future<void>.delayed(Duration.zero);
    expect(api.lastToken?.isCancelled, isFalse);

    subscription.close(); // e.g. the progress dialog was closed
    await Future<void>.delayed(Duration.zero);
    await pending; // completes quietly: no state write on a dead notifier

    expect(api.lastToken?.isCancelled, isTrue);
  });

  test('can ask again after a cancel, with a fresh CancelToken', () async {
    final notifier = container.read(provider.notifier);
    final first = notifier.request(doc);
    await Future<void>.delayed(Duration.zero);
    notifier.cancel();
    await first;

    final retry = notifier.request(doc);
    await Future<void>.delayed(Duration.zero);
    api.succeed(const AiSuggestions());
    await retry;

    expect(api.calls, 2);
    expect(api.tokens.first?.isCancelled, isTrue);
    expect(api.tokens.last, isNot(same(api.tokens.first)));
    expect(api.tokens.last?.isCancelled, isFalse);
    expect(container.read(provider), isA<AiSuggestionsSuccess>());
  });

  test('a late reply to a cancelled request never overwrites a newer one',
      () async {
    api.ignoreCancel = true;
    final notifier = container.read(provider.notifier);
    final first = notifier.request(doc);
    await Future<void>.delayed(Duration.zero);
    notifier.cancel();
    final second = notifier.request(doc);
    await Future<void>.delayed(Duration.zero);

    // The first call answers after all: an error, then (for the success path)
    // a second stale request is answered with suggestions.
    api.fail(_status(500, '<h1>Server Error</h1>', 'text/html'), call: 0);
    await first;
    expect(container.read(provider), isA<AiSuggestionsLoading>());

    api.succeed(const AiSuggestions(title: 'Fresh'), call: 1);
    await second;
    expect(container.read(provider), isA<AiSuggestionsSuccess>());
  });

  test('a late success for a cancelled request writes nothing', () async {
    api.ignoreCancel = true;
    final notifier = container.read(provider.notifier);
    final first = notifier.request(doc);
    await Future<void>.delayed(Duration.zero);
    notifier.cancel();

    api.succeed(const AiSuggestions(title: 'Stale'), call: 0);
    await first;
    expect(container.read(provider), isA<AiSuggestionsIdle>());
    // ...and makes no further request (no document re-read).
    expect(api.documentFetches, 0);
  });

  group('the app\'s own lists', () {
    test('storage paths failing (e.g. 403) still yields suggestions', () async {
      loadStoragePaths = () async => throw _forbidden('api/storage_paths/');
      final pending = container.read(provider.notifier).request(doc);
      await Future<void>.delayed(Duration.zero);
      api.succeed(AiSuggestions.fromJson(_json('ai_suggestions_bill.json')));
      await pending;

      final state = container.read(provider);
      expect(state, isA<AiSuggestionsSuccess>());
      final prefill = (state as AiSuggestionsSuccess).prefill;
      expect(prefill.tagIds, [2]);
      expect(prefill.storagePathNames, isEmpty);
    });

    test('tags failing: a non-AI error, and no model call is made', () async {
      loadTags = () async => throw DioException(
            requestOptions: RequestOptions(path: 'api/tags/'),
            type: DioExceptionType.connectionError,
          );
      await container.read(provider.notifier).request(doc);

      final state = container.read(provider);
      expect(state, isA<AiSuggestionsFailure>());
      expect((state as AiSuggestionsFailure).kind,
          AiSuggestionsErrorKind.libraryUnavailable);
      expect(api.calls, 0);
    });

    test('tags 403: a permission message, not a connection one', () async {
      loadTags = () async => throw _forbidden('api/tags/');
      await container.read(provider.notifier).request(doc);

      expect((container.read(provider) as AiSuggestionsFailure).kind,
          AiSuggestionsErrorKind.libraryForbidden);
      expect(api.calls, 0);
    });

    test('"try again" can succeed: the failed list is re-fetched on the '
        'next tap', () async {
      var builds = 0;
      loadTags = () async {
        if (++builds == 1) {
          throw DioException(
            requestOptions: RequestOptions(path: 'api/tags/'),
            type: DioExceptionType.connectionError,
          );
        }
        return {2: _utilities};
      };
      final notifier = container.read(provider.notifier);
      await notifier.request(doc);
      expect(container.read(provider), isA<AiSuggestionsFailure>());

      final retry = notifier.request(doc);
      await Future<void>.delayed(Duration.zero);
      api.succeed(AiSuggestions.fromJson(_json('ai_suggestions_bill.json')));
      await retry;

      expect(builds, 2);
      expect(container.read(provider), isA<AiSuggestionsSuccess>());
    });
  });

  group('suggested IDs the app doesn\'t know', () {
    test('re-load that list once; a now-known ID is pre-filled', () async {
      var builds = 0;
      loadTags = () async =>
          ++builds == 1 ? const <int, Tag>{} : {2: _utilities};
      final pending = container.read(provider.notifier).request(doc);
      await Future<void>.delayed(Duration.zero);
      api.succeed(AiSuggestions.fromJson(_json('ai_suggestions_bill.json')));
      await pending;

      final prefill =
          (container.read(provider) as AiSuggestionsSuccess).prefill;
      expect(builds, 2);
      expect(prefill.tagIds, [2]);
      expect(prefill.unknownTagIds, isEmpty);
    });

    test('still unknown after one re-load: reported, never re-loaded again',
        () async {
      var builds = 0;
      loadTags = () async {
        builds++;
        return const <int, Tag>{};
      };
      final pending = container.read(provider.notifier).request(doc);
      await Future<void>.delayed(Duration.zero);
      api.succeed(AiSuggestions.fromJson(_json('ai_suggestions_bill.json')));
      await pending;

      final prefill =
          (container.read(provider) as AiSuggestionsSuccess).prefill;
      expect(builds, 2);
      expect(prefill.tagIds, isEmpty);
      expect(prefill.unknownTagIds, [2]);
    });

    test('all IDs known: no re-load', () async {
      var builds = 0;
      loadTags = () async {
        builds++;
        return {2: _utilities};
      };
      final pending = container.read(provider.notifier).request(doc);
      await Future<void>.delayed(Duration.zero);
      api.succeed(AiSuggestions.fromJson(_json('ai_suggestions_bill.json')));
      await pending;

      expect(builds, 1);
    });
  });

  group('the document is re-read after the AI answers', () {
    test('an edit made meanwhile wins: no pre-fill over it, and the sheet\'s '
        'base is the fresh copy', () async {
      final pending = container.read(provider.notifier).request(doc);
      await Future<void>.delayed(Duration.zero);
      // Someone sets the correspondent while the model is thinking.
      final edited = doc.copyWith(correspondent: 2, tags: [3]);
      api.nextDocument = edited;
      api.succeed(AiSuggestions.fromJson(_json('ai_suggestions_bill.json')));
      await pending;

      final state = container.read(provider) as AiSuggestionsSuccess;
      expect(api.documentFetches, 1);
      expect(state.document, edited);
      expect(state.prefill.correspondentId, 2);
      expect(state.prefill.suggestedCorrespondent, isFalse);
      expect(state.prefill.correspondentDisagreement, 'Acme Energy');
      expect(state.prefill.tagIds, [3, 2]);
    });

    test('if the re-read fails, the AI answer is kept (snapshot as base)',
        () async {
      api.nextDocument = null;
      final pending = container.read(provider.notifier).request(doc);
      await Future<void>.delayed(Duration.zero);
      api.succeed(AiSuggestions.fromJson(_json('ai_suggestions_bill.json')));
      await pending;

      final state = container.read(provider) as AiSuggestionsSuccess;
      expect(state.document, doc);
      expect(state.prefill.correspondentId, 1);
    });
  });

  group('the detail screen is never older than the sheet', () {
    late ProviderSubscription<AsyncValue<Document>> detail;

    setUp(() async {
      // The open detail screen watches its document.
      detail = container.listen(documentDetailProvider(doc.id), (_, __) {});
      await container.read(documentDetailProvider(doc.id).future);
      api.documentFetches = 0;
    });

    tearDown(() => detail.close());

    test('a re-read that differs refreshes the screen\'s copy', () async {
      final pending = container.read(provider.notifier).request(doc);
      await Future<void>.delayed(Duration.zero);
      final edited = doc.copyWith(correspondent: 2);
      api.nextDocument = edited;
      api.succeed(AiSuggestions.fromJson(_json('ai_suggestions_bill.json')));
      await pending;
      await container.read(documentDetailProvider(doc.id).future);

      expect(container.read(documentDetailProvider(doc.id)).valueOrNull,
          edited);
      expect(api.documentFetches, 2); // the re-read + the screen's refresh
    });

    test('an unchanged re-read leaves the screen alone (no extra fetch)',
        () async {
      final pending = container.read(provider.notifier).request(doc);
      await Future<void>.delayed(Duration.zero);
      api.succeed(AiSuggestions.fromJson(_json('ai_suggestions_bill.json')));
      await pending;
      await Future<void>.delayed(Duration.zero);

      expect(api.documentFetches, 1); // the re-read only
      expect(container.read(documentDetailProvider(doc.id)).isRefreshing,
          isFalse);
    });
  });
}
