import 'package:flutter_riverpod/flutter_riverpod.dart';

// Cyclic with auth_provider.dart on purpose: it needs secureStorageProvider
// from there, and logout() there needs exportDestinationServiceProvider from
// here. Lazy top-level finals on both sides, so no init-order hazard.
import '../auth/auth_provider.dart';
import 'export_destination_service.dart';

// Hand-written rather than @riverpod: code generation cannot run on this
// toolchain (the pinned analyzer rejects Dart 3.13 syntax, so build_runner
// deletes every generated file and then fails). Convert back to @riverpod once
// the analyzer/SDK mismatch is resolved.
final exportDestinationServiceProvider = Provider<ExportDestinationService>(
  (ref) => ExportDestinationService(storage: ref.watch(secureStorageProvider)),
);

/// The downloads folder, re-validated against live OS grants on every read.
///
/// Async because a stored URI is only a hint — the grant it refers to can be
/// revoked at any time, so the value has to be checked before it can be shown
/// or used. Auto-disposing on purpose: this feeds the UI only (the save path
/// re-resolves for itself), so letting it rebuild means a reopened Settings
/// screen always shows the truth.
final downloadsDestinationProvider = AsyncNotifierProvider.autoDispose<
    DownloadsDestination, ExportDestination>(DownloadsDestination.new);

class DownloadsDestination
    extends AutoDisposeAsyncNotifier<ExportDestination> {
  @override
  Future<ExportDestination> build() =>
      ref.watch(exportDestinationServiceProvider).resolve();

  /// Prompts for a folder. Returns true if one was chosen and persisted.
  Future<bool> choose() async {
    final service = ref.read(exportDestinationServiceProvider);
    final chosen = await service.chooseFolder();
    if (chosen == null) return false;
    state = AsyncData(chosen);
    return true;
  }

  Future<void> clear() async {
    await ref.read(exportDestinationServiceProvider).forget();
    state = const AsyncData(ExportDestination.unset());
  }
}
