import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../api/dio_client.dart';
import '../database/cache_provider.dart';
import '../services/export_destination_service.dart';
import 'auth_service.dart';
import 'secure_storage.dart';

part 'auth_provider.g.dart';

@riverpod
SecureStorageService secureStorage(Ref ref) => SecureStorageService();

@riverpod
AuthService authService(Ref ref) =>
    AuthService(storage: ref.watch(secureStorageProvider));

@riverpod
class AuthState extends _$AuthState {
  @override
  Future<AuthStatus> build() async {
    final authService = ref.watch(authServiceProvider);
    final credentials = await authService.getSavedCredentials();
    if (credentials != null) {
      return AuthStatus.authenticated(
        serverUrl: credentials.serverUrl,
        token: credentials.token,
      );
    }
    return const AuthStatus.unauthenticated();
  }

  Future<void> loginWithCredentials(String serverUrl, String username, String password) async {
    state = const AsyncLoading();
    try {
      final authService = ref.read(authServiceProvider);
      final token = await authService.loginWithCredentials(serverUrl, username, password);
      state = AsyncData(AuthStatus.authenticated(serverUrl: serverUrl, token: token));
    } catch (e) {
      state = const AsyncData(AuthStatus.unauthenticated());
      rethrow;
    }
  }

  Future<void> loginWithToken(String serverUrl, String token) async {
    state = const AsyncLoading();
    try {
      final authService = ref.read(authServiceProvider);
      await authService.loginWithToken(serverUrl, token);
      state = AsyncData(AuthStatus.authenticated(serverUrl: serverUrl, token: token));
    } catch (e) {
      state = const AsyncData(AuthStatus.unauthenticated());
      rethrow;
    }
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    try {
      final cache = ref.read(cacheRepositoryProvider);
      await cache.clearServerCache();
    } catch (_) {
      // Cache may not be initialized yet
    }
    await authService.logout();
    state = const AsyncData(AuthStatus.unauthenticated());
  }
}

/// Thrown when something needs an authenticated client and there is no session
/// — no server configured yet, or the user is signed out.
///
/// A named type rather than a bare [StateError] because callers branch on it:
/// the upload queue treats it as "park this document and retry after login".
/// Matching `StateError` there would also swallow every unrelated bad-state bug
/// into a silent retry loop, and would break on a Riverpod upgrade that wraps
/// provider build errors rather than rethrowing the original object.
class NotAuthenticatedException implements Exception {
  const NotAuthenticatedException();

  @override
  String toString() => 'Not authenticated';
}

/// Provides an authenticated Dio instance. Throws if not authenticated.
/// Closes the previous instance when auth state changes.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final authStatus = ref.watch(authStateProvider).valueOrNull;
  if (authStatus == null || !authStatus.isAuthenticated) {
    throw const NotAuthenticatedException();
  }
  final dio = DioClient.create(authStatus.serverUrl!, authStatus.token!);
  ref.onDispose(() => dio.close());
  return dio;
}

sealed class AuthStatus {
  const AuthStatus();
  const factory AuthStatus.authenticated({
    required String serverUrl,
    required String token,
  }) = Authenticated;
  const factory AuthStatus.unauthenticated() = Unauthenticated;

  bool get isAuthenticated => this is Authenticated;
  String? get serverUrl => switch (this) {
    Authenticated(:final serverUrl) => serverUrl,
    _ => null,
  };
  String? get token => switch (this) {
    Authenticated(:final token) => token,
    _ => null,
  };
}

class Authenticated extends AuthStatus {
  @override
  final String serverUrl;
  @override
  final String token;
  const Authenticated({required this.serverUrl, required this.token});
}

class Unauthenticated extends AuthStatus {
  const Unauthenticated();
}

@Riverpod(keepAlive: true)
class AiChatUrl extends _$AiChatUrl {
  bool _userChanged = false;

  @override
  String? build() {
    _userChanged = false;
    _loadUrl();
    return null;
  }

  Future<void> _loadUrl() async {
    final storage = ref.read(secureStorageProvider);
    final url = await storage.getAiChatUrl();
    if (!_userChanged && url != null && url.isNotEmpty) {
      state = url;
    }
  }

  Future<void> setUrl(String url) async {
    _userChanged = true;
    final storage = ref.read(secureStorageProvider);
    await storage.saveAiChatUrl(url);
    state = url.isEmpty ? null : url;
  }
}

@Riverpod(keepAlive: true)
class AiChatUsername extends _$AiChatUsername {
  bool _userChanged = false;

  @override
  String? build() {
    _userChanged = false;
    _load();
    return null;
  }

  Future<void> _load() async {
    final storage = ref.read(secureStorageProvider);
    final value = await storage.getAiChatUsername();
    if (!_userChanged && value != null && value.isNotEmpty) {
      state = value;
    }
  }

  Future<void> set(String value) async {
    _userChanged = true;
    final storage = ref.read(secureStorageProvider);
    await storage.saveAiChatUsername(value);
    state = value.isEmpty ? null : value;
  }
}

@Riverpod(keepAlive: true)
class AiChatPassword extends _$AiChatPassword {
  bool _userChanged = false;

  @override
  String? build() {
    _userChanged = false;
    _load();
    return null;
  }

  Future<void> _load() async {
    final storage = ref.read(secureStorageProvider);
    final value = await storage.getAiChatPassword();
    if (!_userChanged && value != null && value.isNotEmpty) {
      state = value;
    }
  }

  Future<void> set(String value) async {
    _userChanged = true;
    final storage = ref.read(secureStorageProvider);
    await storage.saveAiChatPassword(value);
    state = value.isEmpty ? null : value;
  }
}

@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  bool _userChanged = false;

  @override
  ThemeMode build() {
    _userChanged = false;
    _loadThemeMode();
    return ThemeMode.system;
  }

  Future<void> _loadThemeMode() async {
    final storage = ref.read(secureStorageProvider);
    final mode = await storage.getThemeMode();
    if (!_userChanged && mode != null) {
      state = ThemeMode.values.firstWhere(
        (m) => m.name == mode,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _userChanged = true;
    final storage = ref.read(secureStorageProvider);
    await storage.saveThemeMode(mode.name);
    state = mode;
  }
}

@Riverpod(keepAlive: true)
class BiometricLock extends _$BiometricLock {
  bool _userChanged = false;

  @override
  bool build() {
    _userChanged = false;
    _loadSetting();
    return false;
  }

  Future<void> _loadSetting() async {
    final storage = ref.read(secureStorageProvider);
    final enabled = await storage.getBiometricLock();
    if (!_userChanged) {
      state = enabled;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _userChanged = true;
    final storage = ref.read(secureStorageProvider);
    await storage.saveBiometricLock(enabled);
    state = enabled;
  }
}

// Hand-written rather than @riverpod: code generation cannot run on this
// toolchain (the pinned analyzer rejects Dart 3.13 syntax, so build_runner
// deletes every generated file and then fails). Convert back to @riverpod once
// the analyzer/SDK mismatch is resolved.
final exportDestinationServiceProvider = Provider<ExportDestinationService>(
  (ref) => ExportDestinationService(storage: ref.watch(secureStorageProvider)),
);

/// The downloads folder, re-validated against live OS grants on every read.
///
/// Async rather than the sync-then-patch shape used above because a stored URI
/// is only a hint — the grant it refers to can be revoked at any time, so the
/// value has to be checked before it can be shown or used. Auto-disposing on
/// purpose: this feeds the UI only (the save path re-resolves for itself), so
/// letting it rebuild means a reopened Settings screen always shows the truth.
final downloadsDestinationProvider = AsyncNotifierProvider.autoDispose<
    DownloadsDestination, ExportDestination>(DownloadsDestination.new);

class DownloadsDestination
    extends AutoDisposeAsyncNotifier<ExportDestination> {
  @override
  Future<ExportDestination> build() =>
      ref.watch(exportDestinationServiceProvider).resolve();

  /// Prompts for a folder. Returns true if one was chosen and persisted.
  Future<bool> choose() async {
    final service = ref.read(exportDestinationServiceProvider);
    final chosen = await service.chooseFolder();
    if (chosen == null) return false;
    state = AsyncData(chosen);
    return true;
  }

  Future<void> clear() async {
    await ref.read(exportDestinationServiceProvider).forget();
    state = const AsyncData(ExportDestination.unset());
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(exportDestinationServiceProvider).resolve(),
    );
  }
}
