import 'document_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_error_mapper.dart';
import '../../core/design_tokens.dart';
import 'processing/presets.dart';
import 'providers/selected_preset_provider.dart';

/// Camera-first capture hub: one large primary "Scan document" action, a preset
/// strip that seeds the whole pipeline, and quiet secondary entry points.
class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppTokens.of(context);
    final selectedPreset = ref.watch(selectedPresetProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Spacing.xl, Spacing.lg, Spacing.xl, Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add a document',
                            style: Theme.of(context).textTheme.headlineMedium),
                        Text(
                          'Capture, confirm, upload',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: tokens.inkSoft),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Settings',
                    iconSize: 26,
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),

              const Spacer(),

              // Preset strip — seeds the enhance default for the whole pipeline.
              Text(
                'ENHANCEMENT',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: tokens.inkSoft,
                      letterSpacing: 1.2,
                    ),
              ),
              const SizedBox(height: Spacing.sm),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ProcessingPreset.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: Spacing.sm),
                  itemBuilder: (_, i) {
                    final preset = ProcessingPreset.values[i];
                    return ChoiceChip(
                      label: Text(preset.label),
                      selected: preset == selectedPreset,
                      tooltip: preset.description,
                      onSelected: (_) => ref
                          .read(selectedPresetProvider.notifier)
                          .select(preset)
                          .catchError((Object _) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Couldn't save that enhancement "
                                'preset. Please try again.'),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),

              const SizedBox(height: Spacing.lg),

              // Hero primary action.
              _ScanHero(onTap: () => _startScan(context)),

              const SizedBox(height: Spacing.lg),

              // Quiet secondary actions.
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _startBatchScan(context),
                      icon: const Icon(Icons.burst_mode_outlined, size: 18),
                      label: const Text('Batch scan'),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickFile(context),
                      icon: const Icon(Icons.upload_file_outlined, size: 18),
                      label: const Text('Upload file'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startScan(BuildContext context) async {
    try {
      final images = await DocumentScanner.getPictures(
        isGalleryImportAllowed: true,
      );
      if (images != null && images.isNotEmpty && context.mounted) {
        context.push('/scan/review', extra: images);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanner error: ${friendlyApiMessage(e)}')),
        );
      }
    }
  }

  Future<void> _startBatchScan(BuildContext context) async {
    try {
      final images = await DocumentScanner.getPictures(
        isGalleryImportAllowed: false,
      );
      if (images != null && images.isNotEmpty && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scanned ${images.length} ${images.length == 1 ? 'page' : 'pages'}'),
            duration: const Duration(seconds: 2),
          ),
        );
        context.push('/scan/review', extra: images);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanner error: ${friendlyApiMessage(e)}')),
        );
      }
    }
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'tiff', 'webp'],
      );
      if (result != null && result.files.single.path != null && context.mounted) {
        final file = result.files.single;
        context.push('/scan/upload', extra: {
          'filePath': file.path!,
          'filename': file.name,
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picker error: ${friendlyApiMessage(e)}')),
        );
      }
    }
  }
}

/// The single large accent-filled capture action.
class _ScanHero extends StatelessWidget {
  const _ScanHero({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final onFill = tokens.onAccent;

    return Material(
      color: tokens.accentFill,
      borderRadius: BorderRadius.circular(Radii.lg),
      child: Semantics(
        label: 'Scan document',
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.xl, vertical: Spacing.xxl),
            child: Column(
              children: [
                Icon(Icons.center_focus_strong_outlined,
                    size: 56, color: onFill),
                const SizedBox(height: Spacing.md),
                Text(
                  'Scan document',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: onFill),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Camera or gallery import',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: onFill.withValues(alpha: 0.8),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
