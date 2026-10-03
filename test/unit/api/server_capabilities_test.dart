// Native AI (#44) Phase 0: server capability detection from
// GET /api/ui_settings/ (`settings.ai_enabled`, `permissions`, `settings.version`).
//
// Only the 3.2.1 AI-off fixture is a real capture (taken from a live
// Paperless-ngx 3.2.1 server). Every other shape in this file (AI on, the 2.x
// shape without `ai_enabled`, a view-only user, malformed payloads) is DERIVED
// from it by hand; replace the AI-on one with a live capture when one exists.
//
// Consumers must read `effectiveServerCapabilitiesProvider`: Riverpod keeps the
// previous value on a loading/error rebuild, so gating on
// `serverCapabilitiesProvider` directly would show the PREVIOUS server's
// capabilities while a profile switch is in flight.
//
// Run: flutter test test/unit/api/server_capabilities_test.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_providers.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/core/api/server_capabilities.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';

Map<String, dynamic> _loadFixture(String name) {
  final file = File('test/fixtures/api/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// DERIVED: new map with `settings.ai_enabled` set to [value] (does not mutate
/// [json]).
Map<String, dynamic> _withAiEnabled(Map<String, dynamic> json, Object? value) => {
      ...json,
      'settings': {...(json['settings'] as Map<String, dynamic>), 'ai_enabled': value},
    };

/// Replies with a fixed [status] and [body] to every request. When [gate] is
/// given, every request waits for it to complete before replying.
class _FixedAdapter implements HttpClientAdapter {
  _FixedAdapter(
    this.status,
    this.body, {
    this.contentType = Headers.jsonContentType,
    this.gate,
  });

  final int status;
  final String body;
  final String contentType;
  final Completer<void>? gate;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    await gate?.future;
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: [contentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

PaperlessApi _apiFor(_FixedAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://paperless.example.com/'));
  dio.httpClientAdapter = adapter;
  return PaperlessApi(dio);
}

void main() {
  final fixture = _loadFixture('ui_settings_ai_disabled.json');

  group('ServerCapabilities.fromUiSettings', () {
    test('real 3.2.1 capture, AI off: not enabled, can edit, version parsed', () {
      final caps = ServerCapabilities.fromUiSettings(fixture);

      expect(caps.aiEnabled, isFalse);
      expect(caps.can('change_document'), isTrue);
      expect(caps.version, equals('3.2.1'));
      expect(caps.canRequestAiSuggestions, isFalse);
    });

    test('DERIVED AI-on shape: suggestions can be requested', () {
      final caps = ServerCapabilities.fromUiSettings(_withAiEnabled(fixture, true));

      expect(caps.aiEnabled, isTrue);
      expect(caps.canRequestAiSuggestions, isTrue);
    });

    test('DERIVED 2.x shape (no ai_enabled key): treated as AI off', () {
      final settings = fixture['settings'] as Map<String, dynamic>;
      final legacy = {
        ...fixture,
        'settings': {
          for (final entry in settings.entries)
            if (entry.key != 'ai_enabled') entry.key: entry.value,
        },
      };

      final caps = ServerCapabilities.fromUiSettings(legacy);

      expect(caps.aiEnabled, isFalse);
      expect(caps.canRequestAiSuggestions, isFalse);
    });

    test('DERIVED view-only user (no change_document) with AI on: cannot request suggestions', () {
      final withAi = _withAiEnabled(fixture, true);
      final viewOnly = {
        ...withAi,
        'permissions': [
          for (final p in withAi['permissions'] as List<dynamic>)
            if (p != 'change_document') p,
        ],
      };

      final caps = ServerCapabilities.fromUiSettings(viewOnly);

      expect(caps.aiEnabled, isTrue);
      expect(caps.can('change_document'), isFalse);
      expect(caps.can('view_document'), isTrue);
      expect(caps.canRequestAiSuggestions, isFalse);
    });

    group('DERIVED malformed shapes never throw and fall back to safe defaults', () {
      test('empty object', () {
        final caps = ServerCapabilities.fromUiSettings(const {});

        expect(caps.aiEnabled, isFalse);
        expect(caps.permissions, isEmpty);
        expect(caps.version, isNull);
      });

      test('no settings key keeps permissions', () {
        final caps = ServerCapabilities.fromUiSettings({'permissions': ['change_document']});

        expect(caps.aiEnabled, isFalse);
        expect(caps.can('change_document'), isTrue);
        expect(caps.version, isNull);
      });

      test('settings is not a map', () {
        final caps = ServerCapabilities.fromUiSettings({'settings': 'oops', 'permissions': const []});

        expect(caps.aiEnabled, isFalse);
        expect(caps.version, isNull);
      });

      test('permissions is not a list', () {
        final caps = ServerCapabilities.fromUiSettings({
          ..._withAiEnabled(fixture, true),
          'permissions': 'change_document',
        });

        expect(caps.aiEnabled, isTrue);
        expect(caps.permissions, isEmpty);
        expect(caps.canRequestAiSuggestions, isFalse);
      });

      test('permissions list keeps only string elements', () {
        final caps = ServerCapabilities.fromUiSettings({
          'permissions': ['change_document', 7, null, 'view_document'],
        });

        expect(caps.permissions, equals({'change_document', 'view_document'}));
      });

      test('ai_enabled as the string "true" is not enabled', () {
        final caps = ServerCapabilities.fromUiSettings(_withAiEnabled(fixture, 'true'));

        expect(caps.aiEnabled, isFalse);
        expect(caps.canRequestAiSuggestions, isFalse);
      });

      test('ai_enabled null is not enabled', () {
        final caps = ServerCapabilities.fromUiSettings(_withAiEnabled(fixture, null));

        expect(caps.aiEnabled, isFalse);
      });

      test('version as an int is ignored', () {
        final settings = fixture['settings'] as Map<String, dynamic>;
        final caps = ServerCapabilities.fromUiSettings({
          ...fixture,
          'settings': {...settings, 'version': 3},
        });

        expect(caps.version, isNull);
        expect(caps.aiEnabled, isFalse);
      });
    });

    test('permissions set is unmodifiable', () {
      final caps = ServerCapabilities.fromUiSettings(fixture);

      expect(() => caps.permissions.add('x'), throwsUnsupportedError);
    });

    test('none is AI off with no permissions and no version', () {
      expect(ServerCapabilities.none.aiEnabled, isFalse);
      expect(ServerCapabilities.none.permissions, isEmpty);
      expect(ServerCapabilities.none.version, isNull);
      expect(ServerCapabilities.none.can('change_document'), isFalse);
      expect(ServerCapabilities.none.canRequestAiSuggestions, isFalse);
    });
  });

  group('ServerCapabilities equality', () {
    test('equal for the same fields, whatever the permission order', () {
      const a = ServerCapabilities(aiEnabled: true, permissions: {'a', 'b'}, version: '3.2.1');
      const b = ServerCapabilities(aiEnabled: true, permissions: {'b', 'a'}, version: '3.2.1');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('parsing the same payload twice gives equal values', () {
      expect(
        ServerCapabilities.fromUiSettings(fixture),
        equals(ServerCapabilities.fromUiSettings(fixture)),
      );
    });

    test('differs when any field differs', () {
      const base = ServerCapabilities(aiEnabled: true, permissions: {'a'}, version: '3.2.1');

      expect(base, isNot(equals(const ServerCapabilities(aiEnabled: false, permissions: {'a'}, version: '3.2.1'))));
      expect(base, isNot(equals(const ServerCapabilities(aiEnabled: true, permissions: {'a', 'b'}, version: '3.2.1'))));
      expect(base, isNot(equals(const ServerCapabilities(aiEnabled: true, permissions: {'a'}, version: '3.2.2'))));
      expect(base, isNot(equals(ServerCapabilities.none)));
    });
  });

  group('serverCapabilitiesProvider / effectiveServerCapabilitiesProvider', () {
    ProviderContainer containerFor(PaperlessApi api) {
      final container = ProviderContainer(
        overrides: [paperlessApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('loads capabilities from the server response', () async {
      final container = containerFor(_apiFor(_FixedAdapter(200, jsonEncode(fixture))));

      final caps = await container.read(serverCapabilitiesProvider.future);

      expect(caps.aiEnabled, isFalse);
      expect(caps.permissions, contains('change_document'));
      expect(caps.version, equals('3.2.1'));
      expect(container.read(effectiveServerCapabilitiesProvider), equals(caps));
    });

    test('HTTP 500: could not ask (AsyncError), effective capabilities are none', () async {
      final container = containerFor(
        _apiFor(_FixedAdapter(500, '<html>Server Error</html>', contentType: 'text/html')),
      );

      await expectLater(
        container.read(serverCapabilitiesProvider.future),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 500)),
      );

      expect(container.read(serverCapabilitiesProvider).hasError, isTrue);
      expect(container.read(effectiveServerCapabilitiesProvider), equals(ServerCapabilities.none));
    });

    test('200 with an HTML body (captive portal): AsyncError, effective capabilities are none', () async {
      final container = containerFor(
        _apiFor(_FixedAdapter(200, '<html>Sign in</html>', contentType: 'text/html')),
      );

      await expectLater(
        container.read(serverCapabilitiesProvider.future),
        throwsA(isA<DioException>().having((e) => e.type, 'type', DioExceptionType.badResponse)),
      );

      expect(container.read(effectiveServerCapabilitiesProvider), equals(ServerCapabilities.none));
    });

    test('a body that is not valid JSON under a JSON content type: AsyncError, effective is none', () async {
      // Dio's transformer throws a FormatException-backed DioException here,
      // before getUiSettings sees any data.
      final container = containerFor(_apiFor(_FixedAdapter(200, '<html>captive portal</html>')));

      await expectLater(
        container.read(serverCapabilitiesProvider.future),
        throwsA(isA<DioException>()),
      );

      expect(container.read(effectiveServerCapabilitiesProvider), equals(ServerCapabilities.none));
    });

    test('signed out (no session): effective capabilities are none and nothing throws', () async {
      final container = ProviderContainer(
        overrides: [
          paperlessApiProvider.overrideWith((ref) => throw const NotAuthenticatedException()),
        ],
      );
      addTearDown(container.dispose);
      final effective = container.listen(effectiveServerCapabilitiesProvider, (_, __) {});

      await expectLater(
        container.read(serverCapabilitiesProvider.future),
        throwsA(isA<NotAuthenticatedException>()),
      );

      expect(container.read(serverCapabilitiesProvider).hasError, isTrue);
      expect(effective.read(), equals(ServerCapabilities.none));
    });

    test('keepAlive: capabilities are fetched once, even after every listener has gone', () async {
      final adapter = _FixedAdapter(200, jsonEncode(fixture));
      final container = containerFor(_apiFor(adapter));

      final first = container.listen(effectiveServerCapabilitiesProvider, (_, __) {});
      await container.read(serverCapabilitiesProvider.future);
      expect(first.read().version, equals('3.2.1'));

      // Dropping the only listener disposes the autoDispose derived provider
      // (on a microtask). An autoDispose base provider would go with it.
      first.close();
      await Future<void>.delayed(Duration.zero);

      final second = container.listen(effectiveServerCapabilitiesProvider, (_, __) {});
      await container.read(serverCapabilitiesProvider.future);

      expect(second.read().version, equals('3.2.1'));
      expect(adapter.requestCount, equals(1));
    });

    group('switching servers (profile switch / re-login)', () {
      late StateProvider<PaperlessApi> currentApi;
      late ProviderContainer container;
      late ProviderSubscription<ServerCapabilities> effective;

      Future<void> startOn(PaperlessApi first) async {
        currentApi = StateProvider<PaperlessApi>((ref) => first);
        container = ProviderContainer(
          overrides: [paperlessApiProvider.overrideWith((ref) => ref.watch(currentApi))],
        );
        addTearDown(container.dispose);
        // Hold the autoDispose derived provider open, as a mounted screen would.
        effective = container.listen(effectiveServerCapabilitiesProvider, (_, __) {});
        await container.read(serverCapabilitiesProvider.future);
      }

      void switchTo(PaperlessApi next) => container.read(currentApi.notifier).state = next;

      test('while the new server is still loading, the old server capabilities are not shown', () async {
        await startOn(_apiFor(_FixedAdapter(200, jsonEncode(_withAiEnabled(fixture, true)))));
        expect(effective.read().aiEnabled, isTrue);

        final gate = Completer<void>();
        switchTo(_apiFor(_FixedAdapter(200, jsonEncode(fixture), gate: gate)));

        // Riverpod keeps the AI-on value as `previous` on this AsyncLoading.
        expect(effective.read(), equals(ServerCapabilities.none));

        gate.complete();
        await container.read(serverCapabilitiesProvider.future);

        expect(effective.read().aiEnabled, isFalse);
        expect(effective.read().version, equals('3.2.1'));
      });

      test('when the new server cannot be asked, the old server capabilities are not shown', () async {
        await startOn(_apiFor(_FixedAdapter(200, jsonEncode(_withAiEnabled(fixture, true)))));
        expect(effective.read().aiEnabled, isTrue);

        switchTo(_apiFor(_FixedAdapter(500, 'boom', contentType: 'text/plain')));
        await expectLater(container.read(serverCapabilitiesProvider.future), throwsA(isA<DioException>()));

        // Riverpod keeps the AI-on value as `previous` on this AsyncError.
        expect(container.read(serverCapabilitiesProvider).hasError, isTrue);
        expect(effective.read(), equals(ServerCapabilities.none));
      });
    });
  });
}
