import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'api_providers.dart';

part 'server_capabilities.g.dart';

/// What the connected Paperless-ngx server (and the signed-in user) can do,
/// read from `GET api/ui_settings/`.
class ServerCapabilities {
  const ServerCapabilities({
    required this.aiEnabled,
    required this.permissions,
    required this.version,
  });

  /// Fail-closed default: no AI, no permissions. Used when the capabilities
  /// can't be read, so AI UI stays hidden.
  static const none = ServerCapabilities(
    aiEnabled: false,
    permissions: <String>{},
    version: null,
  );

  /// Parses the `ui_settings` payload. Never throws on an odd shape: anything
  /// missing or of the wrong type falls back to the [none] values.
  factory ServerCapabilities.fromUiSettings(Map<String, dynamic> json) {
    final rawSettings = json['settings'];
    final settings = rawSettings is Map ? rawSettings : null;
    final rawPermissions = json['permissions'];
    final rawVersion = settings?['version'];
    return ServerCapabilities(
      // Paperless-ngx 2.x has no `ai_enabled` key: a missing key means off.
      aiEnabled: settings?['ai_enabled'] == true,
      permissions: rawPermissions is List
          ? Set<String>.unmodifiable(rawPermissions.whereType<String>())
          : const <String>{},
      version: rawVersion is String ? rawVersion : null,
    );
  }

  /// `settings.ai_enabled`. This only says AI is switched on server-side, not
  /// that a model or embedding index is configured.
  final bool aiEnabled;

  /// Django permission codenames granted to the user (e.g. `change_document`).
  final Set<String> permissions;

  /// `settings.version`, when the server reports one (3.x).
  final String? version;

  bool can(String codename) => permissions.contains(codename);

  /// Necessary, not sufficient: the server also checks change permission on the
  /// specific document (object permissions), so gate the UI on the document's
  /// own permission too.
  bool get canRequestAiSuggestions => aiEnabled && can('change_document');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerCapabilities &&
          aiEnabled == other.aiEnabled &&
          version == other.version &&
          setEquals(permissions, other.permissions);

  @override
  int get hashCode =>
      Object.hash(aiEnabled, version, Object.hashAllUnordered(permissions));
}

/// Raw result of asking the active server for its capabilities. Watches
/// [paperlessApiProvider], so it rebuilds on login, logout and profile switch;
/// nothing invalidates it manually.
///
/// A failed request is rethrown, so an error state means "couldn't ask", which
/// is not the same as the server saying AI is off (a screen can offer a
/// refresh). UI must NOT gate on this provider or on `.future`: Riverpod keeps
/// the previous value on a loading or error rebuild, so a profile switch would
/// briefly show the previous server's capabilities. Use
/// [effectiveServerCapabilitiesProvider].
@Riverpod(keepAlive: true)
Future<ServerCapabilities> serverCapabilities(Ref ref) async {
  final api = ref.watch(paperlessApiProvider);
  try {
    return ServerCapabilities.fromUiSettings(await api.getUiSettings());
  } on DioException catch (e) {
    debugPrint(
      'Could not read server capabilities (${e.type.name}, '
      'HTTP ${e.response?.statusCode}); AI features stay hidden.',
    );
    rethrow;
  }
}

/// THE API for consumers: the capabilities UI should gate on. Synchronous and
/// fail-closed: it is [ServerCapabilities.none] while loading, after an error
/// and while signed out, and it never carries the previous server's value
/// (`unwrapPrevious` drops it).
@riverpod
ServerCapabilities effectiveServerCapabilities(Ref ref) =>
    ref.watch(serverCapabilitiesProvider).unwrapPrevious().valueOrNull ??
    ServerCapabilities.none;
