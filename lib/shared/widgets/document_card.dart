import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design_tokens.dart';
import '../../core/api/thumbnail_cache_bust.dart';
import '../../core/thumbnail_cache.dart';
import '../../core/models/correspondent.dart';
import '../../core/models/document.dart';
import '../../core/models/document_type.dart';
import '../../core/models/tag.dart';
import 'tag_chip.dart';

class DocumentCard extends StatelessWidget {
  final Document document;
  final Map<int, Tag> tags;
  final Map<int, Correspondent> correspondents;
  final Map<int, DocumentType> documentTypes;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? thumbnailUrl;
  final String? authToken;

  /// When true the document is behind a per-document lock, so the thumbnail
  /// (a rendering of its first page) is replaced with a lock placeholder.
  final bool locked;

  /// Optional trailing widget (e.g. an actions menu) rendered at the end of the
  /// card. Provides a non-gesture affordance alongside swipe/long-press.
  final Widget? trailing;

  static const int _maxVisibleTags = 3;

  const DocumentCard({
    super.key,
    required this.document,
    required this.tags,
    required this.correspondents,
    required this.documentTypes,
    this.onTap,
    this.onLongPress,
    this.thumbnailUrl,
    this.authToken,
    this.locked = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final correspondent = document.correspondent != null
        ? correspondents[document.correspondent]
        : null;
    final docType = document.documentType != null
        ? documentTypes[document.documentType]
        : null;
    final docTags = document.tags
        .map((id) => tags[id])
        .whereType<Tag>()
        .toList();

    final subtitle = [
      if (correspondent != null) correspondent.name,
      if (docType != null) docType.name,
      if (document.created != null) DateFormat.yMMMd().format(document.created!),
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.xs),
      child: Semantics(
        label: document.title.isNotEmpty ? document.title : 'Untitled document',
        button: true,
        onTapHint: 'Open document',
        onLongPressHint: 'Show actions',
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(Radii.lg),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              if (locked)
                Padding(
                  padding: const EdgeInsets.only(right: Spacing.md),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    child: Container(
                      width: 48,
                      height: 64,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.lock_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              else if (thumbnailUrl != null && authToken != null)
                Padding(
                  padding: const EdgeInsets.only(right: Spacing.md),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    child: CachedNetworkImage(
                      imageUrl: cacheBustedThumbnailUrl(thumbnailUrl!, document.modified),
                      httpHeaders: {'Authorization': authToken!},
                      cacheManager: ThumbnailCacheManager.instance,
                      width: 48,
                      height: 64,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 48,
                        height: 64,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.description_outlined,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 48,
                        height: 64,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.broken_image_outlined,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      document.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Tags
                    if (docTags.isNotEmpty) ...[
                      const SizedBox(height: Spacing.sm),
                      Wrap(
                        spacing: Spacing.xs,
                        runSpacing: Spacing.xs,
                        children: [
                          ...docTags.take(_maxVisibleTags).map(
                            (tag) => ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 120),
                              child: TagChip(tag: tag),
                            ),
                          ),
                          if (docTags.length > _maxVisibleTags)
                            TagOverflowChip(count: docTags.length - _maxVisibleTags),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
      ),
    );
  }

}
