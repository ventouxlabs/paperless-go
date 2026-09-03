import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/thumbnail_cache.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/document_lock_service.dart';
import '../../core/services/pdf_tools_service.dart';
import '../../core/api/api_providers.dart';
import '../../core/api/thumbnail_cache_bust.dart';
import '../../shared/widgets/destructive_button_style.dart';
import '../../shared/widgets/metadata_dropdown.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/custom_field.dart';
import '../../core/models/document.dart';
import '../../core/models/storage_path.dart';
import '../../core/models/tag.dart';
import '../../core/design_tokens.dart';
import '../../shared/widgets/metadata_sheet.dart';
import '../../shared/widgets/tag_chip.dart';
import '../../shared/save_to_folder_action.dart';
import '../../core/services/export_destination_service.dart';
import 'ai_edit_trail_notifier.dart';
import 'document_detail_notifier.dart';
import 'documents_notifier.dart';
import '../inbox/inbox_notifier.dart';
import '../../core/api/api_error_mapper.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final int documentId;
  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  ConsumerState<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  bool _isLocked = true;
  bool _lockCheckComplete = false;
  bool _authenticated = false;
  final _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _loadLockState();
  }

  Future<void> _loadLockState() async {
    final locked = await ref.read(documentLockServiceProvider).isLocked(widget.documentId);
    if (mounted) {
      setState(() {
        _isLocked = locked;
        _lockCheckComplete = true;
      });
    }
  }

  Future<void> _authenticate() async {
    final success = await _biometricService.authenticate(
      reason: 'Authenticate to view locked document',
    );
    if (mounted && success) {
      setState(() => _authenticated = true);
    }
  }

  int get documentId => widget.documentId;

  @override
  Widget build(BuildContext context) {
    final docAsync = ref.watch(documentDetailProvider(documentId));
    final tagsAsync = ref.watch(tagsProvider);
    final correspondentsAsync = ref.watch(correspondentsProvider);
    final docTypesAsync = ref.watch(documentTypesProvider);
    final storagePathsAsync = ref.watch(storagePathsProvider);

    // Show loading indicator until the async lock check completes
    if (!_lockCheckComplete) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show biometric gate when document is locked and not yet authenticated
    if (_isLocked && !_authenticated) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 64),
              const SizedBox(height: 16),
              const Text('This document is locked'),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Authenticate'),
              ),
            ],
          ),
        ),
      );
    }

    return docAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load document'),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(documentDetailProvider(documentId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (doc) {
        final tags = tagsAsync.valueOrNull ?? {};
        final correspondents = correspondentsAsync.valueOrNull ?? {};
        final docTypes = docTypesAsync.valueOrNull ?? {};
        final storagePaths = storagePathsAsync.valueOrNull ?? {};
        final correspondent = doc.correspondent != null
            ? correspondents[doc.correspondent]
            : null;
        final docType = doc.documentType != null
            ? docTypes[doc.documentType]
            : null;
        final storagePath = doc.storagePath != null
            ? storagePaths[doc.storagePath]
            : null;
        final docTags = doc.tags
            .map((id) => tags[id])
            .whereType<Tag>()
            .toList();

        // One primary action (Share — the single most common thing to do
        // with a document once you've found it) plus one overflow entry
        // point for everything else, grouped by intent in a bottom sheet
        // rather than a flat dropdown. Preview already has its own large,
        // obvious tap target (the thumbnail below), so it doesn't need a
        // second app-bar affordance.
        final hasChat = (ref.watch(aiChatUrlProvider) ?? '').isNotEmpty;
        return Scaffold(
          appBar: AppBar(
            title: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share',
                onPressed: () => _handleAction(context, ref, 'share', doc.title),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More actions',
                onPressed: () => _showActionsSheet(context, ref, doc.title, hasChat),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Thumbnail header
              Semantics(
                label: 'Preview document',
                button: true,
                child: GestureDetector(
                  onTap: () => context.push('/documents/$documentId/preview'),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: cacheBustedThumbnailUrl(
                      ref.watch(paperlessApiProvider).thumbnailUrl(documentId),
                      doc.modified,
                    ),
                    httpHeaders: {'Authorization': ref.watch(paperlessApiProvider).authToken},
                    cacheManager: ThumbnailCacheManager.instance,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => Center(
                      child: Icon(Icons.description_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    errorWidget: (_, __, ___) => Center(
                      child: Icon(Icons.broken_image_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
              ),

              // Title (editable)
              _EditableTile(
                label: 'Title',
                value: doc.title,
                onSave: (v) async {
                  try {
                    await ref.read(documentDetailProvider(documentId).notifier)
                        .updateField({'title': v});
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update title: ${friendlyApiMessage(e)}')),
                      );
                    }
                  }
                },
              ),

              const Divider(height: 32),

              // Metadata summary — correspondent, type, date and tags in one
              // card; edited together via the shared MetadataSheet.
              _MetadataSummaryCard(
                correspondentName: correspondent?.name,
                documentTypeName: docType?.name,
                created: doc.created,
                tags: docTags,
                onEdit: () => _openMetadataSheet(doc),
              ),
              const SizedBox(height: 12),

              // Storage Path
              MetadataDropdown<StoragePath>(
                label: 'Storage Path',
                value: storagePath,
                items: storagePaths.values.toList(),
                displayName: (sp) => sp.name,
                onChanged: (sp) async {
                  try {
                    await ref.read(documentDetailProvider(documentId).notifier)
                        .updateField({'storage_path': sp?.id});
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update: ${friendlyApiMessage(e)}')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),

              // Scan date shortcut — shown below the metadata summary
              if (doc.added != null) ...[
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Row(
                    children: [
                      Icon(
                        Icons.upload_file_outlined,
                        size: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Scanned ${DateFormat.yMMMd().format(doc.added!)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const Spacer(),
                      if (doc.added!.toIso8601String().split('T').first !=
                          (doc.created?.toIso8601String().split('T').first ??
                              ''))
                        TextButton(
                          style: TextButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            textStyle:
                                Theme.of(context).textTheme.labelSmall,
                          ),
                          onPressed: () async {
                            final scanDate = doc.added!
                                .toIso8601String()
                                .split('T')
                                .first;
                            try {
                              await ref
                                  .read(documentDetailProvider(documentId)
                                      .notifier)
                                  .updateField({'created': scanDate});
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Failed to update date: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Use as created'),
                        ),
                    ],
                  ),
                ),
              ],

              // ASN (editable)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tag),
                title: Text('Archive Serial Number',
                    style: Theme.of(context).textTheme.labelSmall),
                subtitle: Text(
                  doc.archiveSerialNumber?.toString() ?? 'Not set',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: () async {
                  final controller = TextEditingController(
                    text: doc.archiveSerialNumber?.toString() ?? '',
                  );
                  try {
                    final result = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Edit ASN'),
                        content: TextField(
                          controller: controller,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Archive serial number',
                            helperText: 'Leave empty to clear',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, controller.text),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    );
                    if (result != null && context.mounted) {
                      final asn = result.isEmpty ? null : int.tryParse(result);
                      if (result.isNotEmpty && asn == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid number')),
                        );
                        return;
                      }
                      try {
                        await ref.read(documentDetailProvider(documentId).notifier)
                            .updateField({'archive_serial_number': asn});
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update ASN: ${friendlyApiMessage(e)}')),
                          );
                        }
                      }
                    }
                  } catch (_) {
                    // Dialog cancelled — no action needed
                  }
                },
              ),

              // Custom fields
              const Divider(height: 32),
              _CustomFieldsSection(
                documentId: documentId,
                fieldInstances: doc.customFields,
              ),

              const Divider(height: 32),

              // Notes
              _NotesSection(documentId: documentId),

              // AI edit trail
              _AiEditTrailSection(documentId: documentId),

              const Divider(height: 32),

              // Share links
              _ShareLinksSection(documentId: documentId),

              // Content preview
              if (doc.content != null && doc.content!.isNotEmpty) ...[
                const Divider(height: 32),
                Semantics(header: true, child: Text('Content', style: Theme.of(context).textTheme.titleSmall)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    doc.content!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 20,
                    overflow: TextOverflow.fade,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openMetadataSheet(Document doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MetadataSheet(
        correspondentId: doc.correspondent,
        documentTypeId: doc.documentType,
        tagIds: doc.tags,
        created: doc.created,
        onSave: (result) => _saveMetadata(doc, result),
      ),
    );
  }

  /// Persist only the fields the sheet actually changed, in one PATCH.
  Future<void> _saveMetadata(Document doc, MetadataSheetResult result) async {
    final patch = <String, dynamic>{};
    if (result.correspondentId != doc.correspondent) {
      patch['correspondent'] = result.correspondentId;
    }
    if (result.documentTypeId != doc.documentType) {
      patch['document_type'] = result.documentTypeId;
    }
    // A cleared date means "leave as is" here — Paperless requires created.
    if (result.created != null) {
      final newDate = result.created!.toIso8601String().split('T').first;
      final oldDate = doc.created?.toIso8601String().split('T').first;
      if (newDate != oldDate) patch['created'] = newDate;
    }
    if (!setEquals(result.tagIds.toSet(), doc.tags.toSet())) {
      patch['tags'] = result.tagIds;
    }
    if (patch.isEmpty) return;
    try {
      await ref
          .read(documentDetailProvider(documentId).notifier)
          .updateField(patch);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to update details: ${friendlyApiMessage(e)}')),
        );
      }
    }
  }

  /// Every action that isn't the app bar's primary Share, grouped by intent.
  /// Returns via [_handleAction] for the shared cases, and pushes directly
  /// for the two navigation-only actions (preview, chat).
  Future<void> _showActionsSheet(
    BuildContext context,
    WidgetRef ref,
    String title,
    bool hasChat,
  ) async {
    Widget sectionLabel(BuildContext ctx, String label) => Padding(
          padding: const EdgeInsets.fromLTRB(
              Spacing.lg, Spacing.md, Spacing.lg, Spacing.xs),
          child: Text(label, style: Theme.of(ctx).textTheme.titleSmall),
        );

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            sectionLabel(ctx, 'View'),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Preview PDF'),
              onTap: () => Navigator.pop(ctx, 'preview'),
            ),
            if (hasChat)
              ListTile(
                leading: const Icon(Icons.smart_toy_outlined),
                title: const Text('Chat about document'),
                onTap: () => Navigator.pop(ctx, 'chat'),
              ),
            ListTile(
              leading: const Icon(Icons.find_in_page_outlined),
              title: const Text('More like this'),
              onTap: () => Navigator.pop(ctx, 'more_like'),
            ),
            const Divider(height: 1),
            sectionLabel(ctx, 'Edit'),
            ListTile(
              leading: const Icon(Icons.rotate_right_outlined),
              title: const Text('Rotate'),
              onTap: () => Navigator.pop(ctx, 'rotate'),
            ),
            ListTile(
              leading: const Icon(Icons.call_split),
              title: const Text('Split document'),
              onTap: () => Navigator.pop(ctx, 'split'),
            ),
            ListTile(
              leading: const Icon(Icons.draw_outlined),
              title: const Text('Annotate'),
              onTap: () => Navigator.pop(ctx, 'annotate'),
            ),
            const Divider(height: 1),
            sectionLabel(ctx, 'Export'),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Download'),
              onTap: () => Navigator.pop(ctx, 'download'),
            ),
            ListTile(
              leading: const Icon(Icons.compress),
              title: const Text('Compress & Share'),
              onTap: () => Navigator.pop(ctx, 'compress_share'),
            ),
            ListTile(
              leading: const Icon(Icons.folder_zip_outlined),
              title: const Text('Compress & Save'),
              onTap: () => Navigator.pop(ctx, 'compress_save'),
            ),
            const Divider(height: 1),
            sectionLabel(ctx, 'Manage'),
            ListTile(
              leading: Icon(_isLocked ? Icons.lock_open : Icons.lock_outline),
              title: Text(_isLocked ? 'Remove Lock' : 'Lock Document'),
              onTap: () =>
                  Navigator.pop(ctx, _isLocked ? 'unlock_doc' : 'lock_doc'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(ctx).colorScheme.error),
              title: Text('Delete',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            const SizedBox(height: Spacing.sm),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case 'preview':
        context.push('/documents/$documentId/preview');
      case 'chat':
        context.push(
          '/documents/$documentId/chat?title=${Uri.encodeComponent(title)}',
        );
      default:
        await _handleAction(context, ref, action, title);
    }
  }

  Future<void> _showRotateChooser(BuildContext context, WidgetRef ref) async {
    final degrees = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.rotate_right),
              title: const Text('Rotate 90° CW'),
              onTap: () => Navigator.pop(ctx, 90),
            ),
            ListTile(
              leading: const Icon(Icons.rotate_90_degrees_cw),
              title: const Text('Rotate 180°'),
              onTap: () => Navigator.pop(ctx, 180),
            ),
            ListTile(
              leading: const Icon(Icons.rotate_left),
              title: const Text('Rotate 90° CCW'),
              onTap: () => Navigator.pop(ctx, 270),
            ),
          ],
        ),
      ),
    );
    if (degrees == null || !context.mounted) return;
    await _rotate(context, ref, degrees);
  }

  Future<void> _rotate(BuildContext context, WidgetRef ref, int degrees) async {
    try {
      await ref.read(paperlessApiProvider).bulkEdit(
            documents: [documentId],
            method: 'rotate',
            parameters: {'degrees': degrees},
          );
      // Re-fetch the document; its bumped `modified` cache-busts the preview
      // thumbnail URL (see the imageUrl below) so the rotated image reloads.
      ref.invalidate(documentDetailProvider(documentId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rotated $degrees°')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rotate: ${friendlyApiMessage(e)}')),
        );
      }
    }
  }

  Future<void> _handleAction(
    BuildContext context, WidgetRef ref, String action, String title,
  ) async {
    switch (action) {
      case 'lock_doc':
        await ref.read(documentLockServiceProvider).lock(documentId);
        if (mounted) setState(() => _isLocked = true);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document locked')),
          );
        }
      case 'unlock_doc':
        final authed = await _biometricService.authenticate(
          reason: 'Unlock document',
        );
        if (!authed) return;
        await ref.read(documentLockServiceProvider).unlock(documentId);
        if (mounted) setState(() => _isLocked = false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document unlocked')),
          );
        }
      case 'download':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloading...')),
        );
        try {
          final path = await ref.read(
            documentDownloadProvider(documentId, title).future,
          );
          if (!context.mounted) break;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          await saveToFolderWithFallback(
            context: context,
            ref: ref,
            localPaths: [path],
            fileNames: [
              '${sanitizeExportName(title, fallback: 'document_$documentId')}'
                  '.pdf',
            ],
          );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Download failed: ${friendlyApiMessage(e)}')),
            );
          }
        }
      case 'share':
        try {
          final path = await ref.read(
            documentDownloadProvider(documentId, title).future,
          );
          await Share.shareXFiles([XFile(path)]);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Share failed: ${friendlyApiMessage(e)}')),
            );
          }
        }
      case 'more_like':
        context.push('/search/similar/$documentId');
      case 'rotate':
        await _showRotateChooser(context, ref);
      case 'split':
        final controller = TextEditingController();
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Split document'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Page ranges',
                hintText: 'e.g. 1-3, 4-6',
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Split'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          final input = controller.text.trim();
          if (input.isEmpty) break;
          try {
            await ref.read(paperlessApiProvider).bulkEdit(
                  documents: [documentId],
                  method: 'split',
                  parameters: {'pages': input},
                );
            ref.invalidate(documentsNotifierProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document split successfully')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to split: ${friendlyApiMessage(e)}')),
              );
            }
          }
        }
      case 'annotate':
        try {
          final dir = await getTemporaryDirectory();
          final path = '${dir.path}/annotate_$documentId.pdf';
          await ref.read(paperlessApiProvider).downloadDocument(documentId, path);
          if (context.mounted) {
            context.push('/annotate', extra: {'pdfPath': path, 'title': title});
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load document: ${friendlyApiMessage(e)}')),
            );
          }
        }
      case 'compress_share':
      case 'compress_save':
        final selectedQuality = await showDialog<CompressionQuality>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('Select compression quality'),
            children: CompressionQuality.values.map((q) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, q),
              child: Text(q.label),
            )).toList(),
          ),
        );
        if (selectedQuality == null) break;
        if (!context.mounted) break;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compressing...')),
        );
        try {
          final tempPath = await ref.read(
            documentDownloadProvider(documentId, title).future,
          );
          final outputPath = await compressPdf(
            inputPath: tempPath,
            quality: selectedQuality,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            if (action == 'compress_save') {
              await saveToFolderWithFallback(
                context: context,
                ref: ref,
                localPaths: [outputPath],
                fileNames: [
                  '${sanitizeExportName(title, fallback: 'document_$documentId')}'
                      '_compressed.pdf',
                ],
              );
            } else {
              await Share.shareXFiles([XFile(outputPath)]);
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Compress failed: ${friendlyApiMessage(e)}')),
            );
          }
        }
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Move to trash?'),
            content: const Text('The document will be moved to the trash. You can restore it later.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: destructiveButtonStyle(context),
                child: const Text('Move to Trash'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          try {
            final api = ref.read(paperlessApiProvider);
            await api.trashDocuments([documentId]);
            ref.invalidate(documentsNotifierProvider);
            ref.invalidate(inboxNotifierProvider);
            if (context.mounted) context.pop();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Delete failed: ${friendlyApiMessage(e)}')),
              );
            }
          }
        }
      default:
        assert(false, 'Unhandled document detail action: $action');
    }
  }
}

class _EditableTile extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onSave;

  const _EditableTile({
    required this.label,
    required this.value,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.edit_outlined),
      title: Text(label, style: Theme.of(context).textTheme.labelSmall),
      subtitle: Text(value, style: Theme.of(context).textTheme.titleMedium),
      onTap: () async {
        final controller = TextEditingController(text: value);
        try {
          final result = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Edit $label'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(hintText: label),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, controller.text),
                  child: const Text('Save'),
                ),
              ],
            ),
          );
          if (result != null && result != value) {
            onSave(result);
          }
        } catch (_) {
          // Dialog cancelled
        }
      },
    );
  }
}

/// Read-only summary of the core metadata (correspondent, type, date, tags)
/// with a single Edit action that opens the shared [MetadataSheet].
class _MetadataSummaryCard extends StatelessWidget {
  const _MetadataSummaryCard({
    required this.correspondentName,
    required this.documentTypeName,
    required this.created,
    required this.tags,
    required this.onEdit,
  });

  final String? correspondentName;
  final String? documentTypeName;
  final DateTime? created;
  final List<Tag> tags;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);

    Widget row(IconData icon, String label, String? value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
          child: Row(
            children: [
              Icon(icon, size: 18, color: tokens.inkSoft),
              const SizedBox(width: Spacing.md),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: tokens.inkSoft)),
              const Spacer(),
              Flexible(
                child: Text(
                  value ?? 'None',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: value == null ? tokens.inkSoft : tokens.ink,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Spacing.lg, Spacing.md, Spacing.lg, Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row(Icons.person_outline, 'Correspondent', correspondentName),
            row(Icons.category_outlined, 'Type', documentTypeName),
            row(
                Icons.calendar_today_outlined,
                'Created',
                created != null
                    ? DateFormat.yMMMd().format(created!)
                    : null),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              Wrap(
                spacing: Spacing.sm - 2,
                runSpacing: Spacing.sm - 2,
                children: [for (final tag in tags) TagChip(tag: tag)],
              ),
            ],
            const SizedBox(height: Spacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomFieldsSection extends ConsumerWidget {
  final int documentId;
  final List<CustomFieldInstance> fieldInstances;

  const _CustomFieldsSection({
    required this.documentId,
    required this.fieldInstances,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(customFieldsProvider);
    final fieldDefs = fieldsAsync.valueOrNull ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Semantics(
                header: true,
                child: Text('Custom Fields',
                    style: Theme.of(context).textTheme.titleSmall)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: fieldsAsync.isLoading
                  ? null
                  : () => _showAddFieldPicker(context, ref, fieldDefs),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (fieldInstances.isEmpty && fieldDefs.isEmpty)
          Text(
            'No custom fields configured on this server',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          )
        else if (fieldInstances.isEmpty)
          Text(
            'No values set — tap + to add',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          )
        else
          ...fieldInstances.map((instance) {
            final fieldDef = fieldDefs[instance.field];
            final fieldName = fieldDef?.name ?? 'Field ${instance.field}';
            final dataType = fieldDef?.dataType ?? 'string';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CustomFieldTile(
                documentId: documentId,
                fieldName: fieldName,
                dataType: dataType,
                fieldId: instance.field,
                value: instance.value,
                extraData: fieldDef?.extraData,
                onSave: (newValue) async {
                  final updatedFields = fieldInstances.map((fi) {
                    if (fi.field == instance.field) {
                      return {'field': fi.field, 'value': newValue};
                    }
                    return {'field': fi.field, 'value': fi.value};
                  }).toList();
                  try {
                    await ref
                        .read(documentDetailProvider(documentId).notifier)
                        .updateField({'custom_fields': updatedFields});
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Failed to update field: ${friendlyApiMessage(e)}')),
                      );
                    }
                  }
                },
              ),
            );
          }),
      ],
    );
  }

  void _showAddFieldPicker(
    BuildContext context,
    WidgetRef ref,
    Map<int, CustomField> fieldDefs,
  ) {
    // Only show fields that aren't already assigned
    final assignedIds = fieldInstances.map((fi) => fi.field).toSet();
    final available = fieldDefs.values
        .where((f) => !assignedIds.contains(f.id))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All custom fields already assigned')),
      );
      return;
    }

    showModalBottomSheet<CustomField>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Add Custom Field',
                    style: Theme.of(ctx).textTheme.titleMedium),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: available
                      .map((f) => ListTile(
                            title: Text(f.name),
                            subtitle: Text(f.dataType,
                                style: Theme.of(ctx).textTheme.bodySmall),
                            onTap: () => Navigator.pop(ctx, f),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ).then((selectedField) async {
      if (selectedField == null || !context.mounted) return;
      // If the user dismisses the edit dialog without saving, nothing is persisted.
      // This is intentional — the field picker can be re-opened via '+'.
      await _editCustomFieldValue(
        context: context,
        fieldName: selectedField.name,
        dataType: selectedField.dataType,
        currentValue: null,
        extraData: selectedField.extraData,
        onSave: (newValue) async {
          final updatedFields = [
            ...fieldInstances
                .map((fi) => {'field': fi.field, 'value': fi.value}),
            {'field': selectedField.id, 'value': newValue},
          ];
          try {
            await ref
                .read(documentDetailProvider(documentId).notifier)
                .updateField({'custom_fields': updatedFields});
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to add field: ${friendlyApiMessage(e)}')),
              );
            }
          }
        },
      );
    });
  }
}

/// Returns a display string for a custom field value.
/// Package-visible so tests can call it directly.
String displayCustomFieldValue(dynamic val, String type,
    {Map<String, dynamic>? extraData}) {
  if (val == null) return 'Not set';
  if (type == 'boolean') return val == true ? 'Yes' : 'No';
  if (type == 'date' && val is String && val.isNotEmpty) {
    try {
      return DateFormat.yMMMd().format(DateTime.parse(val));
    } catch (_) {
      return val;
    }
  }
  if (type == 'monetary') return '\$${val.toString()}';
  if (type == 'select') {
    final options = extraData?['select_options'] as List<dynamic>? ?? [];
    return _displaySelectValue(val, options);
  }
  return val.toString();
}

String _displaySelectValue(dynamic val, List<dynamic> options) {
  if (val == null) return 'Not set';
  for (final opt in options) {
    if (opt is Map) {
      if (opt['id'] == val || opt['id'].toString() == val.toString()) {
        return opt['label']?.toString() ?? opt['id']?.toString() ?? '';
      }
    } else if (opt.toString() == val.toString()) {
      return opt.toString();
    }
  }
  return val.toString();
}

/// Core editing logic for a single custom field. Used by both _CustomFieldTile
/// (via its onTap) and _showAddFieldPicker (for newly added fields).
Future<void> _editCustomFieldValue({
  required BuildContext context,
  required String fieldName,
  required String dataType,
  required dynamic currentValue,
  required Map<String, dynamic>? extraData,
  required ValueChanged<dynamic> onSave,
}) async {
  switch (dataType) {
    case 'boolean':
      onSave(currentValue != true);
    case 'date':
      final current = currentValue is String && currentValue.toString().isNotEmpty
          ? DateTime.tryParse(currentValue.toString())
          : null;
      final picked = await showDatePicker(
        context: context,
        initialDate: current ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now().add(const Duration(days: 3650)),
      );
      if (picked != null) {
        onSave(picked.toIso8601String().split('T').first);
      }
    case 'integer':
      await _editCustomFieldText(context, fieldName, currentValue, TextInputType.number, onSave, dataType);
    case 'float' || 'monetary':
      await _editCustomFieldText(context, fieldName, currentValue, const TextInputType.numberWithOptions(decimal: true), onSave, dataType);
    case 'url':
      await _editCustomFieldText(context, fieldName, currentValue, TextInputType.url, onSave, dataType);
    case 'select':
      await _editCustomFieldSelect(context, fieldName, currentValue, extraData, onSave);
    default:
      await _editCustomFieldText(context, fieldName, currentValue, TextInputType.text, onSave, dataType);
  }
}

Future<void> _editCustomFieldText(
  BuildContext context,
  String fieldName,
  dynamic currentValue,
  TextInputType keyboardType,
  ValueChanged<dynamic> onSave,
  String dataType,
) async {
  final controller = TextEditingController(text: currentValue?.toString() ?? '');
  try {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $fieldName'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: fieldName),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      if (dataType == 'integer') {
        onSave(int.tryParse(result));
      } else if (dataType == 'float' || dataType == 'monetary') {
        onSave(double.tryParse(result));
      } else {
        onSave(result.isEmpty ? null : result);
      }
    }
  } catch (_) {
    // Dialog cancelled
  }
}

Future<void> _editCustomFieldSelect(
  BuildContext context,
  String fieldName,
  dynamic currentValue,
  Map<String, dynamic>? extraData,
  ValueChanged<dynamic> onSave,
) async {
  const selectNone = '__none__';
  final options = extraData?['select_options'] as List<dynamic>? ?? [];
  if (options.isEmpty) {
    await _editCustomFieldText(context, fieldName, currentValue, TextInputType.text, onSave, 'string');
    return;
  }
  final result = await showModalBottomSheet<dynamic>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(fieldName, style: Theme.of(ctx).textTheme.titleMedium),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: const Text('None'),
                    trailing: currentValue == null ? const Icon(Icons.check) : null,
                    onTap: () => Navigator.pop(ctx, selectNone),
                  ),
                  ...options.map((opt) {
                    final id = opt is Map ? opt['id'] : opt;
                    final label = opt is Map
                        ? (opt['label']?.toString() ?? opt['id']?.toString() ?? '')
                        : opt.toString();
                    final isSelected = id == currentValue ||
                        id.toString() == currentValue.toString();
                    return ListTile(
                      title: Text(label),
                      trailing: isSelected ? const Icon(Icons.check) : null,
                      onTap: () => Navigator.pop(ctx, id),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
  if (result == null) return;
  onSave(result == selectNone ? null : result);
}

class _CustomFieldTile extends StatelessWidget {
  final int documentId;
  final String fieldName;
  final String dataType;
  final int fieldId;
  final dynamic value;
  final Map<String, dynamic>? extraData;
  final ValueChanged<dynamic> onSave;

  const _CustomFieldTile({
    required this.documentId,
    required this.fieldName,
    required this.dataType,
    required this.fieldId,
    required this.value,
    this.extraData,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(_iconForType(dataType)),
      title: Text(fieldName, style: Theme.of(context).textTheme.labelSmall),
      subtitle: Text(
        displayCustomFieldValue(value, dataType, extraData: extraData),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      onTap: () => _editField(context),
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'string' => Icons.text_fields,
      'url' => Icons.link,
      'date' => Icons.calendar_today,
      'boolean' => Icons.toggle_on_outlined,
      'integer' || 'float' => Icons.numbers,
      'monetary' => Icons.attach_money,
      'documentlink' => Icons.description,
      _ => Icons.extension,
    };
  }

  Future<void> _editField(BuildContext context) => _editCustomFieldValue(
    context: context,
    fieldName: fieldName,
    dataType: dataType,
    currentValue: value,
    extraData: extraData,
    onSave: onSave,
  );
}

class _NotesSection extends ConsumerWidget {
  final int documentId;
  const _NotesSection({required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(documentNotesProvider(documentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Semantics(header: true, child: Text('Notes', style: Theme.of(context).textTheme.titleSmall)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => _addNote(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 8),
        notesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Failed to load notes: ${friendlyApiMessage(err)}'),
          data: (notes) {
            if (notes.isEmpty) {
              return Text(
                'No notes yet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            }
            return Column(
              children: notes.map((note) => Card(
                child: ListTile(
                  title: Text(note.note),
                  subtitle: Text(DateFormat.yMMMd().add_Hm().format(note.created)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () async {
                      try {
                        await ref.read(documentNotesProvider(documentId).notifier)
                            .deleteNote(note.id);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to delete note: ${friendlyApiMessage(e)}')),
                          );
                        }
                      }
                    },
                  ),
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  void _addNote(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Enter note...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(ctx, text.isNotEmpty ? text : null);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((noteText) {
      if (noteText != null && context.mounted) {
        ref.read(documentNotesProvider(documentId).notifier)
            .addNote(noteText)
            .catchError((e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to add note: ${friendlyApiMessage(e)}')),
            );
          }
        });
      }
    });
  }
}

class _ShareLinksSection extends ConsumerStatefulWidget {
  final int documentId;
  const _ShareLinksSection({required this.documentId});

  @override
  ConsumerState<_ShareLinksSection> createState() => _ShareLinksSectionState();
}

class _ShareLinksSectionState extends ConsumerState<_ShareLinksSection> {
  List<Map<String, dynamic>>? _links;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    try {
      final api = ref.read(paperlessApiProvider);
      final links = await api.getShareLinks(widget.documentId);
      if (mounted) setState(() { _links = links; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _links = []; _loading = false; });
    }
  }

  Future<void> _createLink() async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.createShareLink(documentId: widget.documentId);
      await _loadLinks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share link created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create link: ${friendlyApiMessage(e)}')),
        );
      }
    }
  }

  Future<void> _deleteLink(int linkId) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.deleteShareLink(linkId);
      await _loadLinks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share link deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete link: ${friendlyApiMessage(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Semantics(header: true, child: Text('Share Links', style: Theme.of(context).textTheme.titleSmall)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_link, size: 20),
              tooltip: 'Add share link',
              onPressed: _createLink,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_links == null || _links!.isEmpty)
          Text(
            'No share links',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...(_links!.map((link) {
            final slug = link['slug'] as String? ?? '';
            final api = ref.watch(paperlessApiProvider);
            final linkUrl = '${api.baseUrl}share/$slug';
            final expiration = link['expiration'] as String?;
            final linkId = link['id'] as int;

            return Card(
              child: ListTile(
                leading: const Icon(Icons.link, size: 20),
                title: Text(linkUrl,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                subtitle: expiration != null
                    ? Text('Expires: $expiration',
                        style: const TextStyle(fontSize: 11))
                    : const Text('No expiration',
                        style: TextStyle(fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Delete link',
                  onPressed: () => _deleteLink(linkId),
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: linkUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard')),
                  );
                },
              ),
            );
          })),
      ],
    );
  }
}

class _AiEditTrailSection extends ConsumerWidget {
  final int documentId;
  const _AiEditTrailSection({required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trailAsync = ref.watch(aiEditTrailProvider(documentId));
    return trailAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, __) {
        debugPrint('AiEditTrailSection error: $e');
        return const SizedBox.shrink();
      },
      data: (edits) {
        if (edits.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 32),
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Semantics(
                  header: true,
                  child: Text(
                    'AI Applied at Upload',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...edits.map(
              (edit) => _AiEditRow(documentId: documentId, edit: edit),
            ),
          ],
        );
      },
    );
  }
}

class _AiEditRow extends ConsumerWidget {
  final int documentId;
  final AiEditEntry edit;
  const _AiEditRow({required this.documentId, required this.edit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.auto_awesome,
        size: 16,
        color: Theme.of(context).colorScheme.tertiary,
      ),
      title: Text(
        _fieldLabel(edit.fieldName),
        style: Theme.of(context).textTheme.labelMedium,
      ),
      subtitle: edit.newValue != null
          ? Text(
              edit.newValue!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : Text(
              'Cleared',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        tooltip: 'Remove from history',
        onPressed: () {
          ref
              .read(aiEditTrailProvider(documentId).notifier)
              .deleteEdit(edit.id)
              .catchError((Object e) {
                debugPrint('Failed to delete AI edit: $e');
              });
        },
      ),
    );
  }

  String _fieldLabel(String fieldName) {
    return switch (fieldName) {
      'title' => 'Title',
      'correspondent' => 'Correspondent',
      'document_type' => 'Document Type',
      'tags' => 'Tags',
      'created' => 'Created Date',
      _ => fieldName
              .split('_')
              .map((w) => w.isEmpty
                  ? ''
                  : '${w[0].toUpperCase()}${w.substring(1)}')
              .join(' '),
    };
  }
}
