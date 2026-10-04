import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Shorthand for the app's translated strings: `context.l10n.settingsTitle`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
