import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../core/services/export_destination_providers.dart';
import '../core/services/export_destination_service.dart';

/// A file ready to be saved: where it is on disk and what to call it.
typedef ExportFile = ({String path, String name});

/// Produces the files to save, on demand. Called only once a destination is
/// settled, so a cancelled prompt never costs a download.
typedef ProduceExportFiles = Future<List<ExportFile>> Function();

/// Hands files to the system share sheet. Injectable so tests can observe it.
typedef ShareFiles = Future<void> Function(List<ExportFile> files, String mime);

/// What happened to a "Save to folder" request.
class SaveToFolderResult {
  final int saved;
  final int failed;

  /// The user chose the share sheet over picking a folder.
  final bool sharedInstead;

  const SaveToFolderResult({
    this.saved = 0,
    this.failed = 0,
    this.sharedInstead = false,
  });

  /// The user backed out before any file was produced or written.
  static const cancelled = SaveToFolderResult();

  /// True when at least one file left the device, by folder write or by the
  /// share sheet. Drives whether a bulk selection counts as spent.
  bool get didExport => saved > 0;
}

/// What the user chose when asked to resolve a missing download folder.
enum _MissingFolderChoice { choose, share, cancel }

/// The outcome of settling a destination before any work is done.
sealed class _Destination {
  const _Destination();
}

final class _UseFolder extends _Destination {
  final ExportDestination destination;
  const _UseFolder(this.destination);
}

final class _ShareInstead extends _Destination {
  const _ShareInstead();
}

final class _Cancelled extends _Destination {
  const _Cancelled();
}

Future<void> _shareWithSystem(List<ExportFile> files, String mime) =>
    Share.shareXFiles(
      files.map((f) => XFile(f.path, mimeType: mime, name: f.name)).toList(),
    );

/// Makes sure a usable download folder exists, prompting if it does not.
///
/// [context] is only used for the prompt and is re-checked before every use;
/// the picker can background the app indefinitely and the host widget may be
/// gone by the time it returns. A folder chosen in that window is still
/// persisted and returned — a save the user asked for is never dropped just
/// because the screen went away.
///
/// [forcePrompt] skips the "grant still listed" shortcut. A write that just
/// failed with a folder problem is stronger evidence than the grant table:
/// a deleted tree can keep its persisted grant, so re-resolving would hand
/// back the same dead folder and the user would never be asked.
Future<_Destination> _ensureDestination(
  BuildContext context,
  WidgetRef ref,
  ExportDestinationService service, {
  bool forcePrompt = false,
}) async {
  final current = await service.resolve();
  if (current.isReady && !forcePrompt) return _UseFolder(current);

  if (!context.mounted) return const _Cancelled();
  final neverChosen = current.status == DestinationStatus.unset;
  final choice = await showDialog<_MissingFolderChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        neverChosen ? 'Choose a download folder' : 'Download folder unavailable',
      ),
      content: Text(
        neverChosen
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
      return const _Cancelled();
    case _MissingFolderChoice.share:
      return const _ShareInstead();
    case _MissingFolderChoice.choose:
      final chosen = await service.chooseFolder();
      if (chosen == null) return const _Cancelled();
      // A WidgetRef must not be touched once its element is gone; the
      // provider auto-disposes and re-resolves on its own in that case.
      if (context.mounted) ref.invalidate(downloadsDestinationProvider);
      return _UseFolder(chosen);
  }
}

/// Saves files into the user's chosen folder, prompting for that folder
/// first if it is missing or its grant was revoked.
///
/// Order matters: the destination is settled *before* [produceFiles] runs, so
/// a cancelled prompt costs nothing and the files are not left sitting in the
/// cache across an unbounded picker round-trip. Falls back to the share sheet
/// only if the user asks for it. If the grant vanishes mid-batch the user is
/// asked to re-pick once and the remaining files are retried.
///
/// Throws whatever [produceFiles] throws (typically a download failure) so
/// the call site can report it in its own words.
Future<SaveToFolderResult> saveToFolderWithFallback({
  required BuildContext context,
  required WidgetRef ref,
  required ProduceExportFiles produceFiles,
  String mimeType = 'application/pdf',
  ShareFiles shareFiles = _shareWithSystem,
}) async {
  // Everything that needs the widget is bound here, before the first await:
  // the service outlives any screen, and each closure re-checks `mounted`
  // at the moment it runs, so the write itself never depends on the host.
  final service = ref.read(exportDestinationServiceProvider);
  void toast(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<_Destination> prompt({bool force = false}) =>
      _ensureDestination(context, ref, service, forcePrompt: force);

  final _Destination settled;
  try {
    settled = await prompt();
  } on ExportSaveException catch (e) {
    toast(e.message);
    return SaveToFolderResult.cancelled;
  }

  switch (settled) {
    case _Cancelled():
      return SaveToFolderResult.cancelled;
    case _ShareInstead():
      final files = await produceFiles();
      if (files.isNotEmpty) await shareFiles(files, mimeType);
      return SaveToFolderResult(sharedInstead: true, saved: files.length);
    case _UseFolder(:final destination):
      final files = await produceFiles();
      if (files.isEmpty) return SaveToFolderResult.cancelled;
      return _writeAll(
        service: service,
        destination: destination,
        files: files,
        mimeType: mimeType,
        shareFiles: shareFiles,
        reprompt: () => prompt(force: true),
        toast: toast,
      );
  }
}

Future<SaveToFolderResult> _writeAll({
  required ExportDestinationService service,
  required ExportDestination destination,
  required List<ExportFile> files,
  required String mimeType,
  required ShareFiles shareFiles,
  required Future<_Destination> Function() reprompt,
  required void Function(String) toast,
}) async {
  var target = destination;
  var reselected = false;
  final saved = <String>[];
  final failed = <String>[];
  var lastError = '';

  void summarize() {
    final message = saveSummaryMessage(
      saved: saved,
      failedCount: failed.length,
      lastError: lastError,
      folder: target.displayName,
    );
    if (message != null) toast(message);
  }

  var i = 0;
  while (i < files.length) {
    final file = files[i];
    try {
      saved.add(
        await service.saveToDestination(
          localPath: file.path,
          fileName: file.name,
          mimeType: mimeType,
          known: target,
        ),
      );
      i++;
    } on ExportSaveException catch (e) {
      if (e.needsReselect && !reselected) {
        // The folder itself went away mid-batch. Ask once, then retry this
        // file and the rest against whatever the user picks.
        reselected = true;
        _Destination again;
        try {
          again = await reprompt();
        } on ExportSaveException catch (promptError) {
          // The picker itself failed; say so in its own words rather than
          // letting it escape to a call site that would flatten it.
          toast(promptError.message);
          again = const _Cancelled();
        }
        switch (again) {
          case _UseFolder(:final destination):
            target = destination;
            continue;
          case _ShareInstead():
            final rest = files.sublist(i);
            await shareFiles(rest, mimeType);
            summarize();
            return SaveToFolderResult(
              saved: saved.length + rest.length,
              failed: failed.length,
              sharedInstead: true,
            );
          case _Cancelled():
            // No folder to retry against: the rest cannot land anywhere.
            failed.addAll(files.sublist(i).map((f) => f.name));
            lastError = e.message;
            i = files.length;
            continue;
        }
      }
      failed.add(file.name);
      lastError = e.message;
      i++;
    }
  }

  summarize();
  return SaveToFolderResult(saved: saved.length, failed: failed.length);
}

/// The one-line outcome shown after a batch. Null when nothing happened.
@visibleForTesting
String? saveSummaryMessage({
  required List<String> saved,
  required int failedCount,
  required String lastError,
  required String folder,
}) =>
    switch ((saved.length, failedCount)) {
      (0, 0) => null,
      (0, _) => 'Could not save to $folder: $lastError',
      (1, 0) => 'Saved ${saved.first} to $folder',
      (final n, 0) => 'Saved $n files to $folder',
      (final n, final f) => 'Saved $n to $folder, $f failed',
    };
