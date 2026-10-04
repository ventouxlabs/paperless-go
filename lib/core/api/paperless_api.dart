import 'dart:io';
import 'package:dio/dio.dart';
import 'dio_client.dart';
import 'download_file_type.dart';
import '../models/ai_suggestions.dart';
import '../models/api_response.dart';
import '../models/correspondent.dart';
import '../models/custom_field.dart';
import '../models/document.dart';
import '../models/document_type.dart';
import '../models/note.dart';
import '../models/saved_view.dart';
import '../models/workflow.dart';
import '../models/storage_path.dart';
import '../models/tag.dart';

class PaperlessApi {
  final Dio _dio;

  PaperlessApi(this._dio);

  // Documents

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
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      'ordering': ordering,
      'truncate_content': truncateContent,
    };
    if (query != null && query.isNotEmpty) params['query'] = query;
    if (isInInbox != null) params['is_in_inbox'] = isInInbox;
    if (moreLikeId != null) params['more_like_id'] = moreLikeId;
    if (tagIds != null && tagIds.isNotEmpty) {
      params['tags__id__all'] = tagIds;
    }
    if (correspondentId != null) params['correspondent__id'] = correspondentId;
    if (documentTypeId != null) params['document_type__id'] = documentTypeId;
    if (createdDateFrom != null) {
      params['created__date__gte'] =
          createdDateFrom.toIso8601String().split('T').first;
    }
    if (createdDateTo != null) {
      params['created__date__lte'] =
          createdDateTo.toIso8601String().split('T').first;
    }

    final response = await _dio.get('api/documents/', queryParameters: params);
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Document.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Document> getDocument(int id) async {
    final response = await _dio.get('api/documents/$id/');
    final data = response.data;
    // A captive portal or an access proxy can answer 200 with an HTML page;
    // callers catch DioException, not a cast's TypeError.
    if (data is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'document: expected a JSON object',
      );
    }
    return Document.fromJson(data);
  }

  Future<Document> updateDocument(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch('api/documents/$id/', data: data);
    return Document.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteDocument(int id) async {
    await _dio.delete('api/documents/$id/');
  }

  // Notes

  Future<List<Note>> getNotes(int documentId) async {
    final response = await _dio.get('api/documents/$documentId/notes/');
    final list = response.data as List<dynamic>;
    return list.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Note>> addNote(int documentId, String note) async {
    final response = await _dio.post(
      'api/documents/$documentId/notes/',
      data: {'note': note},
    );
    final list = response.data as List<dynamic>;
    return list.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteNote(int documentId, int noteId) async {
    await _dio.delete('api/documents/$documentId/notes/$noteId/');
  }

  // Download

  /// Download document [id] to the path [pathFor] builds from the file
  /// extension the response calls for.
  ///
  /// The endpoint serves the archived PDF only when there is one; otherwise
  /// it serves the original (text, image, …) as-is, so the extension comes
  /// from the response headers, then [originalFileName] (#43).
  Future<File> downloadDocumentTyped(
    int id,
    String Function(String extension) pathFor, {
    String? originalFileName,
  }) async {
    String? path;
    await _dio.download(
      'api/documents/$id/download/',
      // Must not throw: an exception here escapes before Dio has consumed or
      // cancelled the response stream. `.first` rather than Headers.value(),
      // which throws when a header is repeated.
      (Headers headers) => path = pathFor(
        downloadExtension(
          contentDisposition: headers['content-disposition']?.first,
          contentType: headers[Headers.contentTypeHeader]?.first,
          originalFileName: originalFileName,
        ),
      ),
      options: Options(receiveTimeout: const Duration(minutes: 5)),
    );
    final written = path;
    if (written == null) {
      throw StateError('Download of document $id finished without a path');
    }
    // The type can change (an original archived later), so a copy under the
    // old extension would otherwise linger in the cache.
    await deleteOtherTypeVariants(written);
    return File(written);
  }

  /// Build the preview URL for a document PDF.
  String previewUrl(int documentId) {
    final base = _dio.options.baseUrl;
    return '${base}api/documents/$documentId/preview/';
  }

  Future<void> bulkEdit({
    required List<int> documents,
    required String method,
    Map<String, dynamic>? parameters,
  }) async {
    await _dio.post('api/documents/bulk_edit/', data: {
      'documents': documents,
      'method': method,
      if (parameters != null) 'parameters': parameters,
    });
  }

  // Tags

  Future<PaginatedResponse<Tag>> getTags({int pageSize = 100}) async {
    final response = await _dio.get('api/tags/', queryParameters: {
      'page_size': pageSize,
    });
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Tag.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Tag> createTag(Map<String, dynamic> data) async {
    final response = await _dio.post('api/tags/', data: data);
    return Tag.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Tag> updateTag(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch('api/tags/$id/', data: data);
    return Tag.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTag(int id) async {
    await _dio.delete('api/tags/$id/');
  }

  // Correspondents

  Future<PaginatedResponse<Correspondent>> getCorrespondents({
    int pageSize = 100,
  }) async {
    final response = await _dio.get('api/correspondents/', queryParameters: {
      'page_size': pageSize,
    });
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Correspondent.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Correspondent> createCorrespondent(Map<String, dynamic> data) async {
    final response = await _dio.post('api/correspondents/', data: data);
    return Correspondent.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Correspondent> updateCorrespondent(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch('api/correspondents/$id/', data: data);
    return Correspondent.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCorrespondent(int id) async {
    await _dio.delete('api/correspondents/$id/');
  }

  // Document Types

  Future<PaginatedResponse<DocumentType>> getDocumentTypes({
    int pageSize = 100,
  }) async {
    final response = await _dio.get('api/document_types/', queryParameters: {
      'page_size': pageSize,
    });
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => DocumentType.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<DocumentType> createDocumentType(Map<String, dynamic> data) async {
    final response = await _dio.post('api/document_types/', data: data);
    return DocumentType.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DocumentType> updateDocumentType(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch('api/document_types/$id/', data: data);
    return DocumentType.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteDocumentType(int id) async {
    await _dio.delete('api/document_types/$id/');
  }

  // Storage Paths

  Future<PaginatedResponse<StoragePath>> getStoragePaths({
    int pageSize = 100,
  }) async {
    final response = await _dio.get('api/storage_paths/', queryParameters: {
      'page_size': pageSize,
    });
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => StoragePath.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<StoragePath> createStoragePath(Map<String, dynamic> data) async {
    final response = await _dio.post('api/storage_paths/', data: data);
    return StoragePath.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StoragePath> updateStoragePath(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch('api/storage_paths/$id/', data: data);
    return StoragePath.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteStoragePath(int id) async {
    await _dio.delete('api/storage_paths/$id/');
  }

  // Saved Views

  Future<PaginatedResponse<SavedView>> getSavedViews({int pageSize = 100}) async {
    final response = await _dio.get('api/saved_views/', queryParameters: {
      'page_size': pageSize,
    });
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => SavedView.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<SavedView> createSavedView({
    required String name,
    required List<FilterRule> filterRules,
    required String sortField,
    required bool sortReverse,
    bool showOnDashboard = false,
    bool showInSidebar = false,
  }) async {
    final response = await _dio.post('api/saved_views/', data: {
      'name': name,
      'filter_rules': filterRules.map((r) => r.toJson()).toList(),
      'sort_field': sortField,
      'sort_reverse': sortReverse,
      'show_on_dashboard': showOnDashboard,
      'show_in_sidebar': showInSidebar,
    });
    return SavedView.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSavedView(int id) async {
    await _dio.delete('api/saved_views/$id/');
  }

  Future<SavedView> updateSavedView(
    int id, {
    String? name,
    bool? showOnDashboard,
    bool? showInSidebar,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (showOnDashboard != null) data['show_on_dashboard'] = showOnDashboard;
    if (showInSidebar != null) data['show_in_sidebar'] = showInSidebar;
    if (data.isEmpty) throw ArgumentError('At least one field must be provided to updateSavedView');
    final response = await _dio.patch('api/saved_views/$id/', data: data);
    return SavedView.fromJson(response.data as Map<String, dynamic>);
  }

  // UI settings

  /// The raw `GET api/ui_settings/` payload: `user`, `settings` (including
  /// `ai_enabled` and `version` on 3.x) and the user's `permissions`.
  Future<Map<String, dynamic>> getUiSettings() async {
    final response = await _dio.get('api/ui_settings/');
    final data = response.data;
    // A captive portal or an access proxy can answer 200 with an HTML page.
    if (data is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'ui_settings: expected a JSON object',
      );
    }
    return data;
  }

  /// Native AI suggestions (Paperless-ngx 3.x) for one document.
  ///
  /// Every call is a model call the user pays for and the server sends no
  /// bytes until the model has finished (up to ~120 s per call), so: a
  /// 150 s receive timeout, never retried ([kNoRetryExtraKey]), and
  /// cancellable. Only call it on an explicit user action.
  Future<AiSuggestions> getAiSuggestions(
    int documentId, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      'api/documents/$documentId/ai_suggestions/',
      cancelToken: cancelToken,
      options: Options(
        receiveTimeout: aiSuggestionsReceiveTimeout,
        extra: const {kNoRetryExtraKey: true},
      ),
    );
    final data = response.data;
    // A captive portal or an access proxy can answer 200 with an HTML page.
    if (data is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'ai_suggestions: expected a JSON object',
      );
    }
    return AiSuggestions.fromJson(data);
  }

  static const aiSuggestionsReceiveTimeout = Duration(seconds: 150);

  // Statistics

  Future<Map<String, dynamic>> getStatistics() async {
    final response = await _dio.get('api/statistics/');
    return response.data as Map<String, dynamic>;
  }

  /// Build the thumbnail URL for a document.
  String thumbnailUrl(int documentId) {
    final base = _dio.options.baseUrl;
    return '${base}api/documents/$documentId/thumb/';
  }

  // Upload

  /// Upload a document via multipart POST.
  /// Returns the task UUID for polling consumption status.
  Future<String> uploadDocument({
    required String filePath,
    required String filename,
    String? title,
    int? correspondent,
    int? documentType,
    List<int>? tags,
    DateTime? created,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final formMap = <String, dynamic>{
      'document': await MultipartFile.fromFile(filePath, filename: filename),
      if (title != null && title.isNotEmpty) 'title': title,
      if (correspondent != null) 'correspondent': correspondent,
      if (documentType != null) 'document_type': documentType,
      if (created != null) 'created': created.toIso8601String().split('T').first,
    };
    final formData = FormData.fromMap(formMap);
    // Add tags as separate entries so Dio sends repeated 'tags' fields
    if (tags != null) {
      for (final tag in tags) {
        formData.fields.add(MapEntry('tags', tag.toString()));
      }
    }

    final response = await _dio.post(
      'api/documents/post_document/',
      data: formData,
      onSendProgress: onSendProgress,
      options: Options(
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );

    // Response is a task UUID string (e.g., "abc-123-...")
    final taskId = response.data.toString().replaceAll('"', '').trim();
    return taskId;
  }

  // Task polling

  /// Poll a consumption task's status.
  /// Returns a map with 'status' key: 'PENDING', 'STARTED', 'SUCCESS', 'FAILURE'.
  Future<Map<String, dynamic>> getTaskStatus(String taskId) async {
    final response = await _dio.get(
      'api/tasks/',
      queryParameters: {'task_id': taskId},
    );
    final tasks = response.data as List<dynamic>;
    if (tasks.isEmpty) {
      return {'status': 'PENDING'};
    }
    return tasks.first as Map<String, dynamic>;
  }

  // Custom Fields

  Future<PaginatedResponse<CustomField>> getCustomFields({
    int pageSize = 100,
  }) async {
    final response = await _dio.get('api/custom_fields/', queryParameters: {
      'page_size': pageSize,
    });
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => CustomField.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<CustomField> createCustomField({
    required String name,
    required String dataType,
    Map<String, dynamic>? extraData,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'data_type': dataType,
    };
    if (extraData != null) data['extra_data'] = extraData;
    final response = await _dio.post('api/custom_fields/', data: data);
    return CustomField.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CustomField> updateCustomField(int id, {String? name}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (data.isEmpty) {
      throw ArgumentError('At least one field must be provided to updateCustomField');
    }
    final response = await _dio.patch('api/custom_fields/$id/', data: data);
    return CustomField.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCustomField(int id) async {
    await _dio.delete('api/custom_fields/$id/');
  }

  // Trash

  /// Get trashed documents via the real trash endpoint (since ngx 2.10).
  ///
  /// There is no `is_in_trash` filter on `/api/documents/` — DRF ignores
  /// unknown filters, so that endpoint always returns live documents.
  /// `/api/trash/` has no ordering backend, so `ordering` /
  /// `truncate_content` are not supported here.
  Future<PaginatedResponse<Document>> getTrashedDocuments({
    int page = 1,
    int pageSize = 25,
  }) async {
    final response = await _dio.get('api/trash/', queryParameters: {
      'page': page,
      'page_size': pageSize,
    });
    return PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Document.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Restore documents from trash via the real trash endpoint.
  Future<void> restoreFromTrash(List<int> documentIds) async {
    await _dio.post('api/trash/', data: {
      'documents': documentIds,
      'action': 'restore',
    });
  }

  /// Permanently delete documents from trash via the real trash endpoint.
  ///
  /// This is not reversible.
  Future<void> emptyTrash(List<int> documentIds) async {
    await _dio.post('api/trash/', data: {
      'documents': documentIds,
      'action': 'empty',
    });
  }

  /// Move documents to trash (soft delete).
  ///
  /// Uses the legacy bulk_edit `delete` method, not `trash` — Paperless-ngx
  /// never accepted 'trash' as a bulk_edit method. `delete` is a legacy
  /// method (accepted at the API version this app sends, version 9) that
  /// upstream soft-deletes into the trash; it will be dropped once API v9
  /// is retired, and its replacement `/api/documents/delete/` only exists
  /// on Paperless-ngx 3.x. `delete` is the one call that works across both
  /// 2.x and 3.x.
  Future<void> trashDocuments(List<int> documentIds) async {
    await bulkEdit(
      documents: documentIds,
      method: 'delete',
    );
  }

  /// Re-run OCR on documents.
  ///
  /// Uses bulk_edit `reprocess` — 'redo_ocr' is not an accepted choice on
  /// Paperless-ngx 2.20 or 3.x. Like `delete`, `reprocess` is a legacy
  /// method upstream will drop with API v9 (replacement
  /// `/api/documents/reprocess/` is 3.x-only).
  Future<void> reprocessDocuments(List<int> documentIds) async {
    await bulkEdit(
      documents: documentIds,
      method: 'reprocess',
    );
  }

  // Share Links

  /// Get share links for a document.
  Future<List<Map<String, dynamic>>> getShareLinks(int documentId) async {
    final response = await _dio.get('api/share_links/', queryParameters: {
      'document': documentId,
    });
    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      return (data['results'] as List<dynamic>).cast<Map<String, dynamic>>();
    }
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Create a share link for a document.
  Future<Map<String, dynamic>> createShareLink({
    required int documentId,
    DateTime? expiration,
  }) async {
    final response = await _dio.post('api/share_links/', data: {
      'document': documentId,
      if (expiration != null) 'expiration': expiration.toIso8601String(),
    });
    return response.data as Map<String, dynamic>;
  }

  /// Delete a share link.
  Future<void> deleteShareLink(int linkId) async {
    await _dio.delete('api/share_links/$linkId/');
  }

  // Search Autocomplete

  Future<List<String>> searchAutocomplete(String term, {int limit = 10}) async {
    final response = await _dio.get('api/search/auto_complete/', queryParameters: {
      'term': term,
      'limit': limit,
    });
    final data = response.data;
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Auth token for image requests.
  String get authToken => _dio.options.headers['Authorization'] as String? ?? '';

  /// Base URL for building full share link URLs.
  String get baseUrl => _dio.options.baseUrl;

  // Workflows

  Future<List<Workflow>> getWorkflows() async {
    final response = await _dio.get('api/workflows/', queryParameters: {
      'page_size': 10000,
    });
    final data = response.data;
    final List results =
        data is Map ? (data['results'] as List? ?? []) : (data as List);
    return results
        .map((e) => Workflow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Workflow> toggleWorkflow(int id, {required bool enabled}) async {
    final response = await _dio.patch('api/workflows/$id/', data: {
      'enabled': enabled,
    });
    return Workflow.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteWorkflow(int id) async {
    await _dio.delete('api/workflows/$id/');
  }
}
