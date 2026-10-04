import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_error_mapper.dart';
import '../../../core/design_tokens.dart';
import '../../../core/models/document.dart';
import '../../../shared/widgets/metadata_sheet.dart';
import 'ai_suggestions_error.dart';
import 'ai_suggestions_header.dart';
import 'ai_suggestions_notifier.dart';
import 'ai_suggestions_prefill.dart';

/// Receives the sheet's result, the document the sheet was opened with (the
/// PATCH must diff against it), and the AI title when "Use this title" was
/// ticked (null otherwise).
typedef AiSuggestionsSave = void Function(
    Document base, MetadataSheetResult result, String? title);

/// The text for each [AiSuggestionsErrorKind]; every error sentence of this
/// feature is here. [cause] only feeds [AiSuggestionsErrorKind.other].
String aiSuggestionsErrorText(AiSuggestionsErrorKind kind, Object? cause) =>
    switch (kind) {
      AiSuggestionsErrorKind.aiDisabled =>
        'AI is turned off on your Paperless server.',
      AiSuggestionsErrorKind.aiMisconfigured =>
        "Your Paperless server's AI settings are invalid. "
            'Ask your server admin to check them.',
      AiSuggestionsErrorKind.cannotEdit =>
        "You can't edit this document, so AI can't suggest changes to it.",
      AiSuggestionsErrorKind.documentGone =>
        'This document no longer exists on the server.',
      AiSuggestionsErrorKind.serverError =>
        'The server hit an error. Its AI service may be unreachable.',
      AiSuggestionsErrorKind.aiRejected =>
        'The AI service rejected the request. Your server admin can find '
            'details in the Paperless logs.',
      AiSuggestionsErrorKind.aiTimedOut =>
        'The AI service timed out. Try again later.',
      AiSuggestionsErrorKind.proxyTimeout =>
        "Your server's proxy stopped waiting for the AI. Try again in a "
            'minute: the server may still finish and keep the answer.',
      AiSuggestionsErrorKind.tooSlow =>
        'The AI took too long to answer. Try again later.',
      AiSuggestionsErrorKind.libraryUnavailable =>
        "Couldn't load your tags, correspondents or document types. "
            'Check your connection and try again.',
      AiSuggestionsErrorKind.libraryForbidden =>
        "Couldn't load your tags, correspondents or document types: your "
            "account isn't allowed to view them.",
      AiSuggestionsErrorKind.failed => _couldNotGetSuggestions,
      AiSuggestionsErrorKind.other =>
        friendlyApiMessage(cause, fallback: _couldNotGetSuggestions),
    };

const _couldNotGetSuggestions = 'Could not get AI suggestions.';

/// "Suggest with AI": asks the server once (cancellable progress dialog), then
/// opens the metadata sheet pre-filled with the usable suggestions, or tells
/// the user nothing would change (with the details one tap away) or what went
/// wrong. Nothing is saved unless the user taps Save in the sheet.
Future<void> showAiSuggestions(
  BuildContext context,
  Document document, {
  required AiSuggestionsSave onSave,
}) async {
  final outcome = await showDialog<AiSuggestionsState>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AiSuggestionsProgressDialog(document: document),
  );
  if (!context.mounted) return;
  switch (outcome) {
    case AiSuggestionsSuccess(document: final base, :final prefill)
        when prefill.hasChanges:
      await _openSheet(context, base, prefill, onSave);
    case AiSuggestionsSuccess(document: final base, :final prefill):
      _showNoChanges(context, base, prefill, onSave);
    case AiSuggestionsFailure(:final kind, :final cause):
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(aiSuggestionsErrorText(kind, cause))));
    case AiSuggestionsIdle() || AiSuggestionsLoading() || null:
      break; // Cancelled (button or back): nothing to say.
  }
}

void _showNoChanges(
  BuildContext context,
  Document base,
  AiSuggestionsPrefill prefill,
  AiSuggestionsSave onSave,
) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: const Text('No changes suggested'),
    // With an action, a SnackBar persists by default until tapped, and every
    // later snackbar in the app would queue behind it.
    persist: false,
    duration: const Duration(seconds: 8),
    action: prefill.hasInfo
        ? SnackBarAction(
            label: 'Details',
            onPressed: () {
              // The snackbar follows the user to other pages; open the sheet
              // only over this document's screen.
              if (!context.mounted) return;
              if (ModalRoute.of(context)?.isCurrent != true) return;
              unawaited(_openSheet(context, base, prefill, onSave));
            },
          )
        : null,
  ));
}

/// Dismissing the sheet (swipe, back) drops the result. That's fine: the
/// server caches suggestions per document, model and user for 50 minutes, so
/// asking again costs no model call.
Future<void> _openSheet(
  BuildContext context,
  Document base,
  AiSuggestionsPrefill prefill,
  AiSuggestionsSave onSave,
) async {
  var useTitle = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => MetadataSheet(
      correspondentId: prefill.correspondentId,
      documentTypeId: prefill.documentTypeId,
      tagIds: prefill.tagIds,
      // Never from the AI's dates: they can be due dates.
      created: base.created,
      suggestedCorrespondent: prefill.suggestedCorrespondent,
      suggestedDocumentType: prefill.suggestedDocumentType,
      suggestedTagIds: prefill.suggestedTagIds,
      topSlot: AiSuggestionsHeader(
        prefill: prefill,
        onUseTitleChanged: (value) => useTitle = value,
      ),
      onSave: (result) =>
          onSave(base, result, useTitle ? prefill.suggestedTitle : null),
    ),
  );
}

/// Starts the request after its first frame and closes itself with the
/// outcome. Closing it any way (Cancel, back) cancels the request at once;
/// it is also the request's only listener, so disposing it cancels too.
class _AiSuggestionsProgressDialog extends ConsumerStatefulWidget {
  const _AiSuggestionsProgressDialog({required this.document});

  final Document document;

  @override
  ConsumerState<_AiSuggestionsProgressDialog> createState() =>
      _AiSuggestionsProgressDialogState();
}

class _AiSuggestionsProgressDialogState
    extends ConsumerState<_AiSuggestionsProgressDialog> {
  late final _provider = aiSuggestionsControllerProvider(widget.document.id);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(_provider.notifier).request(widget.document));
    });
  }

  /// Closes this dialog and nothing else. Navigator.pop() closes whatever is
  /// on top, which is not this dialog once it's closing (Back mid-animation)
  /// or covered by another page.
  void _close([AiSuggestionsState? outcome]) {
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return; // already closing
    if (route.isCurrent) {
      Navigator.of(context).pop(outcome);
    } else {
      // Covered: take the dialog out from under the page on top, with no
      // result (asking again is free, see _openSheet).
      Navigator.of(context).removeRoute(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AiSuggestionsState>(_provider, (_, next) {
      if (next is AiSuggestionsSuccess || next is AiSuggestionsFailure) {
        _close(next);
      }
    });
    ref.watch(_provider);
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(_provider.notifier).cancel();
      },
      child: AlertDialog(
        content: const Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: Spacing.lg),
            Expanded(
              child: Text('Asking AI for suggestions… This can take a minute '
                  'or two.\n\nCancel stops waiting; the server may still '
                  'finish the request.'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(_provider.notifier).cancel();
              _close();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
