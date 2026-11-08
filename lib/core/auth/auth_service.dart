import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import '../api/api_error_mapper.dart';
import '../api/dio_client.dart';
import 'secure_storage.dart';

/// Outcome of an unauthenticated reachability probe.
typedef ConnectionProbe = ({bool ok, String? reason});

const ssoRedirectUrl = 'com.ventouxlabs.paperlessgo:/oidc-callback';
const ssoFallbackScopes = ['openid', 'profile', 'email'];
const _headless = 'api/auth/headless';
const ssoRejectedMessage =
    'Sign-in with the identity provider failed. Check your connection and '
    'the SSO setup in the README.';

/// An OpenID Connect provider Paperless can log in with from an app.
class SsoProvider {
  final String id;
  final String name;
  final String clientId;
  final String openidConfigurationUrl;

  const SsoProvider({
    required this.id,
    required this.name,
    required this.clientId,
    required this.openidConfigurationUrl,
  });
}

/// Runs the browser login and returns the provider's `id_token`, or null
/// when the user closed the browser.
typedef SsoAuthorize = Future<String?> Function({
  required String clientId,
  required String discoveryUrl,
  required List<String> scopes,
});

Future<String?> appAuthAuthorize({
  required String clientId,
  required String discoveryUrl,
  required List<String> scopes,
}) async {
  try {
    final response = await const FlutterAppAuth().authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        clientId,
        ssoRedirectUrl,
        discoveryUrl: discoveryUrl,
        scopes: scopes,
      ),
    );
    final idToken = response.idToken;
    if (idToken == null) throw AuthException(ssoRejectedMessage);
    return idToken;
  } on FlutterAppAuthUserCancelledException {
    return null;
  } on PlatformException {
    throw AuthException(ssoRejectedMessage);
  }
}

class AuthService {
  final SecureStorageService _storage;
  final Dio Function(String serverUrl) _dioFactory;
  final SsoAuthorize _ssoAuthorize;

  AuthService({
    SecureStorageService? storage,
    Dio Function(String serverUrl)? dioFactory,
    SsoAuthorize? ssoAuthorize,
  })  : _storage = storage ?? SecureStorageService(),
        _dioFactory = dioFactory ?? DioClient.createUnauthenticated,
        _ssoAuthorize = ssoAuthorize ?? appAuthAuthorize;

  /// Login with username/password, returns the API token.
  Future<String> loginWithCredentials(String serverUrl, String username, String password) async {
    final dio = DioClient.createUnauthenticated(serverUrl);
    try {
      final response = await dio.post(
        'api/token/',
        data: {'username': username, 'password': password},
      );
      final token = response.data['token'] as String?;
      if (token == null) throw AuthException('No token in response');
      await _storage.saveServerUrl(serverUrl);
      await _storage.saveApiToken(token);
      await _storage.saveUsername(username);
      return token;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
        throw AuthException('Invalid username or password');
      }
      throw AuthException(_describeConnectionError(e));
    }
  }

  /// OIDC providers that support the headless app login. Empty when the
  /// server has none or predates Paperless-ngx 3.0.
  Future<List<SsoProvider>> fetchSsoProviders(String serverUrl) async {
    try {
      final response = await _dioFactory(serverUrl).get('$_headless/app/v1/config');
      final providers = switch (response.data) {
        {'data': {'socialaccount': {'providers': final List list}}} => list,
        _ => const [],
      };
      return [
        for (final p in providers)
          if (p
              case {
                'id': final String id,
                'name': final String name,
                'client_id': final String clientId,
                'openid_configuration_url': final String url,
                'flows': final List flows,
              } when flows.contains('provider_token'))
            SsoProvider(
              id: id,
              name: name,
              clientId: clientId,
              openidConfigurationUrl: url,
            ),
      ];
    } on DioException {
      return const [];
    }
  }

  /// Browser login through [provider]. Returns the API token, or null when
  /// the user closed the browser. [appClientId] is a separate public client
  /// trusted by the Paperless client, as in a Dex cross-client setup.
  Future<String?> loginWithSso(
    String serverUrl,
    SsoProvider provider, {
    String? appClientId,
  }) async {
    final dio = _dioFactory(serverUrl);
    final scopes = await _fetchSsoScopes(dio, serverUrl, provider.id);
    final crossClient = appClientId != null && appClientId.isNotEmpty;
    final idToken = await _ssoAuthorize(
      clientId: crossClient ? appClientId : provider.clientId,
      discoveryUrl: provider.openidConfigurationUrl,
      scopes: [
        ...scopes,
        if (crossClient) 'audience:server:client_id:${provider.clientId}',
      ],
    );
    if (idToken == null) return null;

    final Response<dynamic> response;
    try {
      response = await dio.post(
        '$_headless/app/v1/auth/provider/token',
        data: {
          'provider': provider.id,
          'process': 'login',
          'token': {'client_id': provider.clientId, 'id_token': idToken},
        },
        options: Options(validateStatus: (_) => true),
      );
    } on DioException catch (e) {
      throw AuthException(_describeConnectionError(e));
    }

    final token = switch (response.data) {
      {'meta': {'access_token': final String t}} => t,
      _ => null,
    };
    if (response.statusCode == 200 && token != null) {
      await _storage.saveServerUrl(serverUrl);
      await _storage.saveApiToken(token);
      return token;
    }
    throw AuthException(switch (response.statusCode) {
      401 when _isPendingMfa(response.data) =>
        'This account uses two-factor login, which SSO in the app does not '
            'support yet. Use an API token instead.',
      401 || 403 || 409 =>
        'Paperless did not allow this account to sign in. Ask your Paperless admin.',
      400 =>
        'The identity provider client does not match Paperless. Check the SSO setup in the README.',
      200 => 'Paperless did not return an API token',
      final status => 'Server returned HTTP $status',
    });
  }

  static bool _isPendingMfa(Object? data) => switch (data) {
        {'data': {'flows': final List flows}} => flows.any(
            (f) => f is Map && f['id'] == 'mfa_authenticate' && f['is_pending'] == true,
          ),
        _ => false,
      };

  /// The scope Paperless asks the provider for, read from the redirect
  /// Paperless's own web login would start, so claims such as groups match.
  static Future<List<String>> _fetchSsoScopes(
    Dio dio,
    String serverUrl,
    String providerId,
  ) async {
    try {
      final page = await dio.get<String>(
        'accounts/login/',
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (_) => true,
        ),
      );
      final csrf = _csrfCookie(page.headers);
      if (csrf == null) return ssoFallbackScopes;
      final redirect = await dio.post(
        '$_headless/browser/v1/auth/provider/redirect',
        data: {
          'provider': providerId,
          'callback_url': serverUrl,
          'process': 'login',
          'csrfmiddlewaretoken': csrf.value,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (_) => true,
          headers: {
            'X-CSRFToken': csrf.value,
            'Cookie': '${csrf.name}=${csrf.value}',
            'Referer': '$serverUrl/',
          },
        ),
      );
      final location = redirect.headers.value('location');
      final scope = location == null
          ? null
          : Uri.tryParse(location)?.queryParameters['scope'];
      final scopes = scope?.split(' ').where((s) => s.isNotEmpty).toList();
      return scopes == null || scopes.isEmpty ? ssoFallbackScopes : scopes;
    } on DioException {
      return ssoFallbackScopes;
    }
  }

  static ({String name, String value})? _csrfCookie(Headers headers) {
    for (final cookie in headers['set-cookie'] ?? const <String>[]) {
      final pair = cookie.split(';').first;
      final eq = pair.indexOf('=');
      if (eq <= 0) continue;
      final name = pair.substring(0, eq).trim();
      if (name.endsWith('csrftoken')) {
        return (name: name, value: pair.substring(eq + 1).trim());
      }
    }
    return null;
  }

  /// Login with a pre-existing API token.
  Future<void> loginWithToken(String serverUrl, String token) async {
    final dio = DioClient.create(serverUrl, token);
    try {
      await dio.get('api/statistics/');
      await _storage.saveServerUrl(serverUrl);
      await _storage.saveApiToken(token);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw AuthException('Invalid or expired token');
      }
      throw AuthException(_describeConnectionError(e));
    }
  }

  static String _describeConnectionError(DioException e) {
    final status = e.response?.statusCode;
    if (status != null) return 'Server returned HTTP $status';
    return switch (e.type) {
      DioExceptionType.connectionTimeout => 'Connection timed out',
      DioExceptionType.receiveTimeout => 'Server took too long to respond',
      DioExceptionType.connectionError => friendlyApiMessage(e),
      DioExceptionType.badCertificate => friendlyApiMessage(e),
      DioExceptionType.unknown when isUntrustedCertificateError(e) =>
        friendlyApiMessage(e),
      _ => e.message ?? 'Connection failed (${e.type.name})',
    };
  }

  /// Test connection to server (unauthenticated).
  Future<ConnectionProbe> testConnection(String serverUrl) async {
    // Reject an empty/missing host before ever building a Dio instance: an
    // empty host (e.g. the default 'https://' field, or 'https://:8000')
    // makes DioClient's BaseOptions.baseUrl setter throw an ArgumentError,
    // which — unlike DioException — must not be caught here.
    final host = Uri.tryParse(serverUrl)?.host;
    if (host == null || host.isEmpty) {
      return (ok: false, reason: 'Enter a valid URL');
    }
    try {
      final dio = _dioFactory(serverUrl);
      await dio.get(
        'api/',
        options: Options(
          followRedirects: false,
          validateStatus: (_) => true,
        ),
      );
      return (ok: true, reason: null);
    } on DioException catch (e) {
      return (ok: false, reason: _describeConnectionError(e));
    }
  }

  /// Check if we have saved credentials.
  Future<bool> isAuthenticated() async {
    final token = await _storage.getApiToken();
    final url = await _storage.getServerUrl();
    return token != null && url != null;
  }

  Future<({String serverUrl, String token})?> getSavedCredentials() async {
    final token = await _storage.getApiToken();
    final url = await _storage.getServerUrl();
    if (token != null && url != null) {
      return (serverUrl: url, token: token);
    }
    return null;
  }

  Future<void> logout() => _storage.clearAll();
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
