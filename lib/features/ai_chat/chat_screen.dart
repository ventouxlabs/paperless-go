import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design_tokens.dart';
import '../../shared/widgets/stamp_chip.dart';
import 'chat_notifier.dart';
import 'chat_service.dart';
import 'native_chat_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int? documentId;
  final String? documentTitle;

  const ChatScreen({super.key, this.documentId, this.documentTitle});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _initialized = false;

  bool get _isDocumentMode => widget.documentId != null;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final chatState = ref.watch(chatNotifierProvider);
    final isConfigured = ref.watch(chatAvailableProvider);
    final usesNativeChat = ref.watch(nativeChatAvailableProvider);

    // Mode initialization
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDocumentMode) {
          ref
              .read(chatNotifierProvider.notifier)
              .initDocumentMode(
                widget.documentId!,
                widget.documentTitle ?? 'Document',
              );
        } else {
          // Reset to RAG mode in case notifier was left in document mode
          ref.read(chatNotifierProvider.notifier).resetToRagMode();
        }
      });
    }

    // Listen for errors
    ref.listen(chatNotifierProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(next.error!)));
        }
        ref.read(chatNotifierProvider.notifier).dismissError();
      }
      // Scroll to bottom on new messages or streaming updates
      if (next.messages.length > (prev?.messages.length ?? 0) ||
          (next.messages.isNotEmpty &&
              prev != null &&
              prev.messages.isNotEmpty &&
              next.messages.last.content != prev.messages.last.content)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    final appBarTitle = _isDocumentMode
        ? widget.documentTitle ?? 'Document Chat'
        : 'AI Chat';

    // Clear-chat and settings collapse into a single overflow menu so the
    // input's send button remains the one obvious primary action.
    final showClear = chatState.messages.isNotEmpty;
    final showSettings = !_isDocumentMode;

    return Scaffold(
      backgroundColor: tokens.paper,
      appBar: AppBar(
        title: Text(appBarTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (showClear || showSettings)
            PopupMenuButton<_ChatMenuAction>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More',
              onSelected: (action) {
                switch (action) {
                  case _ChatMenuAction.clear:
                    ref.read(chatNotifierProvider.notifier).clearHistory();
                  case _ChatMenuAction.settings:
                    context.push('/settings');
                }
              },
              itemBuilder: (context) => [
                if (showClear)
                  const PopupMenuItem(
                    value: _ChatMenuAction.clear,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.delete_sweep_outlined),
                      title: Text('Clear chat'),
                    ),
                  ),
                if (showSettings)
                  const PopupMenuItem(
                    value: _ChatMenuAction.settings,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.settings_outlined),
                      title: Text('Settings'),
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: !isConfigured
          ? _buildNotConfigured(context)
          : Column(
              children: [
                Expanded(
                  child: chatState.messages.isEmpty
                      ? _buildEmptyChat(context, usesNativeChat)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.md,
                            vertical: Spacing.sm,
                          ),
                          itemCount:
                              chatState.messages.length +
                              (chatState.isLoading &&
                                      (chatState.mode == ChatMode.rag ||
                                          chatState.messages.isEmpty ||
                                          chatState
                                              .messages
                                              .last
                                              .content
                                              .isEmpty)
                                  ? 1
                                  : 0),
                          itemBuilder: (_, i) {
                            if (i >= chatState.messages.length) {
                              return _buildTypingIndicator(context);
                            }
                            final message = chatState.messages[i];
                            // Skip empty placeholder messages (streaming will fill them)
                            if (message.role == 'assistant' &&
                                message.content.isEmpty) {
                              return _buildTypingIndicator(context);
                            }
                            return _MessageBubble(
                              message: message,
                              onDocumentTap: (docId) =>
                                  context.push('/documents/$docId'),
                            );
                          },
                        ),
                ),
                _buildInputBar(context, chatState.isLoading, usesNativeChat),
              ],
            ),
    );
  }

  Widget _buildNotConfigured(BuildContext context) {
    final tokens = AppTokens.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.smart_toy_outlined, size: 64, color: tokens.inkSoft),
                const SizedBox(height: Spacing.lg),
                Text(
                  'AI Chat not configured',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  'Enable AI on your Paperless server, or set up a Paperless-AI URL in settings to start chatting about your documents.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: tokens.inkSoft),
                ),
                const SizedBox(height: Spacing.xl),
                FilledButton.icon(
                  onPressed: () => context.push('/settings'),
                  icon: const Icon(Icons.settings),
                  label: const Text('Open Settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChat(BuildContext context, bool usesNativeChat) {
    final tokens = AppTokens.of(context);
    final icon = _isDocumentMode
        ? Icons.chat_bubble_outline
        : Icons.auto_awesome;
    final title = _isDocumentMode
        ? 'Ask questions about this document'
        : 'Ask about your documents';
    final subtitle = _isDocumentMode
        ? 'Chat with AI to understand, summarize, and explore this document.'
        : 'Chat with AI to search, summarize, and understand your documents.';
    final guidance = usesNativeChat
        ? 'Each question is answered independently, so include any context you need.'
        : null;

    final suggestions = _isDocumentMode
        ? [
            'Summarize this document',
            'What are the key points?',
            'Extract important dates',
          ]
        : [
            'Summarize recent invoices',
            'What tax documents do I have?',
            'Find contracts expiring soon',
          ];

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xxl),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 64, color: tokens.accentEmphasis),
                const SizedBox(height: Spacing.lg),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: Spacing.sm),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: tokens.inkSoft),
                ),
                if (guidance != null) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    guidance,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: tokens.inkSoft),
                  ),
                ],
                const SizedBox(height: Spacing.xl),
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.xs,
                  alignment: WrapAlignment.center,
                  children: suggestions
                      .map(
                        (s) =>
                            StampChip(label: s, onTap: () => _sendMessage(s)),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: Spacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(Radii.lg),
            topRight: Radius.circular(Radii.lg),
            bottomLeft: Radius.circular(Radii.sm),
            bottomRight: Radius.circular(Radii.lg),
          ),
          border: Border.all(color: tokens.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: tokens.accentEmphasis,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              'Thinking...',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tokens.inkSoft),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(
    BuildContext context,
    bool isLoading,
    bool usesNativeChat,
  ) {
    final tokens = AppTokens.of(context);
    final hintText = _isDocumentMode
        ? 'Ask about this document...'
        : 'Ask about your documents...';

    return Container(
      padding: EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.sm,
        Spacing.md,
        Spacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: tokens.paper,
        border: Border(top: BorderSide(color: tokens.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _focusNode,
              enabled: !isLoading,
              style: TextStyle(color: tokens.ink),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: tokens.inkSoft),
                filled: true,
                fillColor: tokens.card,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.pill),
                  borderSide: BorderSide(color: tokens.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.pill),
                  borderSide: BorderSide(color: tokens.accentEmphasis),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.pill),
                  borderSide: BorderSide(color: tokens.line),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.md,
                ),
                isDense: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: isLoading ? null : (_) => _submit(),
              maxLines: 4,
              minLines: 1,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          if (isLoading && usesNativeChat)
            _StopButton(
              onTap: () => ref.read(chatNotifierProvider.notifier).stop(),
            )
          else
            _SendButton(enabled: !isLoading, onTap: _submit),
        ],
      ),
    );
  }

  void _submit() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    if (ref.read(nativeChatAvailableProvider) &&
        text.runes.length > nativeChatMaxQuestionCodePoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Native chat questions can be at most '
            '$nativeChatMaxQuestionCodePoints characters.',
          ),
        ),
      );
      return;
    }
    _sendMessage(text);
  }

  void _sendMessage(String text) {
    _inputController.clear();
    ref.read(chatNotifierProvider.notifier).sendMessage(text);
    _focusNode.requestFocus();
  }
}

enum _ChatMenuAction { clear, settings }

/// The screen's single primary action: an accent-filled circular send button.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final onAccent = tokens.onAccent;
    return Semantics(
      button: true,
      label: 'Send',
      child: Material(
        color: tokens.accentFill,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Icon(Icons.arrow_upward, size: 24, color: onAccent),
          ),
        ),
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Semantics(
      button: true,
      label: 'Stop',
      child: Material(
        color: tokens.accentFill,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Icon(Icons.stop, size: 24, color: tokens.onAccent),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ValueChanged<int> onDocumentTap;

  const _MessageBubble({required this.message, required this.onDocumentTap});

  bool get isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);

    // Asymmetric radius: rounded everywhere except a flat corner on the side
    // the bubble is anchored to (bottom-right for the user, bottom-left for
    // the assistant).
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(Radii.lg),
      topRight: const Radius.circular(Radii.lg),
      bottomLeft: Radius.circular(isUser ? Radii.lg : Radii.sm),
      bottomRight: Radius.circular(isUser ? Radii.sm : Radii.lg),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: Spacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        decoration: BoxDecoration(
          color: isUser ? tokens.accentSoft : tokens.card,
          borderRadius: radius,
          border: isUser ? null : Border.all(color: tokens.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isUser)
              SelectableText(
                message.content,
                style: TextStyle(color: tokens.ink),
              )
            else
              MarkdownBody(
                data: message.content,
                selectable: true,
                onTapLink: (text, href, title) {
                  if (href != null) {
                    launchUrl(Uri.parse(href)).catchError((_) => false);
                  }
                },
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: tokens.ink),
                  a: TextStyle(color: tokens.accentEmphasis),
                  code: TextStyle(
                    backgroundColor: tokens.paper,
                    color: tokens.ink,
                    fontSize: 13,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: tokens.paper,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: tokens.line),
                  ),
                ),
              ),
            // Document references
            if (message.references.isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              Divider(height: 1, color: tokens.line),
              const SizedBox(height: 6),
              Text(
                'Referenced documents:',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: tokens.inkSoft),
              ),
              const SizedBox(height: Spacing.xs),
              ...message.references.map(
                (ref) => InkWell(
                  onTap: () => onDocumentTap(ref.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 14,
                          color: tokens.accentEmphasis,
                        ),
                        const SizedBox(width: Spacing.xs),
                        Flexible(
                          child: Text(
                            ref.title,
                            style: TextStyle(
                              color: tokens.accentEmphasis,
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            // Timestamp
            const SizedBox(height: Spacing.xs),
            Text(
              DateFormat.Hm().format(message.timestamp),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: tokens.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}
