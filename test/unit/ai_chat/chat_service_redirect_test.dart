// The Paperless-AI session JWT (Bearer + Cookie) must only ever be sent to the
// origin the user configured. A server-controlled redirect to another origin
// used to receive it.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/ai_chat/chat_service.dart';

/// Replays [script] in order and records every request it sees.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.script);

  final List<ResponseBody Function(RequestOptions)> script;
  final List<RequestOptions> seen = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    seen.add(options);
    return script[seen.length - 1](options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _redirect(String location, {int status = 307}) =>
    ResponseBody.fromString('', status, headers: {
      'location': [location],
    });

ResponseBody _json(Map<String, dynamic> body) =>
    ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });

Future<(ChatService, _ScriptedAdapter)> _loggedIn(
  List<ResponseBody Function(RequestOptions)> script,
) async {
  final adapter = _ScriptedAdapter([
    (_) => ResponseBody.fromString('', 302, headers: {
          'set-cookie': ['jwt=secret-token; Path=/'],
          'location': ['/dashboard'],
        }),
    ...script,
  ]);
  final dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.50:8083/'))
    ..httpClientAdapter = adapter;
  final service = ChatService(dio);
  await service.login('u', 'p');
  adapter.seen.clear();
  adapter.script.removeAt(0);
  return (service, adapter);
}

bool _carriesCredentials(RequestOptions o) =>
    o.headers.containsKey('Authorization') || o.headers.containsKey('Cookie');

void main() {
  group('sendMessage', () {
    test('does not follow a cross-origin redirect or leak the JWT', () async {
      final (service, adapter) = await _loggedIn([
        (_) => _redirect('http://attacker.example/collect'),
        (_) => _json({'answer': 'leaked'}),
      ]);

      await expectLater(service.sendMessage('hi', const []), throwsException);

      expect(adapter.seen, hasLength(1));
      expect(adapter.seen.single.uri.host, '192.168.1.50');
    });

    // Each target differs from http://192.168.1.50:8083 in exactly one of
    // host, port, scheme, so dropping any single comparison fails a case.
    test('refuses a redirect that differs in only one origin component',
        () async {
      for (final target in [
        'http://attacker.example:8083/x', // host only
        'http://192.168.1.50:9999/x', // port only
        'https://192.168.1.50:8083/x', // scheme only
      ]) {
        final (service, adapter) = await _loggedIn([
          (_) => _redirect(target),
          (_) => _json({'answer': 'leaked'}),
        ]);

        await expectLater(service.sendMessage('hi', const []), throwsException);
        expect(adapter.seen, hasLength(1), reason: target);
      }
    });

    test('reports a malformed Location as a refused redirect', () async {
      final (service, adapter) = await _loggedIn([
        (_) => _redirect('http://[bad'),
        (_) => _json({'answer': 'leaked'}),
      ]);

      await expectLater(
        service.sendMessage('hi', const []),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Refused redirect'))),
      );
      expect(adapter.seen, hasLength(1));
    });

    test('follows a same-origin redirect and keeps the credentials', () async {
      final (service, adapter) = await _loggedIn([
        (_) => _redirect('/api/rag/ask2'),
        (_) => _json({'answer': 'ok'}),
      ]);

      final reply = await service.sendMessage('hi', const []);

      expect(reply.content, 'ok');
      expect(adapter.seen, hasLength(2));
      expect(adapter.seen.last.uri.path, '/api/rag/ask2');
      expect(_carriesCredentials(adapter.seen.last), isTrue);
    });

    test('gives up after too many same-origin redirects', () async {
      final (service, adapter) = await _loggedIn([
        for (var i = 0; i < 10; i++) (_) => _redirect('/loop'),
      ]);

      await expectLater(service.sendMessage('hi', const []), throwsException);

      expect(adapter.seen.length, lessThanOrEqualTo(6));
    });
  });

  group('sendDocumentMessage', () {
    test('does not follow a cross-origin redirect or leak the JWT', () async {
      final (service, adapter) = await _loggedIn([
        (_) => _redirect('http://attacker.example/collect'),
        (_) => _json({'content': 'leaked'}),
      ]);

      await expectLater(
        service.sendDocumentMessage(1, 'hi').toList(),
        throwsException,
      );

      expect(adapter.seen, hasLength(1));
    });
  });

  group('sendDocumentMessage stream bodies', () {
    test('closes the body of every redirect hop and of the refused hop',
        () async {
      var closed = 0;
      ResponseBody redirect(String to) => ResponseBody.fromString('', 307,
          headers: {'location': [to]}, onClose: () => closed++);
      final (service, _) = await _loggedIn([
        (_) => redirect('/chat/message2'),
        (_) => redirect('http://attacker.example:8083/x'),
      ]);

      await expectLater(
        service.sendDocumentMessage(1, 'hi').toList(),
        throwsException,
      );

      await Future<void>.delayed(Duration.zero); // whenCancel is async
      expect(closed, 2);
    });
  });

  group('initDocumentChat', () {
    test('does not follow a cross-origin redirect or leak the JWT', () async {
      final (service, adapter) = await _loggedIn([
        (_) => _redirect('http://attacker.example/collect', status: 302),
        (_) => _json({'ok': true}),
      ]);

      await expectLater(service.initDocumentChat(1), throwsException);

      expect(adapter.seen, hasLength(1));
    });
  });
}
