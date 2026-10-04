import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/server_capabilities.dart';
import '../../../core/models/document.dart';

/// "Suggest with AI" needs the server's AI module switched on and change
/// permission on THIS document. `userCanChange` is null when the server
/// didn't say (older servers, `full_perms` responses): hidden, fail closed.
bool canSuggestWithAi(ServerCapabilities capabilities, Document document) =>
    capabilities.canRequestAiSuggestions && document.userCanChange == true;

/// The actions-sheet entry. Renders nothing unless [canSuggestWithAi].
///
/// The capabilities are read once, when the sheet builds the tile: if they
/// arrive while the sheet is open, the tile doesn't pop in under the user's
/// finger. The next time the sheet opens it's there.
class SuggestWithAiTile extends ConsumerStatefulWidget {
  const SuggestWithAiTile({
    super.key,
    required this.document,
    required this.onTap,
  });

  final Document document;
  final VoidCallback onTap;

  @override
  ConsumerState<SuggestWithAiTile> createState() => _SuggestWithAiTileState();
}

class _SuggestWithAiTileState extends ConsumerState<SuggestWithAiTile> {
  late final bool _visible;

  @override
  void initState() {
    super.initState();
    _visible = canSuggestWithAi(
      ref.read(effectiveServerCapabilitiesProvider),
      widget.document,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return ListTile(
      leading: const Icon(Icons.auto_awesome_outlined),
      title: const Text('Suggest with AI'),
      subtitle: const Text(
        "Sends this document's text to your server's AI provider",
      ),
      onTap: widget.onTap,
    );
  }
}

/// Call once from a screen's `initState`. Starts reading the server's
/// capabilities if nothing has yet, and if that read failed (e.g. the app
/// started offline) asks again ONCE for this screen, so "Suggest with AI" can
/// appear without an app restart. A success is never refreshed, so the action
/// doesn't flicker; nor is a 401/403 (asking again gives the same answer).
/// The listener stops when the screen is disposed.
void refreshServerCapabilitiesOnceOnError(WidgetRef ref) {
  var refreshed = false;
  ref.listenManual<AsyncValue<ServerCapabilities>>(serverCapabilitiesProvider, (
    _,
    next,
  ) {
    if (refreshed || !next.hasError || next.isLoading) return;
    if (_isAuthError(next.error)) return;
    refreshed = true;
    // Deferred: with fireImmediately this can run inside initState.
    scheduleMicrotask(() {
      if (ref.context.mounted) ref.invalidate(serverCapabilitiesProvider);
    });
  }, fireImmediately: true);
}

bool _isAuthError(Object? error) {
  final status = error is DioException ? error.response?.statusCode : null;
  return status == 401 || status == 403;
}
