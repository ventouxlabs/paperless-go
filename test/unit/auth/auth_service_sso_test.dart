import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/dio_client.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';
import 'package:paperless_go/core/auth/auth_service.dart';
import 'package:paperless_go/core/auth/secure_storage.dart';

const _server = 'https://paperless.example.com';

class _Reply {
  const _Reply(this.status, [this.body, this.headers = const {}]);
  final int status;
  final Object? body;
  final Map<String, List<String>> headers;
}

class _RouteAdapter implements HttpClientAdapter {
  _RouteAdapter(this.routes);

  final Map<String, _Reply> routes;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.uri.path == _unreachable) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
      );
    }
    final reply = routes[options.uri.path] ?? const _Reply(404);
    return ResponseBody.fromString(
      reply.body == null ? '' : jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...reply.headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeAuthorize {
  _FakeAuthorize(this.idToken);

  final String? idToken;
  String? clientId;
  String? discoveryUrl;
  List<String>? scopes;

  Future<String?> call({
    required String clientId,
    required String discoveryUrl,
    required List<String> scopes,
  }) async {
    this.clientId = clientId;
    this.discoveryUrl = discoveryUrl;
    this.scopes = scopes;
    return idToken;
  }
}

const _provider = SsoProvider(
  id: 'authentik',
  name: 'Authentik',
  clientId: 'paperless-client',
  openidConfigurationUrl:
      'https://auth.example.com/application/o/paperless/.well-known/openid-configuration',
);

const _configPath = '/api/auth/headless/app/v1/config';
const _loginPath = '/accounts/login/';
const _redirectPath = '/api/auth/headless/browser/v1/auth/provider/redirect';
const _tokenPath = '/api/auth/headless/app/v1/auth/provider/token';

var _unreachable = '';

const _csrfReply = _Reply(200, null, {
  'set-cookie': ['csrftoken=csrf123; Path=/; SameSite=Lax'],
});

_Reply _redirectTo(String location) => _Reply(302, null, {
  'location': [location],
});

void main() {
  late SecureStorageService storage;

  setUp(() {
    _unreachable = '';
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    storage = SecureStorageService(storage: const FlutterSecureStorage());
  });

  (AuthService, _RouteAdapter) build(
    Map<String, _Reply> routes, [
    _FakeAuthorize? authorize,
  ]) {
    final adapter = _RouteAdapter(routes);
    final service = AuthService(
      storage: storage,
      dioFactory: (url) =>
          DioClient.createUnauthenticated(url)..httpClientAdapter = adapter,
      ssoAuthorize: (authorize ?? _FakeAuthorize('id-token')).call,
    );
    return (service, adapter);
  }

  group('fetchSsoProviders', () {
    test(
      'keeps only complete providers with the provider_token flow',
      () async {
        final (service, _) = build({
          _configPath: const _Reply(200, {
            'data': {
              'socialaccount': {
                'providers': [
                  {
                    'id': 'authentik',
                    'name': 'Authentik',
                    'flows': ['provider_redirect', 'provider_token'],
                    'client_id': 'paperless-client',
                    'openid_configuration_url': 'https://auth.example.com/oidc',
                  },
                  {
                    'id': 'redirect-only',
                    'name': 'Redirect only',
                    'flows': ['provider_redirect'],
                    'client_id': 'x',
                    'openid_configuration_url': 'https://idp.example.com/oidc',
                  },
                  {
                    'id': 'github',
                    'name': 'GitHub',
                    'flows': ['provider_token'],
                    'client_id': 'gh',
                  },
                ],
              },
            },
          }),
        });

        final providers = await service.fetchSsoProviders(_server);

        expect(providers.map((p) => p.id), ['authentik']);
        expect(providers.single.clientId, 'paperless-client');
        expect(
          providers.single.openidConfigurationUrl,
          'https://auth.example.com/oidc',
        );
      },
    );

    test('a server without headless endpoints has no providers', () async {
      final (service, _) = build({});

      expect(await service.fetchSsoProviders(_server), isEmpty);
    });

    test('an unexpected config shape has no providers', () async {
      final (service, _) = build({
        _configPath: const _Reply(200, {'status': 200}),
      });

      expect(await service.fetchSsoProviders(_server), isEmpty);
    });
  });

  group('loginWithSso', () {
    test(
      'requests the scope Paperless uses and stores the API token',
      () async {
        final authorize = _FakeAuthorize('id-token');
        final (service, adapter) = build({
          _loginPath: _csrfReply,
          _redirectPath: _redirectTo(
            'https://auth.example.com/authorize?client_id=paperless-client'
            '&scope=openid+profile+email+groups&state=abc',
          ),
          _tokenPath: const _Reply(200, {
            'status': 200,
            'meta': {'access_token': 'api-token', 'is_authenticated': true},
          }),
        }, authorize);

        final token = await service.loginWithSso(_server, _provider);

        expect(token, 'api-token');
        expect(authorize.clientId, 'paperless-client');
        expect(authorize.discoveryUrl, _provider.openidConfigurationUrl);
        expect(authorize.scopes, ['openid', 'profile', 'email', 'groups']);

        final redirect = adapter.requests.firstWhere(
          (r) => r.uri.path == _redirectPath,
        );
        expect(redirect.headers['X-CSRFToken'], 'csrf123');
        expect(redirect.headers['Cookie'], 'csrftoken=csrf123');
        expect(redirect.data, containsPair('provider', 'authentik'));
        expect(redirect.data, containsPair('process', 'login'));

        final exchange = adapter.requests.firstWhere(
          (r) => r.uri.path == _tokenPath,
        );
        expect(exchange.data, {
          'provider': 'authentik',
          'process': 'login',
          'token': {'client_id': 'paperless-client', 'id_token': 'id-token'},
        });

        expect(await service.getSavedCredentials(), (
          serverUrl: _server,
          token: 'api-token',
        ));
      },
    );

    test(
      'falls back to the default scopes when Paperless gives none',
      () async {
        final authorize = _FakeAuthorize('id-token');
        final (service, _) = build({
          _loginPath: _csrfReply,
          _redirectPath: _redirectTo('https://auth.example.com/authorize'),
          _tokenPath: const _Reply(200, {
            'meta': {'access_token': 'api-token'},
          }),
        }, authorize);

        await service.loginWithSso(_server, _provider);

        expect(authorize.scopes, ssoFallbackScopes);
      },
    );

    test('reads a CSRF cookie with a PAPERLESS_COOKIE_PREFIX', () async {
      final authorize = _FakeAuthorize('id-token');
      final (service, adapter) = build({
        _loginPath: const _Reply(200, null, {
          'set-cookie': ['paperless_csrftoken=csrf456; Path=/'],
        }),
        _redirectPath: _redirectTo(
          'https://auth.example.com/authorize?scope=email%20openid%20profile',
        ),
        _tokenPath: const _Reply(200, {
          'meta': {'access_token': 'api-token'},
        }),
      }, authorize);

      await service.loginWithSso(_server, _provider);

      final redirect = adapter.requests.firstWhere(
        (r) => r.uri.path == _redirectPath,
      );
      expect(redirect.headers['Cookie'], 'paperless_csrftoken=csrf456');
      expect(redirect.headers['X-CSRFToken'], 'csrf456');
      expect(authorize.scopes, ['email', 'openid', 'profile']);
    });

    test('falls back to the default scopes without a CSRF cookie', () async {
      final authorize = _FakeAuthorize('id-token');
      final (service, adapter) = build({
        _loginPath: const _Reply(200),
        _tokenPath: const _Reply(200, {
          'meta': {'access_token': 'api-token'},
        }),
      }, authorize);

      await service.loginWithSso(_server, _provider);

      expect(authorize.scopes, ssoFallbackScopes);
      expect(
        adapter.requests.map((r) => r.uri.path),
        isNot(contains(_redirectPath)),
      );
    });

    test('an app client ID logs in as that client with the Paperless audience, '
        'but exchanges with the Paperless client ID', () async {
      final authorize = _FakeAuthorize('id-token');
      final (service, adapter) = build({
        _tokenPath: const _Reply(200, {
          'meta': {'access_token': 'api-token'},
        }),
      }, authorize);

      await service.loginWithSso(
        _server,
        _provider,
        appClientId: 'paperless-go',
      );

      expect(authorize.clientId, 'paperless-go');
      expect(authorize.scopes, [
        ...ssoFallbackScopes,
        'audience:server:client_id:paperless-client',
      ]);
      final exchange = adapter.requests.firstWhere(
        (r) => r.uri.path == _tokenPath,
      );
      expect(
        (exchange.data as Map)['token'],
        containsPair('client_id', 'paperless-client'),
      );
    });

    test('closing the browser returns null and calls no exchange', () async {
      final (service, adapter) = build({}, _FakeAuthorize(null));

      expect(await service.loginWithSso(_server, _provider), isNull);
      expect(
        adapter.requests.map((r) => r.uri.path),
        isNot(contains(_tokenPath)),
      );
      expect(await service.getSavedCredentials(), isNull);
    });

    Future<String> errorFor(_Reply reply) async {
      final (service, _) = build({_tokenPath: reply});
      try {
        await service.loginWithSso(_server, _provider);
      } on AuthException catch (e) {
        expect(await service.getSavedCredentials(), isNull);
        return e.message;
      }
      fail('expected AuthException');
    }

    test('a pending second factor names two-factor login', () async {
      final message = await errorFor(
        const _Reply(401, {
          'status': 401,
          'data': {
            'flows': [
              {'id': 'mfa_authenticate', 'is_pending': true},
            ],
          },
          'meta': {'is_authenticated': false, 'session_token': 's'},
        }),
      );

      expect(message, contains('two-factor'));
    });

    test('a refused or pending signup asks for the admin', () async {
      for (final status in [401, 403, 409]) {
        final message = await errorFor(_Reply(status, const {'status': 0}));
        expect(
          message,
          contains('Ask your Paperless admin'),
          reason: '$status',
        );
      }
    });

    test('an invalid token points at the SSO setup', () async {
      final message = await errorFor(
        const _Reply(400, {
          'status': 400,
          'errors': [
            {'code': 'invalid_token', 'param': 'token'},
          ],
        }),
      );

      expect(message, contains('SSO setup'));
    });

    test(
      'a network failure during the exchange reports the connection error',
      () async {
        _unreachable = _tokenPath;
        expect(await errorFor(const _Reply(200)), 'Connection timed out');
      },
    );

    test('a server error reports the status', () async {
      expect(await errorFor(const _Reply(500)), 'Server returned HTTP 500');
    });
  });

  group('AuthState.loginWithSso', () {
    ProviderContainer containerWith(_FakeAuthorize authorize) {
      final adapter = _RouteAdapter({
        _tokenPath: const _Reply(200, {
          'meta': {'access_token': 'api-token'},
        }),
      });
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(
            AuthService(
              storage: storage,
              dioFactory: (url) =>
                  DioClient.createUnauthenticated(url)
                    ..httpClientAdapter = adapter,
              ssoAuthorize: authorize.call,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(authStateProvider, (_, _) {});
      return container;
    }

    test(
      'closing the browser leaves the user signed out without an error',
      () async {
        final container = containerWith(_FakeAuthorize(null));
        await container.read(authStateProvider.future);

        await container
            .read(authStateProvider.notifier)
            .loginWithSso(_server, _provider);

        expect(
          container.read(authStateProvider).valueOrNull?.isAuthenticated,
          isFalse,
        );
      },
    );

    test('a successful login signs the user in with the API token', () async {
      final container = containerWith(_FakeAuthorize('id-token'));
      await container.read(authStateProvider.future);

      await container
          .read(authStateProvider.notifier)
          .loginWithSso(_server, _provider);

      final status = container.read(authStateProvider).valueOrNull;
      expect(status?.token, 'api-token');
      expect(status?.serverUrl, _server);
    });
  });
}
