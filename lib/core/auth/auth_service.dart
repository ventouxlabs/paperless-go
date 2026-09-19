import 'package:dio/dio.dart';
import '../api/api_error_mapper.dart';
import '../api/dio_client.dart';
import 'secure_storage.dart';

/// Outcome of an unauthenticated reachability probe.
typedef ConnectionProbe = ({bool ok, String? reason});

class AuthService {
  final SecureStorageService _storage;
  final Dio Function(String serverUrl) _dioFactory;

  AuthService({
    SecureStorageService? storage,
    Dio Function(String serverUrl)? dioFactory,
  })  : _storage = storage ?? SecureStorageService(),
        _dioFactory = dioFactory ?? DioClient.createUnauthenticated;

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
