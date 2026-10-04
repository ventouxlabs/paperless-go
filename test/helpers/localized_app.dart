import 'package:flutter/material.dart';
import 'package:paperless_go/l10n/app_localizations.dart';

/// A [MaterialApp] with the app's localization delegates, pinned to English.
///
/// Use it instead of a bare `MaterialApp` for any widget that reads
/// `AppLocalizations.of(context)` (or `context.l10n`): without the delegates
/// that call throws. The locale is fixed so tests, goldens included, render
/// the same English strings whatever the machine's language.
MaterialApp localizedApp({
  required Widget home,
  ThemeData? theme,
  bool debugShowCheckedModeBanner = true,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: debugShowCheckedModeBanner,
    theme: theme,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

/// [localizedApp] for tests that drive the real router.
MaterialApp localizedRouterApp({required RouterConfig<Object> routerConfig}) {
  return MaterialApp.router(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: routerConfig,
  );
}
