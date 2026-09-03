import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/api/api_providers.dart';
import '../../core/models/correspondent.dart';
import '../../core/models/document.dart';
import '../../core/models/document_type.dart';
import '../../core/models/saved_view.dart';
import '../../core/models/tag.dart';
import '../../shared/widgets/document_card.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/paginated_list_view.dart';
import '../../shared/widgets/stamp_chip.dart';
import '../../shared/save_to_folder_action.dart';
import '../../core/services/export_destination_service.dart';
import '../../core/design_tokens.dart';
import '../../core/api/api_error_mapper.dart';
import 'active_filters_bar.dart';
import 'bulk_action_bar.dart';
import 'document_detail_notifier.dart';
import 'documents_notifier.dart';
import 'filter_bottom_sheet.dart';
import 'saved_view_dialogs.dart';
import 'saved_view_helpers.dart';

/// The Library — the app's main document browser.
///
/// Follows the redesign header language (big Space Grotesk title + count
/// subtitle + a single icon action). Search lives in a full-width omnibox that
/// opens the search screen; filters and sort live behind a single Filter pill
/// (the sort options are a section inside the filter sheet). Saved views are a
/// horizontal carousel of stamp chips at the top of the list, and active
/// filters render as dismissible stamp pills below the omnibox.
class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  String _ordering = '-created';
  final _selectedIds = <int>{};
  bool get _isSelecting => _selectedIds.isNotEmpty;
  int? _activeSavedViewId;

  void _toggleSelection(int docId) {
    setState(() {
      if (_selectedIds.contains(docId)) {
        _selectedIds.remove(docId);
      } else {
        _selectedIds.add(docId);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _shareDocument(BuildContext context, WidgetRef ref, int docId, String title) async {
    try {
      final path = await ref.read(documentDownloadProvider(docId, title).future);
      await Share.shareXFiles([XFile(path)]);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: ${friendlyApiMessage(e)}')),
        );
      }
    }
  }

  Future<void> _saveDocument(
      BuildContext context, WidgetRef ref, int docId, String title) async {
    try {
      final path = await ref.read(documentDownloadProvider(docId, title).future);
      if (!context.mounted) return;
      await saveToFolderWithFallback(
        context: context,
        ref: ref,
        localPaths: [path],
        fileNames: [
          '${sanitizeExportName(title, fallback: 'document_$docId')}.pdf',
        ],
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${friendlyApiMessage(e)}')),
        );
      }
    }
  }

  Future<void> _showDocumentContextMenu(
    BuildContext context,
    WidgetRef ref,
    Document doc,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () => Navigator.pop(context, 'share'),
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Save to folder'),
              onTap: () => Navigator.pop(context, 'save'),
            ),
            ListTile(
              leading: const Icon(Icons.check_box_outline_blank),
              title: const Text('Select'),
              onTap: () => Navigator.pop(context, 'select'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'share') {
      await _shareDocument(context, ref, doc.id, doc.title);
    } else if (action == 'save') {
      await _saveDocument(context, ref, doc.id, doc.title);
    } else if (action == 'select') {
      _toggleSelection(doc.id);
    }
  }

  void _applyFilter(DocumentsFilter filter) {
    setState(() => _ordering = filter.ordering);
    ref.read(documentsNotifierProvider.notifier).applyFilter(filter);
  }

  void _clearAllFilters() {
    setState(() => _activeSavedViewId = null);
    _applyFilter(DocumentsFilter(ordering: _ordering));
  }

  void _applySavedView(SavedView view) {
    final ordering = view.sortReverse
        ? '-${view.sortField}'
        : view.sortField;

    setState(() {
      _activeSavedViewId = view.id;
      _ordering = ordering;
    });

    ref.read(documentsNotifierProvider.notifier).applyFilter(
          filterRulesToDocumentsFilter(view.filterRules, ordering),
        );
  }

  @override
  Widget build(BuildContext context) {
    final docsState = ref.watch(documentsNotifierProvider);
    final tagsAsync = ref.watch(tagsProvider);
    final correspondentsAsync = ref.watch(correspondentsProvider);
    final docTypesAsync = ref.watch(documentTypesProvider);
    final savedViewsAsync = ref.watch(savedViewsProvider);
    final tokens = AppTokens.of(context);

    // Show loadMore errors as SnackBar
    ref.listen(documentsNotifierProvider, (prev, next) {
      final error = next.valueOrNull?.loadMoreError;
      if (error != null && error != prev?.valueOrNull?.loadMoreError) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
    });

    final currentFilter = docsState.valueOrNull?.filter ?? const DocumentsFilter();
    final hasActiveFilters = currentFilter.correspondentId != null ||
        currentFilter.documentTypeId != null ||
        (currentFilter.tagIds != null && currentFilter.tagIds!.isNotEmpty) ||
        currentFilter.createdDateFrom != null ||
        currentFilter.createdDateTo != null;

    final subtitle = _isSelecting
        ? '${_selectedIds.length} selected'
        : switch (docsState.valueOrNull?.totalCount) {
            null => ' ',
            0 => 'No documents',
            1 => '1 document',
            final n => '$n documents',
          };

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header — Library title + count subtitle + single icon action.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.xl, Spacing.lg, Spacing.md, Spacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Library',
                                style: Theme.of(context).textTheme.headlineMedium),
                            Text(
                              subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: tokens.inkSoft),
                            ),
                          ],
                        ),
                      ),
                      _isSelecting
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: 'Cancel selection',
                              iconSize: 26,
                              onPressed: _clearSelection,
                            )
                          : IconButton(
                              icon: const Icon(Icons.settings_outlined),
                              tooltip: 'Settings',
                              iconSize: 26,
                              onPressed: () => context.push('/settings'),
                            ),
                    ],
                  ),
                ),
                // Omnibox + Filter pill.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.xl, 0, Spacing.xl, Spacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Omnibox(
                          onTap: () => context.push('/search'),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      _FilterPill(
                        active: hasActiveFilters,
                        onTap: () => _showFilterSheet(context, currentFilter),
                      ),
                    ],
                  ),
                ),
                // Active filters — dismissible stamp pills, only when set.
                if (hasActiveFilters)
                  ActiveFiltersBar(
                    filter: currentFilter,
                    tags: tagsAsync.valueOrNull ?? const {},
                    correspondents: correspondentsAsync.valueOrNull ?? const {},
                    docTypes: docTypesAsync.valueOrNull ?? const {},
                    onChanged: (f) {
                      setState(() => _activeSavedViewId = null);
                      _applyFilter(f);
                    },
                    onClear: _clearAllFilters,
                    onSave: () => showSaveViewDialog(
                      context: context,
                      ref: ref,
                      currentFilter: currentFilter,
                    ),
                  ),
                Expanded(
                  child: docsState.when(
                    loading: () => const DocumentListSkeleton(),
                    error: (err, _) => _ErrorView(
                      message: friendlyApiMessage(err,
                          fallback: 'Failed to load documents.'),
                      onRetry: () =>
                          ref.read(documentsNotifierProvider.notifier).refresh(),
                    ),
                    data: (docsData) {
                      final tags = tagsAsync.valueOrNull ?? <int, Tag>{};
                      final correspondents =
                          correspondentsAsync.valueOrNull ?? <int, Correspondent>{};
                      final docTypes =
                          docTypesAsync.valueOrNull ?? <int, DocumentType>{};
                      final savedViews = savedViewsAsync.valueOrNull ?? const [];

                      if (docsData.documents.isEmpty) {
                        return _EmptyLibrary(
                          hasActiveFilters: hasActiveFilters,
                          onClearFilters: _clearAllFilters,
                        );
                      }

                      final api = ref.watch(paperlessApiProvider);

                      return PaginatedListView(
                        onRefresh: () =>
                            ref.read(documentsNotifierProvider.notifier).refresh(),
                        onLoadMore: () =>
                            ref.read(documentsNotifierProvider.notifier).loadMore(),
                        isLoadingMore: docsData.isLoadingMore,
                        slivers: [
                          // Saved views carousel.
                          if (savedViews.isNotEmpty)
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: 56,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Spacing.lg),
                                  children: [
                                    for (final view in savedViews)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: Spacing.sm),
                                        child: _SavedViewChip(
                                          view: view,
                                          selected: _activeSavedViewId == view.id,
                                          onTap: () {
                                            if (_activeSavedViewId == view.id) {
                                              _clearAllFilters();
                                            } else {
                                              _applySavedView(view);
                                            }
                                          },
                                          onManage: () => showChipManagementSheet(
                                            context: context,
                                            view: view,
                                            onDelete: () => confirmDeleteSavedView(
                                              context: context,
                                              ref: ref,
                                              view: view,
                                              onDeactivated:
                                                  _activeSavedViewId == view.id
                                                      ? _clearAllFilters
                                                      : null,
                                            ),
                                            onRename: () => showRenameSavedViewDialog(
                                              context: context,
                                              ref: ref,
                                              view: view,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          SliverList.builder(
                            itemCount: docsData.documents.length,
                            itemBuilder: (context, index) {
                              final doc = docsData.documents[index];
                              final isSelected = _selectedIds.contains(doc.id);
                              return Stack(
                                key: ValueKey(doc.id),
                                children: [
                                  DocumentCard(
                                    document: doc,
                                    tags: tags,
                                    correspondents: correspondents,
                                    documentTypes: docTypes,
                                    thumbnailUrl: api.thumbnailUrl(doc.id),
                                    authToken: api.authToken,
                                    onTap: _isSelecting
                                        ? () => _toggleSelection(doc.id)
                                        : () => context.push('/documents/${doc.id}'),
                                    onLongPress: _isSelecting
                                        ? () => _toggleSelection(doc.id)
                                        : () =>
                                            _showDocumentContextMenu(context, ref, doc),
                                  ),
                                  if (isSelected)
                                    Positioned.fill(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: Spacing.lg,
                                            vertical: Spacing.xs),
                                        decoration: BoxDecoration(
                                          color: tokens.accentSoft.withValues(alpha: 0.6),
                                          borderRadius:
                                              BorderRadius.circular(Radii.lg),
                                          border: Border.all(
                                            color: tokens.accentEmphasis,
                                            width: 2,
                                          ),
                                        ),
                                        child: Align(
                                          alignment: Alignment.topRight,
                                          child: Padding(
                                            padding: const EdgeInsets.all(Spacing.sm),
                                            child: Icon(
                                              Icons.check_circle,
                                              color: tokens.accentEmphasis,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            // Floating bulk action bar.
            if (_isSelecting)
              Positioned(
                bottom: Spacing.xl,
                left: Spacing.lg,
                right: Spacing.lg,
                child: Center(
                  child: BulkActionBar(
                    selectedIds: _selectedIds,
                    onClearSelection: _clearSelection,
                    onRefresh: () =>
                        ref.read(documentsNotifierProvider.notifier).refresh(),
                    onShare: () => _shareSelected(context, ref),
                    onSave: () => _saveSelected(context, ref),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmBulkShare(BuildContext context, int count) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share documents?'),
        content: Text(
          'Sharing $count documents requires downloading them all. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmBulkSave(BuildContext context, int count) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save documents?'),
        content: Text(
          'Saving $count documents requires downloading them all. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSelected(BuildContext context, WidgetRef ref) async {
    final docs = ref.read(documentsNotifierProvider).valueOrNull?.documents ?? [];
    final selectedDocs = docs.where((d) => _selectedIds.contains(d.id)).toList();
    if (selectedDocs.isEmpty) return;

    if (selectedDocs.length > 5) {
      final confirmed = await _confirmBulkSave(context, selectedDocs.length);
      if (confirmed != true || !context.mounted) return;
    }

    final paths = <String>[];
    final names = <String>[];
    final downloadFailures = <String>[];

    for (final doc in selectedDocs) {
      try {
        paths.add(await ref.read(
          documentDownloadProvider(doc.id, doc.title).future,
        ));
        names.add(
          '${sanitizeExportName(doc.title, fallback: 'document_${doc.id}')}.pdf',
        );
      } catch (_) {
        downloadFailures.add(doc.title);
      }
    }

    if (paths.isNotEmpty && context.mounted) {
      await saveToFolderWithFallback(
        context: context,
        ref: ref,
        localPaths: paths,
        fileNames: names,
      );
      if (context.mounted) _clearSelection();
    }

    // Reported separately from save failures: these never reached the disk.
    if (downloadFailures.isNotEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download: ${downloadFailures.join(', ')}'),
        ),
      );
    }
  }

  Future<void> _shareSelected(BuildContext context, WidgetRef ref) async {
    final docs = ref.read(documentsNotifierProvider).valueOrNull?.documents ?? [];
    final selectedDocs = docs.where((d) => _selectedIds.contains(d.id)).toList();
    if (selectedDocs.isEmpty) return;

    if (selectedDocs.length > 5) {
      final confirmed = await _confirmBulkShare(context, selectedDocs.length);
      if (confirmed != true || !context.mounted) return;
    }

    final paths = <String>[];
    final failures = <String>[];

    for (final doc in selectedDocs) {
      try {
        final path = await ref.read(
          documentDownloadProvider(doc.id, doc.title).future,
        );
        paths.add(path);
      } catch (_) {
        failures.add(doc.title);
      }
    }

    if (paths.isNotEmpty && context.mounted) {
      await Share.shareXFiles(paths.map((p) => XFile(p)).toList());
      if (context.mounted) _clearSelection();
    }

    if (failures.isNotEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download: ${failures.join(', ')}'),
        ),
      );
    }
  }

  void _showFilterSheet(BuildContext context, DocumentsFilter currentFilter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterBottomSheet(
        currentFilter: currentFilter,
        onApply: (filter) {
          setState(() => _activeSavedViewId = null);
          _applyFilter(filter);
        },
      ),
    );
  }
}

/// Full-width pill that reads as a search field but opens the search screen.
class _Omnibox extends StatelessWidget {
  const _Omnibox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Material(
      color: tokens.card,
      shape: StadiumBorder(side: BorderSide(color: tokens.line)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.search, size: 20, color: tokens.inkSoft),
              const SizedBox(width: Spacing.sm),
              Text(
                'Search documents',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: tokens.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single Filter pill; a badge dot appears when filters are active.
class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Material(
      color: active ? tokens.accentSoft : tokens.card,
      shape: StadiumBorder(
        side: BorderSide(color: active ? tokens.accentEmphasis : tokens.line),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune,
                  size: 20,
                  color: active ? tokens.accentEmphasis : tokens.inkSoft),
              const SizedBox(width: Spacing.xs),
              Text(
                'Filter',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: active ? tokens.accentEmphasis : tokens.ink,
                    ),
              ),
              if (active) ...[
                const SizedBox(width: Spacing.xs),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: tokens.accentEmphasis,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Saved-view chip in the carousel. Selected = accent stamp; unselected =
/// muted stamp. Long-press opens rename/delete.
class _SavedViewChip extends StatelessWidget {
  const _SavedViewChip({
    required this.view,
    required this.selected,
    required this.onTap,
    required this.onManage,
  });

  final SavedView view;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return GestureDetector(
      onLongPress: onManage,
      child: StampChip(
        label: view.name,
        icon: selected ? Icons.check : Icons.bookmark_border,
        rotated: false,
        tint: selected ? null : tokens.inkSoft,
        onTap: onTap,
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({
    required this.hasActiveFilters,
    required this.onClearFilters,
  });

  final bool hasActiveFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StampChip(
            label: hasActiveFilters ? 'NO MATCHES' : 'EMPTY',
            rotated: true,
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            hasActiveFilters ? 'No documents found' : 'Nothing here yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            hasActiveFilters
                ? 'Try adjusting your filters'
                : 'Upload a document to get started',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: tokens.inkSoft),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: Spacing.lg),
            TextButton(
              onPressed: onClearFilters,
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: Spacing.lg),
            Text('Failed to load documents',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Spacing.sm),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: Spacing.lg),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
