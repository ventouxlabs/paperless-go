import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_providers.dart';
import '../../core/design_tokens.dart';
import '../../core/models/correspondent.dart';
import '../../core/models/document_type.dart';
import '../../core/models/storage_path.dart';
import '../../core/models/tag.dart';
import 'metadata_dropdown.dart';
import 'stamp_chip.dart';

/// Immutable result of editing document metadata in [MetadataSheet].
class MetadataSheetResult {
  const MetadataSheetResult({
    this.correspondentId,
    this.documentTypeId,
    this.storagePathId,
    this.tagIds = const [],
    this.created,
  });

  final int? correspondentId;
  final int? documentTypeId;
  final int? storagePathId;
  final List<int> tagIds;
  final DateTime? created;
}

/// Reusable bottom sheet for the full metadata surface — correspondent and
/// document-type dropdowns, chip-based tag selection with search, and a created
/// date picker. OCR-suggested fields are marked with the signature stamp motif.
///
/// Deliberately free of any scanner-specific coupling: it takes initial values
/// and returns edits via [onSave], so other lanes (e.g. the library) can adopt
/// it unchanged. Callers inject their own extras (templates, etc.) via [topSlot].
class MetadataSheet extends ConsumerStatefulWidget {
  const MetadataSheet({
    super.key,
    this.correspondentId,
    this.documentTypeId,
    this.storagePathId,
    this.tagIds = const [],
    this.created,
    this.showStoragePath = false,
    this.suggestedCorrespondent = false,
    this.suggestedDocumentType = false,
    this.suggestedStoragePath = false,
    this.suggestedDate = false,
    this.suggestedTagIds = const {},
    this.topSlot,
    required this.onSave,
  });

  final int? correspondentId;
  final int? documentTypeId;
  final int? storagePathId;
  final List<int> tagIds;
  final DateTime? created;

  /// Shows the storage-path dropdown. Off by default so bulk, upload and
  /// detail callers are unchanged; [storagePathId] is returned as given then.
  final bool showStoragePath;

  final bool suggestedCorrespondent;
  final bool suggestedDocumentType;
  final bool suggestedStoragePath;
  final bool suggestedDate;
  final Set<int> suggestedTagIds;

  /// Optional caller-supplied controls rendered above the fields (e.g. template
  /// apply/save). Keeps the sheet reusable while letting the host inject extras.
  final Widget? topSlot;

  final ValueChanged<MetadataSheetResult> onSave;

  @override
  ConsumerState<MetadataSheet> createState() => _MetadataSheetState();
}

class _MetadataSheetState extends ConsumerState<MetadataSheet> {
  late int? _correspondentId = widget.correspondentId;
  late int? _documentTypeId = widget.documentTypeId;
  late int? _storagePathId = widget.storagePathId;
  late final List<int> _tagIds = List.of(widget.tagIds);
  late DateTime? _created = widget.created;
  String _tagFilter = '';

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final correspondentsAsync = ref.watch(correspondentsProvider);
    final docTypesAsync = ref.watch(documentTypesProvider);
    final tagsAsync = ref.watch(tagsProvider);
    final storagePathsAsync =
        widget.showStoragePath ? ref.watch(storagePathsProvider) : null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.lg, Spacing.lg, Spacing.lg, Spacing.sm),
              child: Text('Details',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                children: [
                  if (widget.topSlot != null) ...[
                    widget.topSlot!,
                    const SizedBox(height: Spacing.lg),
                  ],

                  // Correspondent
                  correspondentsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (correspondents) => MetadataDropdown<Correspondent>(
                      label: 'Correspondent',
                      value: correspondents[_correspondentId],
                      items: correspondents.values.toList(),
                      displayName: (c) => c.name,
                      suffix: widget.suggestedCorrespondent &&
                              _correspondentId == widget.correspondentId
                          ? const _SuggestedDot()
                          : null,
                      onChanged: (c) =>
                          setState(() => _correspondentId = c?.id),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Document type
                  docTypesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (docTypes) => MetadataDropdown<DocumentType>(
                      label: 'Document Type',
                      value: docTypes[_documentTypeId],
                      items: docTypes.values.toList(),
                      displayName: (dt) => dt.name,
                      suffix: widget.suggestedDocumentType &&
                              _documentTypeId == widget.documentTypeId
                          ? const _SuggestedDot()
                          : null,
                      onChanged: (dt) =>
                          setState(() => _documentTypeId = dt?.id),
                    ),
                  ),
                  if (storagePathsAsync != null) ...[
                    const SizedBox(height: Spacing.lg),
                    storagePathsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (paths) => MetadataDropdown<StoragePath>(
                        label: 'Storage Path',
                        value: paths[_storagePathId],
                        items: paths.values.toList(),
                        displayName: (s) => s.name,
                        suffix: widget.suggestedStoragePath &&
                                _storagePathId == widget.storagePathId
                            ? const _SuggestedDot()
                            : null,
                        onChanged: (s) =>
                            setState(() => _storagePathId = s?.id),
                      ),
                    ),
                  ],
                  const SizedBox(height: Spacing.sm),

                  // Created date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.calendar_today_outlined,
                        color: tokens.inkSoft),
                    title: Row(
                      children: [
                        const Text('Date'),
                        if (widget.suggestedDate &&
                            _created == widget.created) ...[
                          const SizedBox(width: Spacing.sm),
                          const _SuggestedDot(),
                        ],
                      ],
                    ),
                    subtitle: Text(_created != null
                        ? DateFormat.yMMMd().format(_created!)
                        : 'Auto-detect'),
                    onTap: _pickDate,
                    trailing: _created != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _created = null),
                          )
                        : null,
                  ),

                  const Divider(height: Spacing.xl),

                  // Tags
                  Text('Tags', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: Spacing.sm),
                  tagsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Failed to load tags'),
                    data: (allTags) => _buildTags(allTags, tokens),
                  ),
                  const SizedBox(height: Spacing.lg),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.lg, Spacing.sm, Spacing.lg, Spacing.lg),
              child: FilledButton(
                onPressed: () {
                  widget.onSave(MetadataSheetResult(
                    correspondentId: _correspondentId,
                    documentTypeId: _documentTypeId,
                    storagePathId: _storagePathId,
                    tagIds: List.of(_tagIds),
                    created: _created,
                  ));
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTags(Map<int, Tag> allTags, AppTokens tokens) {
    final selected =
        _tagIds.map((id) => allTags[id]).whereType<Tag>().toList();
    final matches = _tagFilter.isEmpty
        ? const <Tag>[]
        : (allTags.values
            .where((t) =>
                !_tagIds.contains(t.id) &&
                t.name.toLowerCase().contains(_tagFilter.toLowerCase()))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search tags to add…',
            prefixIcon: Icon(Icons.search),
            isDense: true,
          ),
          onChanged: (v) => setState(() => _tagFilter = v),
        ),
        if (matches.isNotEmpty) ...[
          const SizedBox(height: Spacing.sm),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.xs,
            children: [
              for (final tag in matches.take(12))
                ActionChip(
                  avatar: Icon(Icons.add, size: 16, color: tokens.inkSoft),
                  label: Text(tag.name),
                  onPressed: () => setState(() {
                    _tagIds.add(tag.id);
                    _tagFilter = '';
                  }),
                ),
            ],
          ),
        ],
        const SizedBox(height: Spacing.md),
        if (selected.isEmpty)
          Text('No tags selected',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: tokens.inkSoft))
        else
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.xs,
            children: [
              for (final tag in selected)
                if (widget.suggestedTagIds.contains(tag.id))
                  StampChip(
                    label: tag.name,
                    icon: Icons.sell_outlined,
                    rotated: false,
                    onDeleted: () => setState(() => _tagIds.remove(tag.id)),
                  )
                else
                  InputChip(
                    label: Text(tag.name),
                    onDeleted: () => setState(() => _tagIds.remove(tag.id)),
                  ),
            ],
          ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _created ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _created = picked);
  }
}

/// Small accent dot marking an OCR-suggested value.
class _SuggestedDot extends StatelessWidget {
  const _SuggestedDot();

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome, size: 14, color: tokens.accentEmphasis),
        const SizedBox(width: 2),
        Text('Suggested',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: tokens.accentEmphasis)),
      ],
    );
  }
}
