import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../core/auth/auth_provider.dart';
import '../core/services/export_destination_service.dart';

/// What the user chose when asked to resolve a missing download folder.
enum _MissingFolderChoice { choose, share, cancel }

/// Makes sure a usable download folder exists, prompting if it does not.
///
/// Returns the destination, or null when the user backed out or asked to share
/// instead — a save the user explicitly requested is never dropped silently.
Future<ExportDestination?> _ensureDestination(
  BuildContext context,
  WidgetRef ref, {
  required bool offerShareFallback,
  required VoidCallback onShareInstead,
}) async {
  final service = ref.read(exportDestinationServiceProvider);
  final current = await service.resolve();
  if (current.isReady) return current;

  if (!context.mounted) return null;
  final choice = await showDialog<_MissingFolderChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        current.status == DestinationStatus.unset
            ? 'Choose a download folder'
            : 'Download folder unavailable',
      ),
      content: Text(
        current.status == DestinationStatus.unset
            ? 'Pick a folder to save files into. It will be remembered for '
                'next time.'
            : 'Access to "${current.displayName}" was revoked or the folder '
                'was removed. Pick a folder again.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, _MissingFolderChoice.cancel),
          child: const Text('Cancel'),
        ),
        if (offerShareFallback)
          TextButton(
            onPressed: () => Navigator.pop(ctx, _MissingFolderChoice.share),
            child: const Text('Share instead'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, _MissingFolderChoice.choose),
          child: const Text('Choose folder'),
        ),
      ],
    ),
  );

  switch (choice) {
    case null:
    case _MissingFolderChoice.cancel:
      return null;
    case _MissingFolderChoice.share:
      onShareInstead();
      return null;
    case _MissingFolderChoice.choose:
      final chosen = await service.chooseFolder();
      ref.invalidate(downloadsDestinationProvider);
      return chosen;
  }
}

/// Saves an already-downloaded local file into the user's chosen folder,
/// prompting for that folder if it is missing or its grant was revoked.
///
/// [localPaths] must already exist on disk; SAF copies from a real file.
/// Falls back to the share sheet only if the user asks for it.
Future<void> saveToFolderWithFallback({
  required BuildContext context,
  required WidgetRef ref,
  required List<String> localPaths,
  required List<String> fileNames,
  String mimeType = 'application/pdf',
}) async {
  assert(localPaths.length == fileNames.length);
  if (localPaths.isEmpty) return;

  var sharedInstead = false;
  final ExportDestination? destination;
  try {
    destination = await _ensureDestination(
      context,
      ref,
      offerShareFallback: true,
      onShareInstead: () => sharedInstead = true,
    );
  } on ExportSaveException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
    return;
  }

  if (sharedInstead) {
    await Share.shareXFiles(
      localPaths.map((p) => XFile(p, mimeType: mimeType)).toList(),
    );
    return;
  }
  if (destination == null) return;

  final service = ref.read(exportDestinationServiceProvider);
  final savedNames = <String>[];
  final failures = <String>[];
  var lastError = '';

  for (var i = 0; i < localPaths.length; i++) {
    try {
      savedNames.add(
        await service.saveToDestination(
          localPath: localPaths[i],
          fileName: fileNames[i],
          mimeType: mimeType,
          known: destination,
        ),
      );
    } on ExportSaveException catch (e) {
      failures.add(fileNames[i]);
      lastError = e.message;
    }
  }

  if (!context.mounted) return;
  final folder = destination.displayName;
  final message = switch ((savedNames.length, failures.length)) {
    (0, _) => 'Could not save to $folder: $lastError',
    (1, 0) => 'Saved ${savedNames.first} to $folder',
    (final n, 0) => 'Saved $n files to $folder',
    (final n, final f) => 'Saved $n to $folder, $f failed',
  };
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}
