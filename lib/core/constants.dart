class ApiConstants {
  static const String apiVersion = '9';
  static const String acceptHeader = 'application/json; version=$apiVersion';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int maxRedirects = 5;
  static const int defaultPageSize = 25;
}

class StorageKeys {
  static const String serverUrl = 'server_url';
  static const String apiToken = 'api_token';
  static const String username = 'username';
  static const String aiChatUrl = 'ai_chat_url';
  static const String aiChatUsername = 'ai_chat_username';
  static const String aiChatPassword = 'ai_chat_password';
  static const String themeMode = 'theme_mode';
  static const String biometricLock = 'biometric_lock';
  static const String serverProfiles = 'server_profiles';
  static const String activeProfileIndex = 'active_profile_index';
  static const String downloadsUri = 'downloads_uri';
  static const String downloadsName = 'downloads_name';
}
