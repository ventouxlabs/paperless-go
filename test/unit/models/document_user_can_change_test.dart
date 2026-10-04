// Document.userCanChange (native AI #44, Phase 1).
//
// `user_can_change` is the per-document permission the "Suggest with AI"
// action gates on. The fixtures are real Paperless-ngx 3.2.1 detail
// responses (see test/fixtures/api/ai/README.md).
//
// Run: flutter test test/unit/models/document_user_can_change_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/models/document.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/fixtures/api/ai/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('admin detail response: user_can_change true', () {
    final doc = Document.fromJson(_fixture('document_detail_admin.json'));
    expect(doc.userCanChange, isTrue);
  });

  test('view-only user: user_can_change false', () {
    final doc = Document.fromJson(_fixture('document_detail_viewer.json'));
    expect(doc.userCanChange, isFalse);
  });

  test('global change_document but object-level view only: false', () {
    final doc = Document.fromJson(
        _fixture('document_detail_editor_object_view_only.json'));
    expect(doc.userCanChange, isFalse);
  });

  test('absent (full_perms=true responses, 2.x servers): null, not false', () {
    final json = _fixture('document_detail_admin.json')
      ..remove('user_can_change');
    final doc = Document.fromJson(json);
    expect(doc.userCanChange, isNull);
  });
}
