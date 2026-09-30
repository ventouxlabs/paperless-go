import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../processing/presets.dart';

/// The enhancement preset chosen on the scanner hub.
///
/// Carried from the scanner screen through the review → enhance pipeline so the
/// happy-path "Continue" and the "Adjust" enhance screen both default to the
/// user's pick. Remembered across scanner sessions and app restarts —
/// including "None" — so a user who doesn't want enhancement isn't reset to
/// Auto on every batch (#42). Hand-written (no codegen): build_runner is
/// unavailable here.
final selectedPresetProvider =
    NotifierProvider<SelectedPresetNotifier, ProcessingPreset>(
  SelectedPresetNotifier.new,
);

class SelectedPresetNotifier extends Notifier<ProcessingPreset> {
  bool _userChanged = false;

  @override
  ProcessingPreset build() {
    _userChanged = false;
    _load();
    return ProcessingPreset.auto;
  }

  Future<void> _load() async {
    final stored = await ref.read(secureStorageProvider).getScannerPreset();
    // A pick made while the read was in flight wins over the stored value.
    if (_userChanged || stored == null) return;
    state = ProcessingPreset.values.firstWhere(
      (p) => p.name == stored,
      orElse: () => ProcessingPreset.auto,
    );
  }

  /// Makes [preset] the default for this and future scanner sessions.
  ///
  /// Saves first, like the other settings notifiers: if the write fails the
  /// chip keeps showing the previous preset rather than a choice that would
  /// silently revert on restart. The failure is rethrown for the caller.
  Future<void> select(ProcessingPreset preset) async {
    _userChanged = true;
    await ref.read(secureStorageProvider).saveScannerPreset(preset.name);
    state = preset;
  }
}
