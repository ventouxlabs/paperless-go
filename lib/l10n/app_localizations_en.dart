// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonUsername => 'Username';

  @override
  String get commonPassword => 'Password';

  @override
  String get loginSubtitle => 'Connect to your Paperless-ngx server';

  @override
  String get loginServerUrlLabel => 'Server URL';

  @override
  String get loginTestConnectionTooltip => 'Test connection';

  @override
  String get loginServerUrlRequired => 'Enter your server URL';

  @override
  String get loginServerUrlSchemeRequired =>
      'URL must start with https:// or http://';

  @override
  String get loginServerUrlHttpBlocked =>
      'This app requires https:// — plain http:// connections are blocked. Put your server behind a reverse proxy or Tailscale Serve for a valid HTTPS address.';

  @override
  String get loginServerUrlInvalid => 'Enter a valid URL';

  @override
  String get loginHttpWarning =>
      'http:// is blocked by this app — use https:// instead';

  @override
  String get loginUseApiToken => 'Login with API token';

  @override
  String get loginApiTokenLabel => 'API Token';

  @override
  String get loginApiTokenRequired => 'Enter your API token';

  @override
  String get loginUsernameRequired => 'Enter your username';

  @override
  String get loginPasswordRequired => 'Enter your password';

  @override
  String get loginSubmit => 'Login';

  @override
  String loginConnectionError(String message) {
    return 'Connection error: $message';
  }

  @override
  String get lockSubtitle => 'Authenticate to continue';

  @override
  String get lockUnlock => 'Unlock';
}
