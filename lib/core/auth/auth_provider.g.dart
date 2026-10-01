// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$secureStorageHash() => r'9005f3948067dc99e23856b40aa14612f85932cf';

/// See also [secureStorage].
@ProviderFor(secureStorage)
final secureStorageProvider =
    AutoDisposeProvider<SecureStorageService>.internal(
      secureStorage,
      name: r'secureStorageProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$secureStorageHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SecureStorageRef = AutoDisposeProviderRef<SecureStorageService>;
String _$authServiceHash() => r'eab008beac96e459972191badcdfb6b03b131ed8';

/// See also [authService].
@ProviderFor(authService)
final authServiceProvider = AutoDisposeProvider<AuthService>.internal(
  authService,
  name: r'authServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthServiceRef = AutoDisposeProviderRef<AuthService>;
String _$dioHash() => r'f9b45df15a59afb100f3dca72acbec576ef5e6d1';

/// Provides an authenticated Dio instance. Throws if not authenticated.
/// Closes the previous instance when auth state changes.
///
/// Copied from [dio].
@ProviderFor(dio)
final dioProvider = Provider<Dio>.internal(
  dio,
  name: r'dioProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dioHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DioRef = ProviderRef<Dio>;
String _$authStateHash() => r'fa827aa5858bed37d32c6d1f5bec7cf8fb6d90be';

/// See also [AuthState].
@ProviderFor(AuthState)
final authStateProvider =
    AutoDisposeAsyncNotifierProvider<AuthState, AuthStatus>.internal(
      AuthState.new,
      name: r'authStateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AuthState = AutoDisposeAsyncNotifier<AuthStatus>;
String _$aiChatUrlHash() => r'9a41f8f38762c345402ec782810376336a415819';

/// See also [AiChatUrl].
@ProviderFor(AiChatUrl)
final aiChatUrlProvider = NotifierProvider<AiChatUrl, String?>.internal(
  AiChatUrl.new,
  name: r'aiChatUrlProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$aiChatUrlHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AiChatUrl = Notifier<String?>;
String _$aiChatUsernameHash() => r'22485de96294355999cc02584f0aa5e157885f87';

/// See also [AiChatUsername].
@ProviderFor(AiChatUsername)
final aiChatUsernameProvider =
    NotifierProvider<AiChatUsername, String?>.internal(
      AiChatUsername.new,
      name: r'aiChatUsernameProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$aiChatUsernameHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AiChatUsername = Notifier<String?>;
String _$aiChatPasswordHash() => r'1e72473f52a1dd84b547332a646bdeb24f8fcafa';

/// See also [AiChatPassword].
@ProviderFor(AiChatPassword)
final aiChatPasswordProvider =
    NotifierProvider<AiChatPassword, String?>.internal(
      AiChatPassword.new,
      name: r'aiChatPasswordProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$aiChatPasswordHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AiChatPassword = Notifier<String?>;
String _$themeModeNotifierHash() => r'2040eed4203f04bbed927b42efa384aa7ebf6067';

/// See also [ThemeModeNotifier].
@ProviderFor(ThemeModeNotifier)
final themeModeNotifierProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>.internal(
      ThemeModeNotifier.new,
      name: r'themeModeNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$themeModeNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ThemeModeNotifier = Notifier<ThemeMode>;
String _$biometricLockHash() => r'5823c17bba2547d1b4a3f13bbfffaf86b07495bb';

/// See also [BiometricLock].
@ProviderFor(BiometricLock)
final biometricLockProvider = NotifierProvider<BiometricLock, bool>.internal(
  BiometricLock.new,
  name: r'biometricLockProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$biometricLockHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BiometricLock = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
