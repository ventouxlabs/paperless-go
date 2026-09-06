import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';

/// Where the app lands after login, on a `/` deep link, and when a shared
/// file needs a real screen to sit on while it is routed.
///
/// Inbox used to be hard-wired here. It is the highest-frequency workflow
/// for someone who sorts every day, but for everyone else it is a triage
/// queue you did not ask for, and sharing a file into the app also had to
/// pass through it. Library is the neutral default.
enum StartScreen {
  library('/documents', 'Library'),
  inbox('/inbox', 'Inbox');

  const StartScreen(this.route, this.label);

  /// The shell route this screen lives at.
  final String route;

  /// User-facing name, for the Settings row.
  final String label;

  static const StartScreen fallback = StartScreen.library;

  /// Parses a stored [name]; anything unknown (including null) is the
  /// default, so a removed value can never strand the router.
  static StartScreen parse(String? name) => StartScreen.values.firstWhere(
        (s) => s.name == name,
        orElse: () => fallback,
      );
}

// Hand-written rather than @riverpod: code generation cannot run on this
// toolchain (see export_destination_providers.dart).
//
// Async, unlike the theme notifier: the router has to *await* the real
// value before it resolves `/`, or a cold start would flash the default
// screen and then hop to the chosen one once the keystore read landed.
final startScreenProvider =
    AsyncNotifierProvider<StartScreenNotifier, StartScreen>(
  StartScreenNotifier.new,
);

class StartScreenNotifier extends AsyncNotifier<StartScreen> {
  /// Never errors. The router awaits this to resolve `/`; a keystore that
  /// cannot be read (backup restore, invalidated key) must degrade to the
  /// default screen, not to a blank one with no way to reach login.
  @override
  Future<StartScreen> build() async {
    try {
      final stored = await ref.watch(secureStorageProvider).getStartScreen();
      return StartScreen.parse(stored);
    } on Exception catch (e) {
      debugPrint('Start screen could not be read, using default: $e');
      return StartScreen.fallback;
    }
  }

  /// Applies the choice now and persists it; a failed write keeps the
  /// in-session choice and is logged rather than surfaced.
  Future<void> set(StartScreen screen) async {
    state = AsyncData(screen);
    try {
      await ref.read(secureStorageProvider).saveStartScreen(screen.name);
    } on Exception catch (e) {
      debugPrint('Start screen could not be saved: $e');
    }
  }
}
