import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/services/user_trust_store.dart';
import 'core/settings/start_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  // Dart's HttpClient ignores CAs the user installed on the device; load them
  // before anything can open a connection (dio, thumbnails, PDF preview).
  // install() bounds its own keystore read, so a wedged keystore can't hold
  // the native splash.
  await UserTrustStore.install();
  final container = ProviderContainer();
  // Read the start-screen choice before the first frame so the router's
  // initial redirect resolves synchronously: an async first redirect leaves
  // frame one without a Navigator, which is exactly when a cold-start share
  // arrives looking for one.
  // Bounded: a wedged keystore must not hold the native splash forever.
  // On timeout the router falls back to its async path once the read
  // lands, which is the pre-existing behaviour, not a regression.
  await container
      .read(startScreenProvider.future)
      .timeout(const Duration(seconds: 2), onTimeout: () => StartScreen.fallback);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PaperlessGoApp(),
    ),
  );
}
