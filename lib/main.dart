import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/settings/start_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  final container = ProviderContainer();
  // Read the start-screen choice before the first frame so the router's
  // initial redirect resolves synchronously: an async first redirect leaves
  // frame one without a Navigator, which is exactly when a cold-start share
  // arrives looking for one.
  await container.read(startScreenProvider.future);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PaperlessGoApp(),
    ),
  );
}
