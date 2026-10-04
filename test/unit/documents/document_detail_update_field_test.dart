// DocumentDetail.updateField keeps userCanChange across a PATCH
// (native AI #44 review).
//
// Paperless-ngx 3.2.1's PATCH reply omits `user_can_change` (verified live),
// so taking the reply as is would hide "Suggest with AI" after the first save.
//
// Run: flutter test test/unit/documents/document_detail_update_field_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_providers.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/features/documents/document_detail_notifier.dart';

Map<String, dynamic> _admin() => jsonDecode(
        File('test/fixtures/api/ai/document_detail_admin.json')
            .readAsStringSync())
    as Map<String, dynamic>;

/// GET returns the real detail body; PATCH returns [patchReply].
class _FakeApi extends PaperlessApi {
  _FakeApi(this.patchReply) : super(Dio());

  final Map<String, dynamic> patchReply;

  @override
  Future<Document> getDocument(int id) async => Document.fromJson(_admin());

  @override
  Future<Document> updateDocument(int id, Map<String, dynamic> data) async =>
      Document.fromJson({...patchReply, ...data});
}

Future<Document> _afterPatch(Map<String, dynamic> patchReply) async {
  final container = ProviderContainer(overrides: [
    paperlessApiProvider.overrideWithValue(_FakeApi(patchReply)),
  ]);
  addTearDown(container.dispose);
  final provider = documentDetailProvider(1);
  container.listen(provider, (_, __) {});
  final before = await container.read(provider.future);
  expect(before.userCanChange, isTrue);

  await container.read(provider.notifier).updateField({'title': 'New'});
  final after = container.read(provider).valueOrNull;
  if (after == null) fail('no document after the PATCH');
  return after;
}

void main() {
  test('a PATCH reply without user_can_change keeps the previous value',
      () async {
    final reply = _admin()..remove('user_can_change');
    final doc = await _afterPatch(reply);
    expect(doc.title, 'New');
    expect(doc.userCanChange, isTrue);
  });

  test('a PATCH reply that carries user_can_change wins', () async {
    final reply = _admin()..['user_can_change'] = false;
    final doc = await _afterPatch(reply);
    expect(doc.userCanChange, isFalse);
  });
}
