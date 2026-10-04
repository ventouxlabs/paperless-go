import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final List<DocumentReference> references;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    this.references = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? role,
    String? content,
    List<DocumentReference>? references,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      references: references ?? this.references,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class DocumentReference {
  final int id;
  final String title;

  const DocumentReference({required this.id, required this.title});
}

class ChatService {
  final Dio _dio;
  String? _jwt;

  ChatService(this._dio);

  /// Login to Paperless-AI and store JWT for subsequent requests.
  Future<void> login(String username, String password) async {
    try {
      final response = await _dio.post(
        'login',
        data: 'username=${Uri.encodeComponent(username)}&password=${Uri.encodeComponent(password)}',
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          validateStatus: (status) => status != null && status < 400,
          followRedirects: false,
        ),
      );

      // Extract JWT from Set-Cookie header
      final cookies = response.headers['set-cookie'];
      if (cookies != null) {
        for (final cookie in cookies) {
          if (cookie.startsWith('jwt=')) {
            final eq = cookie.indexOf('=');
            _jwt = cookie.substring(eq + 1).split(';')[0];
            return;
          }
        }
      }

      // If 302 redirect to dashboard, login succeeded but no cookie parsed
      if (response.statusCode == 302) {
        // Try extracting from the raw header value
        final setCookie = response.headers.value('set-cookie');
        if (setCookie != null && setCookie.contains('jwt=')) {
          _jwt = setCookie.split('jwt=')[1].split(';')[0];
          return;
        }
      }

      // Server returns 200 with HTML login page for invalid credentials
      if (response.statusCode == 200) {
        final body = response.data?.toString() ?? '';
        if (body.contains('Invalid credentials') || body.contains('<html')) {
          throw Exception('Invalid Paperless-AI credentials. Check your username and password in Settings.');
        }
      }

      throw Exception('Login failed: no JWT received from server');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid Paperless-AI credentials');
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Cannot connect to Paperless-AI.');
      }
      throw Exception('Login error: ${e.message}');
    }
  }

  Options _authOptions({
    ResponseType? responseType,
    bool followRedirects = false,
  }) {
    final headers = <String, dynamic>{};
    if (_jwt != null) {
      // Bearer for /chat/* routes, Cookie for /api/rag/* routes
      headers['Authorization'] = 'Bearer $_jwt';
      headers['Cookie'] = 'jwt=$_jwt';
    }
    return Options(
      validateStatus: (status) => status != null && status < 400,
      followRedirects: followRedirects,
      responseType: responseType,
      headers: headers.isNotEmpty ? headers : null,
    );
  }

  /// Send a RAG chat message and get a response.
  /// Uses POST /api/rag/ask with {"question": "..."} → {"answer": "...", "sources": [...]}
  Future<ChatMessage> sendMessage(String message, List<ChatMessage> history) async {
    try {
      final payload = {'question': message};

      var response = await _dio.post(
        'api/rag/ask',
        data: payload,
        options: _authOptions(),
      );

      // Follow redirects manually for POST
      var redirectCount = 0;
      while (response.statusCode == 301 ||
          response.statusCode == 302 ||
          response.statusCode == 307 ||
          response.statusCode == 308) {
        if (++redirectCount > 5) {
          throw Exception('Too many redirects');
        }
        final location = response.headers.value('location');
        if (location == null) {
          throw Exception('Redirect without Location header');
        }
        if (location.contains('/login')) {
          throw Exception('Authentication required. Check your Paperless-AI credentials in Settings.');
        }
        response = await _dio.post(
          location,
          data: payload,
          options: _authOptions(),
        );
      }

      final data = response.data;

      if (data is String) {
        if (data.trimLeft().startsWith('<') || data.trimLeft().startsWith('<!DOCTYPE')) {
          throw Exception('Received HTML instead of JSON. Check your Paperless-AI URL and credentials.');
        }
        return ChatMessage(
          role: 'assistant',
          content: data,
        );
      }

      final responseData = data as Map<String, dynamic>;
      final content = responseData['answer'] as String? ??
          responseData['response'] as String? ??
          responseData['message'] as String? ??
          responseData['content'] as String? ??
          data.toString();

      // Parse document sources if present
      final refs = <DocumentReference>[];
      final sources = responseData['sources'] as List<dynamic>? ??
          responseData['documents'] as List<dynamic>?;
      if (sources != null) {
        for (final doc in sources) {
          if (doc is Map<String, dynamic>) {
            refs.add(DocumentReference(
              id: doc['doc_id'] as int? ?? doc['id'] as int? ?? 0,
              title: doc['title'] as String? ?? 'Unknown',
            ));
          }
        }
      }

      return ChatMessage(
        role: 'assistant',
        content: content,
        references: refs,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('RAG endpoint not found. Check your Paperless-AI URL.');
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Cannot connect to Paperless-AI. Check the URL and ensure the service is running.');
      }
      throw Exception('Chat error: ${e.message}');
    }
  }

  /// Initialize a document chat session.
  Future<void> initDocumentChat(int documentId) async {
    try {
      final response = await _dio.get(
        'chat/init/$documentId',
        options: _authOptions(followRedirects: true),
      );

      // Detect HTML responses (e.g., login page or error page)
      final data = response.data;
      if (data is String) {
        final trimmed = data.trimLeft();
        if (trimmed.startsWith('<') || trimmed.startsWith('<!DOCTYPE')) {
          throw Exception(
            'Received HTML instead of JSON from chat init. Check your Paperless-AI credentials in Settings.',
          );
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Document chat endpoint not found. Check your Paperless-AI URL.');
      }
      if (e.response?.statusCode == 302) {
        final location = e.response?.headers.value('location') ?? '';
        if (location.contains('/login')) {
          throw Exception('Authentication required. Check your Paperless-AI credentials in Settings.');
        }
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Cannot connect to Paperless-AI.');
      }
      throw Exception('Init chat error: ${e.message}');
    }
  }

  /// Send a message for document-specific chat and return an SSE stream of content chunks.
  Stream<String> sendDocumentMessage(int documentId, String message) async* {
    final payload = {
      'documentId': documentId.toString(),
      'message': message,
    };

    try {
      var response = await _dio.post(
        'chat/message',
        data: payload,
        options: _authOptions(responseType: ResponseType.stream),
      );

      // Follow redirects manually for POST with stream
      var redirectCount = 0;
      while (response.statusCode == 301 ||
          response.statusCode == 302 ||
          response.statusCode == 307 ||
          response.statusCode == 308) {
        if (++redirectCount > 5) {
          throw Exception('Too many redirects');
        }
        final location = response.headers.value('location');
        if (location == null) {
          throw Exception('Redirect without Location header');
        }
        if (location.contains('/login')) {
          throw Exception('Authentication required. Check your Paperless-AI credentials in Settings.');
        }
        response = await _dio.post(
          location,
          data: payload,
          options: _authOptions(responseType: ResponseType.stream),
        );
      }

      // Check content-type to detect HTML responses
      final contentType = response.headers.value('content-type') ?? '';
      if (contentType.contains('text/html')) {
        throw Exception(
          'Received HTML instead of SSE stream. Check your Paperless-AI credentials in Settings.',
        );
      }

      final stream = response.data.stream as Stream<List<int>>;
      var accumulated = '';
      var buffer = '';
      var firstChunk = true;

      // Decode as one stream: a chunk can end mid-character, which a
      // per-chunk utf8.decode rejects. bind(), not transform(): the body is
      // a Stream<Uint8List> at runtime, which transform(utf8.decoder) rejects.
      await for (final decoded in utf8.decoder.bind(stream)) {
        // Detect HTML on first chunk
        if (firstChunk) {
          firstChunk = false;
          final trimmed = decoded.trimLeft();
          if (trimmed.startsWith('<') || trimmed.startsWith('<!DOCTYPE')) {
            throw Exception(
              'Received HTML instead of SSE stream. Check your Paperless-AI URL and credentials.',
            );
          }
        }

        // Normalize \r\n to \n for cross-platform SSE parsing
        buffer += decoded.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

        // Process complete SSE lines
        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);

          if (line.isEmpty) continue;

          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();

            if (data == '[DONE]') {
              return;
            }

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final content = json['content'] as String? ?? '';
              if (content.isNotEmpty) {
                accumulated += content;
                yield accumulated;
              }
            } catch (_) {
              // Skip malformed JSON chunks
            }
          }
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Document chat endpoint not found. Check your Paperless-AI URL.');
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Cannot connect to Paperless-AI.');
      }
      throw Exception('Chat error: ${e.message}');
    }
  }
}
