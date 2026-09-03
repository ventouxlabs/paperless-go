import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_providers.dart';
import '../../core/design_tokens.dart';
import '../../core/models/storage_path.dart';
import '../../core/models/tag.dart';
import '../../core/api/api_error_mapper.dart';
import '../../shared/widgets/metadata_sheet.dart';

/// Floating action bar shown during multi-select mode.
class BulkActionBar extends ConsumerWidget {
  final Set<int> selectedIds;
  final VoidCallback onClearSelection;
  final VoidCallback onRefresh;
  final VoidCallback onShare;
  final VoidCallback onSave;

  const BulkActionBar({
    super.key,
    required this.selectedIds,
    required this.onClearSelection,
    required this.onRefresh,
    required this.onShare,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = AppTokens.of(context);

    return Material(
      elevation: 0,
      color: tokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: tokens.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clear selection',
              onPressed: onClearSelection,
            ),
            Text(
              '${selectedIds.length}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: tokens.ink),
            ),
            const SizedBox(width: Spacing.xs),
            _ActionButton(
              icon: Icons.edit_outlined,
              tooltip: 'Edit metadata',
              onPressed: () => _showEditSheet(context, ref),
            ),
            _ActionButton(
              icon: Icons.share_outlined,
              tooltip: 'Share',
              onPressed: onShare,
            ),
            _ActionButton(
              icon: Icons.folder_outlined,
              tooltip: 'Save to folder',
              onPressed: onSave,
            ),
            _ActionButton(
              icon: Icons.delete_outline,
              tooltip: 'Delete',
              onPressed: () => _showBulkDeleteDialog(context, ref),
              color: colorScheme.error,
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: tokens.inkSoft),
              tooltip: 'More actions',
              onSelected: (action) {
                switch (action) {
                  case 'remove_tags':
                    _showBulkTagRemoveDialog(context, ref);
                  case 'storage_path':
                    _showBulkStoragePathDialog(context, ref);
                  case 'merge':
                    _showBulkMergeDialog(context, ref);
                  case 'rotate':
                    _showBulkRotateDialog(context, ref);
                  case 'redo_ocr':
                    _showBulkOcrDialog(context, ref);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'remove_tags',
                  child: ListTile(
                    leading: Icon(Icons.label_off_outlined),
                    title: Text('Remove tags'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'storage_path',
                  child: ListTile(
                    leading: Icon(Icons.folder_outlined),
                    title: Text('Set storage path'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (selectedIds.length >= 2)
                  const PopupMenuItem(
                    value: 'merge',
                    child: ListTile(
                      leading: Icon(Icons.merge),
                      title: Text('Merge'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const PopupMenuItem(
                  value: 'rotate',
                  child: ListTile(
                    leading: Icon(Icons.rotate_right),
                    title: Text('Rotate'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'redo_ocr',
                  child: ListTile(
                    leading: Icon(Icons.document_scanner_outlined),
                    title: Text('Re-run OCR'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the shared [MetadataSheet] for bulk-editing tags, correspondent,
  /// and document type across the selection. Starts blank (not diffed against
  /// any single document) — only fields the user actually touches are sent,
  /// each as its own `bulkEdit` call. There's no bulk-edit method for
  /// `created`, so the sheet's date field is a no-op here.
  Future<void> _showEditSheet(BuildContext context, WidgetRef ref) async {
    final count = selectedIds.length;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MetadataSheet(
        topSlot: Text(
          'Editing $count documents',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        onSave: (result) => _applyBulkEdit(context, ref, result),
      ),
    );
  }

  Future<void> _applyBulkEdit(
    BuildContext context,
    WidgetRef ref,
    MetadataSheetResult result,
  ) async {
    if (result.correspondentId == null &&
        result.documentTypeId == null &&
        result.tagIds.isEmpty) {
      return;
    }

    final api = ref.read(paperlessApiProvider);
    final docIds = selectedIds.toList();
    final failures = <String>[];

    if (result.correspondentId != null) {
      try {
        await api.bulkEdit(
          documents: docIds,
          method: 'set_correspondent',
          parameters: {'correspondent': result.correspondentId},
        );
      } catch (e) {
        failures.add('correspondent (${friendlyApiMessage(e)})');
      }
    }
    if (result.documentTypeId != null) {
      try {
        await api.bulkEdit(
          documents: docIds,
          method: 'set_document_type',
          parameters: {'document_type': result.documentTypeId},
        );
      } catch (e) {
        failures.add('document type (${friendlyApiMessage(e)})');
      }
    }
    if (result.tagIds.isNotEmpty) {
      try {
        await api.bulkEdit(
          documents: docIds,
          method: 'modify_tags',
          parameters: {'add_tags': result.tagIds, 'remove_tags': <int>[]},
        );
      } catch (e) {
        failures.add('tags (${friendlyApiMessage(e)})');
      }
    }

    if (!context.mounted) return;
    onClearSelection();
    onRefresh();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failures.isEmpty
              ? '${docIds.length} documents updated'
              : 'Failed to update: ${failures.join(', ')}',
        ),
      ),
    );
  }

  Future<void> _showBulkTagRemoveDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final tagsMap = ref.read(tagsProvider).valueOrNull ?? {};
    final allTags = tagsMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final selected = await showDialog<Set<int>>(
      context: context,
      builder: (ctx) => _BulkTagPicker(
        tags: allTags,
        title: 'Remove Tags',
        actionLabel: 'Remove',
      ),
    );

    if (selected != null && selected.isNotEmpty && context.mounted) {
      final count = selectedIds.length;
      try {
        final api = ref.read(paperlessApiProvider);
        await api.bulkEdit(
          documents: selectedIds.toList(),
          method: 'modify_tags',
          parameters: {'add_tags': <int>[], 'remove_tags': selected.toList()},
        );
        if (!context.mounted) return;
        onClearSelection();
        onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tags removed from $count documents')),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove tags: ${friendlyApiMessage(e)}'),
            ),
          );
        }
      }
    }
  }

  Future<void> _showBulkStoragePathDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final pathsMap = ref.read(storagePathsProvider).valueOrNull ?? {};
    final allPaths = pathsMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final selected = await showDialog<int?>(
      context: context,
      builder: (ctx) => _BulkSinglePicker<StoragePath>(
        title: 'Set Storage Path',
        items: allPaths,
        displayName: (sp) => sp.name,
        getId: (sp) => sp.id,
      ),
    );

    if (selected != null && context.mounted) {
      final count = selectedIds.length;
      try {
        final api = ref.read(paperlessApiProvider);
        await api.bulkEdit(
          documents: selectedIds.toList(),
          method: 'set_storage_path',
          parameters: {'storage_path': selected},
        );
        if (!context.mounted) return;
        onClearSelection();
        onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage path set on $count documents')),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to set storage path: ${friendlyApiMessage(e)}',
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _showBulkMergeDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Merge documents?'),
        content: Text(
          'Merge ${selectedIds.length} documents into one? '
          'The first selected document will be the primary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Merge'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final api = ref.read(paperlessApiProvider);
        final docIds = selectedIds.toList();
        await api.bulkEdit(
          documents: docIds,
          method: 'merge',
          parameters: {'metadata_document_id': docIds.first},
        );
        if (!context.mounted) return;
        onClearSelection();
        onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${docIds.length} documents merged')),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to merge: ${friendlyApiMessage(e)}'),
            ),
          );
        }
      }
    }
  }

  Future<void> _showBulkRotateDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final degrees = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Rotate documents'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 90),
            child: const Text('90 degrees clockwise'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 180),
            child: const Text('180 degrees'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 270),
            child: const Text('270 degrees clockwise'),
          ),
        ],
      ),
    );

    if (degrees != null && context.mounted) {
      final count = selectedIds.length;
      try {
        final api = ref.read(paperlessApiProvider);
        await api.bulkEdit(
          documents: selectedIds.toList(),
          method: 'rotate',
          parameters: {'degrees': degrees},
        );
        if (!context.mounted) return;
        onClearSelection();
        onRefresh();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$count documents rotated')));
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to rotate: ${friendlyApiMessage(e)}'),
            ),
          );
        }
      }
    }
  }

  Future<void> _showBulkOcrDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Re-run OCR?'),
        content: Text(
          'Re-run OCR on ${selectedIds.length} documents? This may take a while.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Re-run OCR'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final count = selectedIds.length;
      try {
        final api = ref.read(paperlessApiProvider);
        await api.bulkEdit(documents: selectedIds.toList(), method: 'redo_ocr');
        if (!context.mounted) return;
        onClearSelection();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR re-run started for $count documents')),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to re-run OCR: ${friendlyApiMessage(e)}'),
            ),
          );
        }
      }
    }
  }

  Future<void> _showBulkDeleteDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to trash?'),
        content: Text('Move ${selectedIds.length} documents to trash?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Move to trash'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final count = selectedIds.length;
      try {
        final api = ref.read(paperlessApiProvider);
        await api.trashDocuments(selectedIds.toList());
        if (!context.mounted) return;
        onClearSelection();
        onRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count documents moved to trash')),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${friendlyApiMessage(e)}'),
            ),
          );
        }
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

class _BulkTagPicker extends StatefulWidget {
  final List<Tag> tags;
  final String title;
  final String actionLabel;

  const _BulkTagPicker({
    required this.tags,
    this.title = 'Add Tags',
    this.actionLabel = 'Add',
  });

  @override
  State<_BulkTagPicker> createState() => _BulkTagPickerState();
}

class _BulkTagPickerState extends State<_BulkTagPicker> {
  final _selected = <int>{};
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.tags
        .where((t) => t.name.toLowerCase().contains(_filter.toLowerCase()))
        .toList();

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search tags...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final tag = filtered[i];
                  final isSelected = _selected.contains(tag.id);
                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(tag.name),
                    dense: true,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selected.add(tag.id);
                        } else {
                          _selected.remove(tag.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(context, _selected),
          child: Text('${widget.actionLabel} (${_selected.length})'),
        ),
      ],
    );
  }
}

class _BulkSinglePicker<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) displayName;
  final int Function(T) getId;

  const _BulkSinglePicker({
    required this.title,
    required this.items,
    required this.displayName,
    required this.getId,
  });

  @override
  State<_BulkSinglePicker<T>> createState() => _BulkSinglePickerState<T>();
}

class _BulkSinglePickerState<T> extends State<_BulkSinglePicker<T>> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where(
          (item) => widget
              .displayName(item)
              .toLowerCase()
              .contains(_filter.toLowerCase()),
        )
        .toList();

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final item = filtered[i];
                  return ListTile(
                    title: Text(widget.displayName(item)),
                    dense: true,
                    onTap: () => Navigator.pop(context, widget.getId(item)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
