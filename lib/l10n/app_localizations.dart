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

  /// Title of the settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section heading: server, profiles and sign out.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// Settings section heading: theme and start screen.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// Settings section heading: biometric lock.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSectionSecurity;

  /// Settings section heading: download folder.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsSectionStorage;

  /// Settings section heading: Paperless-AI chat configuration.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get settingsSectionAiChat;

  /// Settings section heading: labels, workflows, custom fields, templates, upload queue and trash.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsSectionData;

  /// Settings section heading: app version.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// Settings row showing the address of the server the user is logged in to.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsServer;

  /// Shown in place of the server address when the user is not logged in.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get settingsServerNotConnected;

  /// Tooltip of the button that deletes a saved server profile.
  ///
  /// In en, this message translates to:
  /// **'Remove profile'**
  String get settingsRemoveProfileTooltip;

  /// Settings row that saves the current server so the user can switch back to it later.
  ///
  /// In en, this message translates to:
  /// **'Save current server as profile'**
  String get settingsSaveProfile;

  /// Title of the dialog that names a new server profile.
  ///
  /// In en, this message translates to:
  /// **'Save Server Profile'**
  String get settingsSaveProfileTitle;

  /// Label of the server profile name field.
  ///
  /// In en, this message translates to:
  /// **'Profile name'**
  String get settingsProfileNameLabel;

  /// Example value shown in the empty server profile name field.
  ///
  /// In en, this message translates to:
  /// **'e.g., Home Server'**
  String get settingsProfileNameHint;

  /// Settings row, and the confirm button of its dialog, that logs the user out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// Title of the dialog asking the user to confirm signing out.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get settingsSignOutConfirmTitle;

  /// Body of the dialog asking the user to confirm signing out.
  ///
  /// In en, this message translates to:
  /// **'You will need to log in again.'**
  String get settingsSignOutConfirmMessage;

  /// Settings row choosing between system, light and dark theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Theme option that follows the device's light/dark setting. Keep it short: it shares a row with two other options.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// Light theme option. Keep it short: it shares a row with two other options.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Dark theme option. Keep it short: it shares a row with two other options.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Settings row choosing which screen the app opens on.
  ///
  /// In en, this message translates to:
  /// **'Start screen'**
  String get settingsStartScreen;

  /// Start screen option: the list of all documents.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get settingsStartScreenLibrary;

  /// Start screen option: the inbox of documents waiting to be sorted.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get settingsStartScreenInbox;

  /// Snackbar shown when the chosen start screen could not be stored.
  ///
  /// In en, this message translates to:
  /// **'Could not save the start screen.'**
  String get settingsStartScreenSaveFailed;

  /// Switch that requires fingerprint or face unlock when the app is opened.
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock'**
  String get settingsBiometricLock;

  /// Explanation under the biometric lock switch.
  ///
  /// In en, this message translates to:
  /// **'Require authentication on app launch'**
  String get settingsBiometricLockSubtitle;

  /// Snackbar shown when the user turns on the biometric lock on a device without biometrics.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is not available on this device'**
  String get settingsBiometricUnavailable;

  /// Reason shown in the system biometric prompt when turning the lock on.
  ///
  /// In en, this message translates to:
  /// **'Verify to enable biometric lock'**
  String get settingsBiometricVerifyReason;

  /// Settings row choosing the folder where documents are saved.
  ///
  /// In en, this message translates to:
  /// **'Download folder'**
  String get settingsDownloadFolder;

  /// Shown under the download folder row when no folder is set.
  ///
  /// In en, this message translates to:
  /// **'Ask each time'**
  String get settingsDownloadFolderAskEachTime;

  /// Shown under the download folder row when Android revoked access to the chosen folder.
  ///
  /// In en, this message translates to:
  /// **'{folder} — no longer available, tap to choose again'**
  String settingsDownloadFolderUnavailable(String folder);

  /// Shown under the download folder row when its access could not be checked.
  ///
  /// In en, this message translates to:
  /// **'Could not check folder access'**
  String get settingsDownloadFolderCheckFailed;

  /// Shown under the download folder row while its access is being checked.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get settingsDownloadFolderChecking;

  /// Option in the download folder sheet that opens the folder picker.
  ///
  /// In en, this message translates to:
  /// **'Choose a different folder'**
  String get settingsDownloadFolderChooseOther;

  /// Option in the download folder sheet that clears the chosen folder.
  ///
  /// In en, this message translates to:
  /// **'Forget this folder'**
  String get settingsDownloadFolderForget;

  /// Explanation under the forget folder option. "Save to folder" is the name of a document action.
  ///
  /// In en, this message translates to:
  /// **'Save to folder will ask each time'**
  String get settingsDownloadFolderForgetSubtitle;

  /// Settings row, and title of its dialog, for the address of the Paperless-AI server. Paperless-AI is a product name.
  ///
  /// In en, this message translates to:
  /// **'Paperless-AI URL'**
  String get settingsAiUrl;

  /// Shown under the Paperless-AI URL row when no address is set.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get settingsAiUrlNotConfigured;

  /// Explanation at the top of the Paperless-AI URL dialog. Keep the example address as is.
  ///
  /// In en, this message translates to:
  /// **'Enter the URL of your Paperless-AI instance (e.g., http://your-server:8083)'**
  String get settingsAiUrlDescription;

  /// Label of the address field in the Paperless-AI URL dialog.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get settingsAiUrlFieldLabel;

  /// Error shown when verifying Paperless-AI before its address is set.
  ///
  /// In en, this message translates to:
  /// **'Set the Paperless-AI URL first.'**
  String get settingsAiUrlRequired;

  /// Settings row, and title of its dialog, for the Paperless-AI username and password.
  ///
  /// In en, this message translates to:
  /// **'Paperless-AI Credentials'**
  String get settingsAiCredentials;

  /// Shown under the Paperless-AI credentials row when credentials are saved.
  ///
  /// In en, this message translates to:
  /// **'Logged in as {username}'**
  String settingsAiLoggedInAs(String username);

  /// Shown under the Paperless-AI credentials row when none are saved.
  ///
  /// In en, this message translates to:
  /// **'Not configured (required for chat)'**
  String get settingsAiCredentialsNotConfigured;

  /// Explanation at the top of the Paperless-AI credentials dialog.
  ///
  /// In en, this message translates to:
  /// **'Enter your Paperless-AI login credentials. Required for chat.'**
  String get settingsAiCredentialsDescription;

  /// Snackbar shown when verifying Paperless-AI before credentials are saved.
  ///
  /// In en, this message translates to:
  /// **'Set your Paperless-AI credentials first.'**
  String get settingsAiCredentialsRequired;

  /// Button in the credentials dialog that checks them against Paperless-AI, then saves them.
  ///
  /// In en, this message translates to:
  /// **'Verify & save'**
  String get settingsAiVerifyAndSave;

  /// Snackbar shown after Paperless-AI credentials were checked and saved.
  ///
  /// In en, this message translates to:
  /// **'Credentials verified'**
  String get settingsAiCredentialsVerified;

  /// Settings row that checks Paperless-AI can be reached with the saved credentials.
  ///
  /// In en, this message translates to:
  /// **'Verify Connection'**
  String get settingsAiVerify;

  /// Explanation under the verify connection row.
  ///
  /// In en, this message translates to:
  /// **'Check server reachability and credentials'**
  String get settingsAiVerifySubtitle;

  /// Progress dialog shown while Paperless-AI is being checked.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get settingsAiVerifying;

  /// Snackbar shown when Paperless-AI was reached and the credentials were accepted.
  ///
  /// In en, this message translates to:
  /// **'Paperless-AI connection verified'**
  String get settingsAiVerified;

  /// Settings row opening the screen that manages tags, correspondents and document types.
  ///
  /// In en, this message translates to:
  /// **'Manage Labels'**
  String get settingsManageLabels;

  /// Explanation under the manage labels row. These are Paperless-ngx concepts.
  ///
  /// In en, this message translates to:
  /// **'Tags, correspondents, document types'**
  String get settingsManageLabelsSubtitle;

  /// Settings row opening the Paperless-ngx workflows screen.
  ///
  /// In en, this message translates to:
  /// **'Workflows'**
  String get settingsWorkflows;

  /// Explanation under the workflows row.
  ///
  /// In en, this message translates to:
  /// **'View and manage automation rules'**
  String get settingsWorkflowsSubtitle;

  /// Settings row opening the Paperless-ngx custom fields screen.
  ///
  /// In en, this message translates to:
  /// **'Custom Fields'**
  String get settingsCustomFields;

  /// Explanation under the custom fields row.
  ///
  /// In en, this message translates to:
  /// **'Create and manage field definitions'**
  String get settingsCustomFieldsSubtitle;

  /// Settings row opening the screen of saved metadata presets used when uploading.
  ///
  /// In en, this message translates to:
  /// **'Upload Templates'**
  String get settingsUploadTemplates;

  /// Explanation under the upload templates row.
  ///
  /// In en, this message translates to:
  /// **'Save metadata presets for quick upload'**
  String get settingsUploadTemplatesSubtitle;

  /// Settings row opening the list of uploads that have not reached the server yet.
  ///
  /// In en, this message translates to:
  /// **'Upload queue'**
  String get settingsUploadQueue;

  /// Shown under the upload queue row when the queue is empty.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting to upload'**
  String get settingsUploadQueueEmpty;

  /// Shown under the upload queue row: number of files waiting to upload.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} waiting to upload}}'**
  String settingsUploadQueueWaiting(int count);

  /// Shown under the upload queue row when some uploads stopped retrying and need the user.
  ///
  /// In en, this message translates to:
  /// **'{waiting} waiting · {stuck} need attention'**
  String settingsUploadQueueNeedsAttention(int waiting, int stuck);

  /// Settings row opening the trash (deleted documents).
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get settingsTrash;

  /// Explanation under the trash row.
  ///
  /// In en, this message translates to:
  /// **'View and restore deleted documents'**
  String get settingsTrashSubtitle;
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
