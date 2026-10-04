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

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsSectionSecurity => 'Security';

  @override
  String get settingsSectionStorage => 'Storage';

  @override
  String get settingsSectionAiChat => 'AI Chat';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsServer => 'Server';

  @override
  String get settingsServerNotConnected => 'Not connected';

  @override
  String get settingsRemoveProfileTooltip => 'Remove profile';

  @override
  String get settingsSaveProfile => 'Save current server as profile';

  @override
  String get settingsSaveProfileTitle => 'Save Server Profile';

  @override
  String get settingsProfileNameLabel => 'Profile name';

  @override
  String get settingsProfileNameHint => 'e.g., Home Server';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutConfirmTitle => 'Sign out?';

  @override
  String get settingsSignOutConfirmMessage => 'You will need to log in again.';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsStartScreen => 'Start screen';

  @override
  String get settingsStartScreenLibrary => 'Library';

  @override
  String get settingsStartScreenInbox => 'Inbox';

  @override
  String get settingsStartScreenSaveFailed =>
      'Could not save the start screen.';

  @override
  String get settingsBiometricLock => 'Biometric Lock';

  @override
  String get settingsBiometricLockSubtitle =>
      'Require authentication on app launch';

  @override
  String get settingsBiometricUnavailable =>
      'Biometric authentication is not available on this device';

  @override
  String get settingsBiometricVerifyReason => 'Verify to enable biometric lock';

  @override
  String get settingsDownloadFolder => 'Download folder';

  @override
  String get settingsDownloadFolderAskEachTime => 'Ask each time';

  @override
  String settingsDownloadFolderUnavailable(String folder) {
    return '$folder — no longer available, tap to choose again';
  }

  @override
  String get settingsDownloadFolderCheckFailed =>
      'Could not check folder access';

  @override
  String get settingsDownloadFolderChecking => 'Checking…';

  @override
  String get settingsDownloadFolderChooseOther => 'Choose a different folder';

  @override
  String get settingsDownloadFolderForget => 'Forget this folder';

  @override
  String get settingsDownloadFolderForgetSubtitle =>
      'Save to folder will ask each time';

  @override
  String get settingsAiUrl => 'Paperless-AI URL';

  @override
  String get settingsAiUrlNotConfigured => 'Not configured';

  @override
  String get settingsAiUrlDescription =>
      'Enter the URL of your Paperless-AI instance (e.g., http://your-server:8083)';

  @override
  String get settingsAiUrlFieldLabel => 'URL';

  @override
  String get settingsAiUrlRequired => 'Set the Paperless-AI URL first.';

  @override
  String get settingsAiCredentials => 'Paperless-AI Credentials';

  @override
  String settingsAiLoggedInAs(String username) {
    return 'Logged in as $username';
  }

  @override
  String get settingsAiCredentialsNotConfigured =>
      'Not configured (required for chat)';

  @override
  String get settingsAiCredentialsDescription =>
      'Enter your Paperless-AI login credentials. Required for chat.';

  @override
  String get settingsAiCredentialsRequired =>
      'Set your Paperless-AI credentials first.';

  @override
  String get settingsAiVerifyAndSave => 'Verify & save';

  @override
  String get settingsAiCredentialsVerified => 'Credentials verified';

  @override
  String get settingsAiVerify => 'Verify Connection';

  @override
  String get settingsAiVerifySubtitle =>
      'Check server reachability and credentials';

  @override
  String get settingsAiVerifying => 'Verifying...';

  @override
  String get settingsAiVerified => 'Paperless-AI connection verified';

  @override
  String get settingsManageLabels => 'Manage Labels';

  @override
  String get settingsManageLabelsSubtitle =>
      'Tags, correspondents, document types';

  @override
  String get settingsWorkflows => 'Workflows';

  @override
  String get settingsWorkflowsSubtitle => 'View and manage automation rules';

  @override
  String get settingsCustomFields => 'Custom Fields';

  @override
  String get settingsCustomFieldsSubtitle =>
      'Create and manage field definitions';

  @override
  String get settingsUploadTemplates => 'Upload Templates';

  @override
  String get settingsUploadTemplatesSubtitle =>
      'Save metadata presets for quick upload';

  @override
  String get settingsUploadQueue => 'Upload queue';

  @override
  String get settingsUploadQueueEmpty => 'Nothing waiting to upload';

  @override
  String settingsUploadQueueWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waiting to upload',
    );
    return '$_temp0';
  }

  @override
  String settingsUploadQueueNeedsAttention(int waiting, int stuck) {
    return '$waiting waiting · $stuck need attention';
  }

  @override
  String get settingsTrash => 'Trash';

  @override
  String get settingsTrashSubtitle => 'View and restore deleted documents';
}
