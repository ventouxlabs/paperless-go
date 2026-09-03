import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/api/api_providers.dart';
import '../../core/models/document.dart';
import '../../core/models/note.dart';
import '../../core/services/export_destination_service.dart';

part 'document_detail_notifier.g.dart';

@riverpod
class DocumentDetail extends _$DocumentDetail {
  @override
  Future<Document> build(int id) async {
    final api = ref.watch(paperlessApiProvider);
    return api.getDocument(id);
  }

  Future<void> updateField(Map<String, dynamic> data) async {
    final previous = state;
    try {
      final api = ref.read(paperlessApiProvider);
      final updated = await api.updateDocument(id, data);
      state = AsyncData(updated);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> setTags(List<int> tagIds) async {
    await updateField({'tags': tagIds});
  }

  Future<void> addTag(int tagId) async {
    final doc = state.valueOrNull;
    if (doc == null) return;
    if (doc.tags.contains(tagId)) return;
    await setTags([...doc.tags, tagId]);
  }

  Future<void> removeTag(int tagId) async {
    final doc = state.valueOrNull;
    if (doc == null) return;
    await setTags(doc.tags.where((id) => id != tagId).toList());
  }
}

@riverpod
class DocumentNotes extends _$DocumentNotes {
  @override
  Future<List<Note>> build(int documentId) async {
    final api = ref.watch(paperlessApiProvider);
    return api.getNotes(documentId);
  }

  Future<void> addNote(String text) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.addNote(documentId, text);
      ref.invalidateSelf();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> deleteNote(int noteId) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.deleteNote(documentId, noteId);
      ref.invalidateSelf();
    } catch (_) {
      rethrow;
    }
  }
}

@riverpod
Future<String> documentDownload(Ref ref, int documentId, String title) async {
  final api = ref.watch(paperlessApiProvider);
  final dir = await getTemporaryDirectory();
  final safeName = sanitizeExportName(title, fallback: 'document_$documentId');
  final path = '${dir.path}/${documentId}_$safeName.pdf';
  final file = await api.downloadDocument(documentId, path);
  return file.path;
}
