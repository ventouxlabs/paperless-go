import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<void> saveServerUrl(String url) =>
      _storage.write(key: StorageKeys.serverUrl, value: url);

  Future<String?> getServerUrl() =>
      _storage.read(key: StorageKeys.serverUrl);

  Future<void> saveApiToken(String token) =>
      _storage.write(key: StorageKeys.apiToken, value: token);

  Future<String?> getApiToken() =>
      _storage.read(key: StorageKeys.apiToken);

  Future<void> saveUsername(String username) =>
      _storage.write(key: StorageKeys.username, value: username);

  Future<String?> getUsername() =>
      _storage.read(key: StorageKeys.username);

  Future<void> saveAiChatUrl(String url) =>
      _storage.write(key: StorageKeys.aiChatUrl, value: url);

  Future<String?> getAiChatUrl() =>
      _storage.read(key: StorageKeys.aiChatUrl);

  Future<void> saveAiChatUsername(String username) =>
      _storage.write(key: StorageKeys.aiChatUsername, value: username);

  Future<String?> getAiChatUsername() =>
      _storage.read(key: StorageKeys.aiChatUsername);

  Future<void> saveAiChatPassword(String password) =>
      _storage.write(key: StorageKeys.aiChatPassword, value: password);

  Future<String?> getAiChatPassword() =>
      _storage.read(key: StorageKeys.aiChatPassword);

  Future<void> saveThemeMode(String mode) =>
      _storage.write(key: StorageKeys.themeMode, value: mode);

  Future<String?> getThemeMode() =>
      _storage.read(key: StorageKeys.themeMode);

  Future<void> saveBiometricLock(bool enabled) =>
      _storage.write(key: StorageKeys.biometricLock, value: enabled.toString());

  Future<bool> getBiometricLock() async {
    final value = await _storage.read(key: StorageKeys.biometricLock);
    return value == 'true';
  }

  // Server profiles (JSON-encoded list)
  Future<void> saveServerProfiles(String json) =>
      _storage.write(key: StorageKeys.serverProfiles, value: json);

  Future<String?> getServerProfiles() =>
      _storage.read(key: StorageKeys.serverProfiles);

  Future<void> saveActiveProfileIndex(int index) =>
      _storage.write(key: StorageKeys.activeProfileIndex, value: index.toString());

  Future<int> getActiveProfileIndex() async {
    final value = await _storage.read(key: StorageKeys.activeProfileIndex);
    return int.tryParse(value ?? '') ?? 0;
  }

  // Downloads destination (SAF tree URI + its display name).
  Future<void> saveDownloadsUri(String uri) =>
      _storage.write(key: StorageKeys.downloadsUri, value: uri);

  Future<String?> getDownloadsUri() =>
      _storage.read(key: StorageKeys.downloadsUri);

  Future<void> saveDownloadsName(String name) =>
      _storage.write(key: StorageKeys.downloadsName, value: name);

  Future<String?> getDownloadsName() =>
      _storage.read(key: StorageKeys.downloadsName);

  Future<void> clearDownloadsDestination() async {
    await _storage.delete(key: StorageKeys.downloadsUri);
    await _storage.delete(key: StorageKeys.downloadsName);
  }

  Future<void> clearAll() => _storage.deleteAll();
}
