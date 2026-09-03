import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error_mapper.dart';
import '../../core/api/api_providers.dart';
import '../../core/design_tokens.dart';
import '../../core/models/correspondent.dart';
import '../../core/models/document.dart';
import '../../core/models/document_type.dart';
import '../../shared/widgets/metadata_dropdown.dart';
import '../../shared/widgets/stamp_chip.dart';
import '../scanner/processing/metadata_matcher.dart';
import 'inbox_notifier.dart';
import 'inbox_suggestions_provider.dart';
import '../upload_queue/queue_status_banner.dart';

/// Inbox as a swipeable card stack — the highest-frequency workflow.
///
/// Swipe right / ✓ = accept OCR-matched suggestions (also files the document
/// out of the inbox). Swipe left / ✎ = edit sheet. Tap / ○ = full detail.
/// The on-card buttons are the accessible, non-gesture path to every action.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxState = ref.watch(inboxNotifierProvider);
    final tokens = AppTokens.of(context);

    ref.listen(inboxNotifierProvider, (prev, next) {
      final error = next.valueOrNull?.loadMoreError;
      if (error != null && error != prev?.valueOrNull?.loadMoreError) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error)));
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Renders nothing unless an upload has actually stopped trying.
            const QueueStatusBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.xl, Spacing.lg, Spacing.md, Spacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Inbox',
                            style: Theme.of(context).textTheme.headlineMedium),
                        Text(
                          switch (inboxState.valueOrNull?.totalCount) {
                            null => ' ',
                            0 => 'All caught up',
                            1 => '1 to sort',
                            final n => '$n to sort',
                          },
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: tokens.inkSoft),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: 'Search',
                    iconSize: 26,
                    onPressed: () => context.push('/search'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: inboxState.when(
                loading: () => const _StackSkeleton(),
                error: (err, _) => _ErrorPanel(
                  message:
                      friendlyApiMessage(err, fallback: 'Failed to load inbox.'),
                  onRetry: () => ref.invalidate(inboxNotifierProvider),
                ),
                data: (inbox) => inbox.documents.isEmpty
                    ? const _EmptyInbox()
                    : _CardStack(documents: inbox.documents),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardStack extends ConsumerStatefulWidget {
  const _CardStack({required this.documents});

  final List<Document> documents;

  @override
  ConsumerState<_CardStack> createState() => _CardStackState();
}

class _CardStackState extends ConsumerState<_CardStack>
    with SingleTickerProviderStateMixin {
  static const _swipeThreshold = 110.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<Offset>? _animation;
  Offset _drag = Offset.zero;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final a = _animation;
      if (a != null) setState(() => _drag = a.value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docs = widget.documents;
    final active = docs.first;

    // Keep the queue topped up while sorting.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (docs.length < 5 && mounted) {
        ref.read(inboxNotifierProvider.notifier).loadMore();
      }
    });

    final width = MediaQuery.sizeOf(context).width;
    final progress = (_drag.dx / width).clamp(-1.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Spacing.xl, Spacing.sm, Spacing.xl, Spacing.lg),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Behind-cards show queue depth: scaled down, offset upward.
          for (var i = (docs.length - 1).clamp(0, 2); i >= 1; i--)
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, -10.0 * i + 10.0 * progress.abs()),
                child: Transform.scale(
                  scale: 1 - 0.04 * i + 0.04 * progress.abs().clamp(0, 1 / i),
                  child: _InboxCard(document: docs[i], dimmed: true),
                ),
              ),
            ),
          Positioned.fill(
            child: GestureDetector(
              onPanUpdate: _busy
                  ? null
                  : (d) => setState(() => _drag += Offset(d.delta.dx, 0)),
              onPanEnd: _busy ? null : (_) => _onPanEnd(active),
              child: Transform.translate(
                offset: _drag,
                child: Transform.rotate(
                  angle: progress * 0.06,
                  child: _InboxCard(
                    document: active,
                    onTap: () => context.push('/documents/${active.id}'),
                    onAccept: () => _accept(active),
                    onEdit: () => _openEditSheet(active),
                    accepting: progress > 0.15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPanEnd(Document active) {
    if (_drag.dx > _swipeThreshold) {
      _accept(active);
    } else if (_drag.dx < -_swipeThreshold) {
      _snapBack();
      _openEditSheet(active);
    } else {
      _snapBack();
    }
  }

  void _animateTo(Offset target, {VoidCallback? then}) {
    _animation = Tween(begin: _drag, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward(from: 0).whenComplete(() {
      _animation = null;
      then?.call();
    });
  }

  void _snapBack() => _animateTo(Offset.zero);

  Future<void> _accept(Document doc) async {
    if (_busy) return;
    setState(() => _busy = true);
    final width = MediaQuery.sizeOf(context).width;
    _animateTo(Offset(width * 1.2, 0));

    final suggestions = ref
            .read(inboxSuggestionsProvider(doc))
            .valueOrNull ??
        const MetadataSuggestions();
    final notifier = ref.read(inboxNotifierProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final previous = await notifier.acceptSuggestions(doc, suggestions);
      if (!mounted) return;
      setState(() {
        _drag = Offset.zero;
        _busy = false;
      });
      if (previous != null) {
        messenger.showSnackBar(SnackBar(
          content: Text('Filed "${doc.title}"'),
          // Flutter defaults an action-bearing SnackBar to persist: true
          // (snack_bar.dart: `persist = persist ?? action != null`) — without
          // this, the auto-dismiss timer fires but early-returns before
          // hiding it, and never re-arms, so it stays pinned indefinitely.
          persist: false,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => notifier.undoAccept(doc.id, previous),
          ),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _drag = Offset.zero;
        _busy = false;
      });
      messenger.showSnackBar(SnackBar(
        content: Text('Failed to file: ${friendlyApiMessage(e)}'),
      ));
    }
  }

  void _openEditSheet(Document doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditSheet(document: doc),
    );
  }
}

class _InboxCard extends ConsumerWidget {
  const _InboxCard({
    required this.document,
    this.onTap,
    this.onAccept,
    this.onEdit,
    this.dimmed = false,
    this.accepting = false,
  });

  final Document document;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onEdit;
  final bool dimmed;
  final bool accepting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppTokens.of(context);
    final api = ref.watch(paperlessApiProvider);
    final correspondents =
        ref.watch(correspondentsProvider).valueOrNull ?? {};

    final meta = <String>[
      if (document.correspondent != null)
        correspondents[document.correspondent]?.name ?? '',
      if (document.created != null)
        MaterialLocalizations.of(context).formatMediumDate(document.created!),
    ].where((s) => s.isNotEmpty).join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xl),
        side: BorderSide(
          color: accepting ? tokens.accentEmphasis : tokens.line,
          width: accepting ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          opacity: dimmed ? 0.55 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: ColoredBox(
                    color: tokens.paper,
                    child: CachedNetworkImage(
                      imageUrl: api.thumbnailUrl(document.id),
                      httpHeaders: {'Authorization': api.authToken},
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorWidget: (_, __, ___) => Icon(
                        Icons.description_outlined,
                        size: 56,
                        color: tokens.inkSoft,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.lg, Spacing.md, Spacing.lg, Spacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(meta,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: tokens.inkSoft)),
                    ],
                    const SizedBox(height: Spacing.sm),
                    if (!dimmed) _SuggestionChips(document: document),
                  ],
                ),
              ),
              if (!dimmed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.sm, 0, Spacing.sm, Spacing.sm),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: Icon(Icons.edit_outlined,
                            size: 18, color: tokens.stamp),
                        label: const Text('Edit'),
                      ),
                      TextButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.description_outlined, size: 18),
                        label: const Text('Details'),
                      ),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onAccept,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// OCR-matched suggestions rendered as the signature stamp chips.
class _SuggestionChips extends ConsumerWidget {
  const _SuggestionChips({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppTokens.of(context);
    final suggestionsAsync = ref.watch(inboxSuggestionsProvider(document));
    final tags = ref.watch(tagsProvider).valueOrNull ?? {};
    final correspondents = ref.watch(correspondentsProvider).valueOrNull ?? {};
    final docTypes = ref.watch(documentTypesProvider).valueOrNull ?? {};

    return SizedBox(
      height: 76,
      child: suggestionsAsync.when(
        loading: () => Align(
          alignment: Alignment.centerLeft,
          child: Text('Reading document…',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: tokens.inkSoft)),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (s) {
          final chips = <Widget>[
            if (s.correspondentId != null &&
                correspondents[s.correspondentId] != null)
              StampChip(
                label: correspondents[s.correspondentId]!.name,
                icon: Icons.person_outline,
              ),
            if (s.documentTypeId != null && docTypes[s.documentTypeId] != null)
              StampChip(
                label: docTypes[s.documentTypeId]!.name,
                icon: Icons.category_outlined,
              ),
            for (final id in s.tagIds.take(4))
              if (tags[id] != null)
                StampChip(
                  label: tags[id]!.name,
                  icon: Icons.sell_outlined,
                ),
          ];
          if (chips.isEmpty) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text('No suggestions — accept just files it',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: tokens.inkSoft)),
            );
          }
          return Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: Spacing.xs,
              children: chips.take(5).toList(),
            ),
          );
        },
      ),
    );
  }
}

/// Edit sheet: quick assign plus remove-from-inbox — the swipe-left target
/// and the accessible alternative to gestures.
class _EditSheet extends ConsumerStatefulWidget {
  const _EditSheet({required this.document});

  final Document document;

  @override
  ConsumerState<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends ConsumerState<_EditSheet> {
  int? _correspondentId;
  int? _documentTypeId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _correspondentId = widget.document.correspondent;
    _documentTypeId = widget.document.documentType;
  }

  @override
  Widget build(BuildContext context) {
    final correspondents = ref.watch(correspondentsProvider).valueOrNull ?? {};
    final docTypes = ref.watch(documentTypesProvider).valueOrNull ?? {};

    return Padding(
      padding: EdgeInsets.fromLTRB(
          Spacing.lg, Spacing.lg, Spacing.lg,
          Spacing.lg + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.document.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.lg),
          MetadataDropdown<Correspondent>(
            label: 'Correspondent',
            value: correspondents[_correspondentId],
            items: correspondents.values.toList(),
            displayName: (c) => c.name,
            onChanged: (c) => setState(() => _correspondentId = c?.id),
          ),
          const SizedBox(height: Spacing.md),
          MetadataDropdown<DocumentType>(
            label: 'Document Type',
            value: docTypes[_documentTypeId],
            items: docTypes.values.toList(),
            displayName: (dt) => dt.name,
            onChanged: (dt) => setState(() => _documentTypeId = dt?.id),
          ),
          const SizedBox(height: Spacing.lg),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
          TextButton.icon(
            onPressed: _saving ? null : _removeFromInbox,
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Remove from inbox without changes'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final api = ref.read(paperlessApiProvider);
      await api.updateDocument(widget.document.id, {
        'correspondent': _correspondentId,
        'document_type': _documentTypeId,
      });
      ref.invalidate(inboxNotifierProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: ${friendlyApiMessage(e)}')),
        );
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _removeFromInbox() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(inboxNotifierProvider.notifier)
          .removeFromInbox(widget.document);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: ${friendlyApiMessage(e)}')),
        );
        setState(() => _saving = false);
      }
    }
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StampChip(label: 'ALL CAUGHT UP', rotated: true),
          const SizedBox(height: Spacing.lg),
          Text('Nothing to sort',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Spacing.xs),
          Text('New documents land here first.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: tokens.inkSoft)),
          const SizedBox(height: Spacing.lg),
          TextButton.icon(
            onPressed: () => GoRouter.of(context).go('/scan'),
            icon: const Icon(Icons.document_scanner_outlined, size: 18),
            label: const Text('Scan something'),
          ),
        ],
      ),
    );
  }
}

class _StackSkeleton extends StatelessWidget {
  const _StackSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    Widget bar(double w) => Container(
          height: 14,
          width: w,
          decoration: BoxDecoration(
            color: tokens.line,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Spacing.xl, Spacing.sm, Spacing.xl, Spacing.lg),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.paper,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              bar(220),
              const SizedBox(height: Spacing.sm),
              bar(140),
              const SizedBox(height: Spacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

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
            Text('Failed to load inbox',
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
