import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/api/api_providers.dart';
import '../../core/services/document_lock_service.dart';
import '../../core/design_tokens.dart';
import '../../core/models/document.dart';
import '../../shared/widgets/document_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';

part 'similar_screen.g.dart';

@riverpod
Future<List<Document>> similarDocuments(Ref ref, int documentId) async {
  final api = ref.watch(paperlessApiProvider);
  final response = await api.getDocuments(
    moreLikeId: documentId,
    pageSize: 20,
    truncateContent: true,
  );
  return response.results;
}

class SimilarScreen extends ConsumerWidget {
  final int documentId;
  const SimilarScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similarAsync = ref.watch(similarDocumentsProvider(documentId));
    final tagsAsync = ref.watch(tagsProvider);
    final correspondentsAsync = ref.watch(correspondentsProvider);
    final docTypesAsync = ref.watch(documentTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Similar Documents')),
      body: similarAsync.when(
        loading: () => const DocumentListSkeleton(),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48,
                    color: Theme.of(context).colorScheme.error),
                const SizedBox(height: Spacing.lg),
                Text('Failed to find similar documents',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: Spacing.lg),
                FilledButton.tonal(
                  onPressed: () =>
                      ref.invalidate(similarDocumentsProvider(documentId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (documents) {
          final tags = tagsAsync.valueOrNull ?? {};
          final correspondents = correspondentsAsync.valueOrNull ?? {};
          final docTypes = docTypesAsync.valueOrNull ?? {};

          if (documents.isEmpty) {
            return const EmptyState(
              icon: Icons.find_in_page_outlined,
              title: 'No similar documents found',
              description: 'Nothing in your library resembles this document yet.',
            );
          }

          final api = ref.watch(paperlessApiProvider);
          final lockedAsync = ref.watch(lockedDocumentIdsProvider);
          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return DocumentCard(
                document: doc,
                tags: tags,
                correspondents: correspondents,
                documentTypes: docTypes,
                thumbnailUrl: api.thumbnailUrl(doc.id),
                authToken: api.authToken,
                locked: lockedAsync.isLocked(doc.id),
                onTap: () => context.push('/documents/${doc.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
