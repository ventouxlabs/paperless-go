import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Button that dismisses a dialog without applying anything.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Button that confirms and saves the value entered in a dialog.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Label of a username text field.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get commonUsername;

  /// Label of a password text field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPassword;

  /// Subtitle under the app name on the login screen. Paperless-ngx is a product name.
  ///
  /// In en, this message translates to:
  /// **'Connect to your Paperless-ngx server'**
  String get loginSubtitle;

  /// Label of the login field where the user types the address of their Paperless-ngx server.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get loginServerUrlLabel;

  /// Tooltip of the button next to the server URL that checks the server can be reached.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get loginTestConnectionTooltip;

  /// Validation error when the server URL field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your server URL'**
  String get loginServerUrlRequired;

  /// Validation error when the server URL has no scheme. Keep https:// and http:// as is.
  ///
  /// In en, this message translates to:
  /// **'URL must start with https:// or http://'**
  String get loginServerUrlSchemeRequired;

  /// Validation error when the server URL uses plain http://. Tailscale Serve is a product name.
  ///
  /// In en, this message translates to:
  /// **'This app requires https:// — plain http:// connections are blocked. Put your server behind a reverse proxy or Tailscale Serve for a valid HTTPS address.'**
  String get loginServerUrlHttpBlocked;

  /// Validation error when the server URL cannot be parsed.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid URL'**
  String get loginServerUrlInvalid;

  /// Inline warning shown under the server URL as soon as it starts with http://.
  ///
  /// In en, this message translates to:
  /// **'http:// is blocked by this app — use https:// instead'**
  String get loginHttpWarning;

  /// Switch that replaces the username/password fields with an API token field.
  ///
  /// In en, this message translates to:
  /// **'Login with API token'**
  String get loginUseApiToken;

  /// Label of the field where the user pastes their Paperless-ngx API token.
  ///
  /// In en, this message translates to:
  /// **'API Token'**
  String get loginApiTokenLabel;

  /// Validation error when the API token field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your API token'**
  String get loginApiTokenRequired;

  /// Validation error when the username field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get loginUsernameRequired;

  /// Validation error when the password field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get loginPasswordRequired;

  /// Button that logs in to the server.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginSubmit;

  /// Snackbar shown when logging in fails for a reason other than bad credentials.
  ///
  /// In en, this message translates to:
  /// **'Connection error: {message}'**
  String loginConnectionError(String message);

  /// Text on the biometric lock screen shown when the app is opened.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to continue'**
  String get lockSubtitle;

  /// Button on the lock screen that starts biometric authentication again.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lockUnlock;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
