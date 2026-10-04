// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonUsername => 'Nom d’utilisateur';

  @override
  String get commonPassword => 'Mot de passe';

  @override
  String get loginSubtitle => 'Connectez-vous à votre serveur Paperless-ngx';

  @override
  String get loginServerUrlLabel => 'URL du serveur';

  @override
  String get loginTestConnectionTooltip => 'Tester la connexion';

  @override
  String get loginServerUrlRequired => 'Saisissez l’URL de votre serveur';

  @override
  String get loginServerUrlSchemeRequired =>
      'L’URL doit commencer par https:// ou http://';

  @override
  String get loginServerUrlHttpBlocked =>
      'Cette application exige https:// — les connexions en http:// simple sont bloquées. Placez votre serveur derrière un reverse proxy ou Tailscale Serve pour obtenir une adresse HTTPS valide.';

  @override
  String get loginServerUrlInvalid => 'Saisissez une URL valide';

  @override
  String get loginHttpWarning =>
      'http:// est bloqué par cette application — utilisez https://';

  @override
  String get loginUseApiToken => 'Se connecter avec un jeton d’API';

  @override
  String get loginApiTokenLabel => 'Jeton d’API';

  @override
  String get loginApiTokenRequired => 'Saisissez votre jeton d’API';

  @override
  String get loginUsernameRequired => 'Saisissez votre nom d’utilisateur';

  @override
  String get loginPasswordRequired => 'Saisissez votre mot de passe';

  @override
  String get loginSubmit => 'Se connecter';

  @override
  String loginConnectionError(String message) {
    return 'Erreur de connexion : $message';
  }

  @override
  String get lockSubtitle => 'Authentifiez-vous pour continuer';

  @override
  String get lockUnlock => 'Déverrouiller';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsSectionAccount => 'Compte';

  @override
  String get settingsSectionAppearance => 'Apparence';

  @override
  String get settingsSectionSecurity => 'Sécurité';

  @override
  String get settingsSectionStorage => 'Stockage';

  @override
  String get settingsSectionAiChat => 'Chat IA';

  @override
  String get settingsSectionData => 'Données';

  @override
  String get settingsSectionAbout => 'À propos';

  @override
  String get settingsServer => 'Serveur';

  @override
  String get settingsServerNotConnected => 'Non connecté';

  @override
  String get settingsRemoveProfileTooltip => 'Supprimer le profil';

  @override
  String get settingsSaveProfile => 'Enregistrer ce serveur comme profil';

  @override
  String get settingsSaveProfileTitle => 'Enregistrer le profil serveur';

  @override
  String get settingsProfileNameLabel => 'Nom du profil';

  @override
  String get settingsProfileNameHint => 'ex. : Serveur maison';

  @override
  String get settingsSignOut => 'Se déconnecter';

  @override
  String get settingsSignOutConfirmTitle => 'Se déconnecter ?';

  @override
  String get settingsSignOutConfirmMessage => 'Vous devrez vous reconnecter.';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsStartScreen => 'Écran d’accueil';

  @override
  String get settingsStartScreenLibrary => 'Bibliothèque';

  @override
  String get settingsStartScreenInbox => 'Boîte de réception';

  @override
  String get settingsStartScreenSaveFailed =>
      'Impossible d’enregistrer l’écran d’accueil.';

  @override
  String get settingsBiometricLock => 'Verrouillage biométrique';

  @override
  String get settingsBiometricLockSubtitle =>
      'Exiger une authentification au lancement';

  @override
  String get settingsBiometricUnavailable =>
      'L’authentification biométrique n’est pas disponible sur cet appareil';

  @override
  String get settingsBiometricVerifyReason =>
      'Vérifiez votre identité pour activer le verrouillage biométrique';

  @override
  String get settingsDownloadFolder => 'Dossier de téléchargement';

  @override
  String get settingsDownloadFolderAskEachTime => 'Demander à chaque fois';

  @override
  String settingsDownloadFolderUnavailable(String folder) {
    return '$folder — n’est plus accessible, touchez pour en choisir un autre';
  }

  @override
  String get settingsDownloadFolderCheckFailed =>
      'Impossible de vérifier l’accès au dossier';

  @override
  String get settingsDownloadFolderChecking => 'Vérification…';

  @override
  String get settingsDownloadFolderChooseOther => 'Choisir un autre dossier';

  @override
  String get settingsDownloadFolderForget => 'Oublier ce dossier';

  @override
  String get settingsDownloadFolderForgetSubtitle =>
      '« Enregistrer dans un dossier » demandera à chaque fois';

  @override
  String get settingsAiUrl => 'URL de Paperless-AI';

  @override
  String get settingsAiUrlNotConfigured => 'Non configuré';

  @override
  String get settingsAiUrlDescription =>
      'Saisissez l’URL de votre instance Paperless-AI (ex. : http://your-server:8083)';

  @override
  String get settingsAiUrlFieldLabel => 'URL';

  @override
  String get settingsAiUrlRequired =>
      'Définissez d’abord l’URL de Paperless-AI.';

  @override
  String get settingsAiCredentials => 'Identifiants Paperless-AI';

  @override
  String settingsAiLoggedInAs(String username) {
    return 'Connecté en tant que $username';
  }

  @override
  String get settingsAiCredentialsNotConfigured =>
      'Non configurés (requis pour le chat)';

  @override
  String get settingsAiCredentialsDescription =>
      'Saisissez vos identifiants Paperless-AI. Requis pour le chat.';

  @override
  String get settingsAiCredentialsRequired =>
      'Définissez d’abord vos identifiants Paperless-AI.';

  @override
  String get settingsAiVerifyAndSave => 'Vérifier et enregistrer';

  @override
  String get settingsAiCredentialsVerified => 'Identifiants vérifiés';

  @override
  String get settingsAiVerify => 'Vérifier la connexion';

  @override
  String get settingsAiVerifySubtitle =>
      'Vérifier l’accès au serveur et les identifiants';

  @override
  String get settingsAiVerifying => 'Vérification…';

  @override
  String get settingsAiVerified => 'Connexion à Paperless-AI vérifiée';

  @override
  String get settingsManageLabels => 'Gérer les étiquettes';

  @override
  String get settingsManageLabelsSubtitle =>
      'Tags, correspondants, types de document';

  @override
  String get settingsWorkflows => 'Workflows';

  @override
  String get settingsWorkflowsSubtitle =>
      'Consulter et gérer les règles d’automatisation';

  @override
  String get settingsCustomFields => 'Champs personnalisés';

  @override
  String get settingsCustomFieldsSubtitle =>
      'Créer et gérer les définitions de champs';

  @override
  String get settingsUploadTemplates => 'Modèles d’envoi';

  @override
  String get settingsUploadTemplatesSubtitle =>
      'Enregistrer des préréglages de métadonnées pour envoyer plus vite';

  @override
  String get settingsUploadQueue => 'File d’envoi';

  @override
  String get settingsUploadQueueEmpty => 'Aucun envoi en attente';

  @override
  String settingsUploadQueueWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en attente d’envoi',
      one: '$count en attente d’envoi',
    );
    return '$_temp0';
  }

  @override
  String settingsUploadQueueNeedsAttention(int waiting, int stuck) {
    return '$waiting en attente · $stuck à vérifier';
  }

  @override
  String get settingsTrash => 'Corbeille';

  @override
  String get settingsTrashSubtitle =>
      'Consulter et restaurer les documents supprimés';
}
