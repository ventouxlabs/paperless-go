import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/design_tokens.dart';
import 'ai_suggestions_prefill.dart';

/// The `topSlot` of the metadata sheet after "Suggest with AI": what the AI
/// proposed that the sheet's own fields can't show. Everything here is
/// information only, except the "Use this title" box (off by default). The
/// header keeps the box's state itself and reports each change through
/// [onUseTitleChanged].
class AiSuggestionsHeader extends StatefulWidget {
  const AiSuggestionsHeader({
    super.key,
    required this.prefill,
    required this.onUseTitleChanged,
  });

  final AiSuggestionsPrefill prefill;
  final ValueChanged<bool> onUseTitleChanged;

  @override
  State<AiSuggestionsHeader> createState() => _AiSuggestionsHeaderState();
}

class _AiSuggestionsHeaderState extends State<AiSuggestionsHeader> {
  bool _useTitle = false;

  @override
  Widget build(BuildContext context) {
    final prefill = widget.prefill;
    final tokens = AppTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final hint = textTheme.bodySmall?.copyWith(color: tokens.inkSoft);
    final title = prefill.suggestedTitle;
    final dateFormat = DateFormat.yMMMd();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 18, color: tokens.accentEmphasis),
            const SizedBox(width: Spacing.sm),
            Text('AI suggestions', style: textTheme.titleSmall),
          ],
        ),
        if (title != null) ...[
          const SizedBox(height: Spacing.sm),
          Text('Title', style: hint),
          Text(title, style: textTheme.bodyLarge),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Use this title'),
            value: _useTitle,
            onChanged: (value) {
              setState(() => _useTitle = value ?? false);
              widget.onUseTitleChanged(_useTitle);
            },
          ),
        ],
        if (prefill.dates.isNotEmpty) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            'Dates in the document: '
            '${prefill.dates.map(dateFormat.format).join(' · ')}',
            style: textTheme.bodyMedium,
          ),
          Text("Info only: the document date isn't changed.", style: hint),
        ],
        if (prefill.correspondentDisagreement case final name?)
          _line(context, 'AI suggests correspondent: $name'),
        if (prefill.documentTypeDisagreement case final name?)
          _line(context, 'AI suggests document type: $name'),
        if (prefill.storagePathNames.isNotEmpty) ...[
          _line(
            context,
            'AI suggests storage path: '
            '${prefill.storagePathNames.join(', ')}',
          ),
          Text("Not set here: this sheet doesn't edit storage paths.",
              style: hint),
        ],
        if (prefill.hasNewNames)
          ..._byKind(
            context,
            heading: 'Not in your library',
            correspondents: prefill.newCorrespondentNames,
            documentTypes: prefill.newDocumentTypeNames,
            tags: prefill.newTagNames,
            storagePaths: prefill.newStoragePathNames,
            footer: Text('Create them in Paperless first to use them.',
                style: hint),
          ),
        if (prefill.hasUnknownIds)
          ..._byKind(
            context,
            // They exist on the server; this app's lists don't have them yet.
            heading: 'Not loaded in the app yet — try again later',
            correspondents: _ids(prefill.unknownCorrespondentIds),
            documentTypes: _ids(prefill.unknownDocumentTypeIds),
            tags: _ids(prefill.unknownTagIds),
            storagePaths: _ids(prefill.unknownStoragePathIds),
          ),
      ],
    );
  }

  List<String> _ids(List<int> ids) => [for (final id in ids) '#$id'];

  List<Widget> _byKind(
    BuildContext context, {
    required String heading,
    required List<String> correspondents,
    required List<String> documentTypes,
    required List<String> tags,
    required List<String> storagePaths,
    Widget? footer,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return [
      const SizedBox(height: Spacing.md),
      Text(heading, style: textTheme.labelLarge),
      for (final (kind, names) in [
        ('Correspondents', correspondents),
        ('Document types', documentTypes),
        ('Tags', tags),
        ('Storage paths', storagePaths),
      ])
        if (names.isNotEmpty)
          Text('$kind: ${names.join(', ')}', style: textTheme.bodyMedium),
      if (footer != null) footer,
    ];
  }

  Widget _line(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: Spacing.sm),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      );
}
