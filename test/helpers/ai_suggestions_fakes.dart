// Shared fixtures and fakes for the "Suggest with AI" widget tests
// (native AI #44, Phase 1).
//
// Documents and suggestion bodies are REAL Paperless-ngx 3.2.1 responses
// (test/fixtures/api/ai/README.md); object IDs on that server: tags
// Invoice=1, Utilities=2, Insurance=3, Tax=4; correspondents Acme Energy=1,
// Northwind Insurance=2; types Bill=1, Letter=2.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_go/core/api/api_providers.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/core/api/server_capabilities.dart';
import 'package:paperless_go/core/models/ai_suggestions.dart';
import 'package:paperless_go/core/models/correspondent.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/core/models/document_type.dart';
import 'package:paperless_go/core/models/storage_path.dart';
import 'package:paperless_go/core/models/tag.dart';

Map<String, dynamic> aiFixture(String name) =>
    jsonDecode(File('test/fixtures/api/ai/$name').readAsStringSync())
        as Map<String, dynamic>;

final adminDoc = Document.fromJson(aiFixture('document_detail_admin.json'));
final viewerDoc = Document.fromJson(aiFixture('document_detail_viewer.json'));
final billSuggestions = AiSuggestions.fromJson(
  aiFixture('ai_suggestions_bill.json'),
);

final fixtureTags = {
  for (final (id, name) in [
    (1, 'Invoice'),
    (2, 'Utilities'),
    (3, 'Insurance'),
    (4, 'Tax'),
  ])
    id: Tag(id: id, name: name, slug: name.toLowerCase()),
};
const fixtureCorrespondents = {
  1: Correspondent(id: 1, name: 'Acme Energy', slug: 'acme-energy'),
  2: Correspondent(
    id: 2,
    name: 'Northwind Insurance',
    slug: 'northwind-insurance',
  ),
};
const fixtureTypes = {
  1: DocumentType(id: 1, name: 'Bill', slug: 'bill'),
  2: DocumentType(id: 2, name: 'Letter', slug: 'letter'),
};

ServerCapabilities capsWith({
  required bool ai,
  Set<String> permissions = const {'view_document', 'change_document'},
}) => ServerCapabilities(
  aiEnabled: ai,
  permissions: permissions,
  version: '3.2.1',
);

/// getAiSuggestions answers only when the test says so. A cancel fails the
/// call the way Dio does, unless [ignoreCancel] simulates a reply that was
/// already on its way.
class FakeAiApi extends PaperlessApi {
  FakeAiApi() : super(Dio());

  final tokens = <CancelToken?>[];
  final _replies = <Completer<AiSuggestions>>[];
  bool ignoreCancel = false;

  /// What re-reading the document after the AI answers returns.
  Document nextDocument = adminDoc;

  // A cancel may already have failed the reply (see getAiSuggestions).
  void succeed(AiSuggestions s) {
    if (!_replies.last.isCompleted) _replies.last.complete(s);
  }

  void fail(DioException e) {
    if (!_replies.last.isCompleted) _replies.last.completeError(e);
  }

  @override
  Future<Document> getDocument(int id) async => nextDocument;

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

List<Override> aiLibraryOverrides(PaperlessApi api) => [
  paperlessApiProvider.overrideWithValue(api),
  tagsProvider.overrideWith((ref) async => fixtureTags),
  correspondentsProvider.overrideWith((ref) async => fixtureCorrespondents),
  documentTypesProvider.overrideWith((ref) async => fixtureTypes),
  storagePathsProvider.overrideWith((ref) async => const <int, StoragePath>{}),
];
