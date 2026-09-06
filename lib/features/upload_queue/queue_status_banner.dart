import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';
import 'upload_queue_notifier.dart';

/// Tells the user what the upload queue is doing, without nagging.
///
/// The queue was silent before this: a document could fail every retry and then
/// sit on disk indefinitely with nothing on screen. A badge in Settings alone
/// does not fix that — nobody opens Settings to check for a problem they have
/// not been told about.
///
/// Two voices, so the loud one keeps its meaning:
/// - a row that needs a decision (failed or legacy) gets the error-coloured
///   banner with a dismiss for this visit;
/// - rows that are merely waiting get a quiet, neutral, tappable line that
///   says how many and opens the queue. It cannot be dismissed, because
///   "what is still on the phone?" is the question it exists to answer, and it
///   disappears on its own once the queue drains.
class QueueStatusBanner extends ConsumerStatefulWidget {
  const QueueStatusBanner({super.key});

  @override
  ConsumerState<QueueStatusBanner> createState() => _QueueStatusBannerState();
}

class _QueueStatusBannerState extends ConsumerState<QueueStatusBanner> {
  /// Dismissal is per-visit, not persisted. A document the app is holding and
  /// cannot deliver is worth raising again next launch; remembering the
  /// dismissal forever is how it goes quiet again.
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(uploadsNeedingAttentionProvider);
    if (count == 0 || _dismissed) {
      return _WaitingLine(count: ref.watch(uploadsWaitingProvider));
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Spacing.lg, Spacing.sm, Spacing.sm, Spacing.sm),
        child: Row(
          children: [
            Icon(Icons.upload_file_outlined,
                size: 20, color: colorScheme.onErrorContainer),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                count == 1
                    ? '1 upload never reached your server'
                    : '$count uploads never reached your server',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/upload-queue'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onErrorContainer,
              ),
              child: const Text('Review'),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: colorScheme.onErrorContainer,
              tooltip: 'Dismiss',
              onPressed: () => setState(() => _dismissed = true),
            ),
          ],
        ),
      ),
    );
  }
}

/// The quiet voice: how many uploads are still on the phone, and a way in.
class _WaitingLine extends StatelessWidget {
  const _WaitingLine({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    final tokens = AppTokens.of(context);
    // "Not sent yet" is true whether the row is queued, retrying, or being
    // uploaded this second; "waiting" would be wrong for the last one.
    final label =
        count == 1 ? '1 upload not sent yet' : '$count uploads not sent yet';
    return Semantics(
      button: true,
      label: '$label. View upload queue',
      child: Material(
        color: tokens.card,
        child: InkWell(
          onTap: () => context.push('/upload-queue'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Row(
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 20, color: tokens.inkSoft),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: ExcludeSemantics(
                      child: Text(
                        label,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: tokens.inkSoft),
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: Text('View',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: tokens.accentEmphasis)),
                  ),
                  const SizedBox(width: Spacing.xs),
                  Icon(Icons.chevron_right, size: 18, color: tokens.inkSoft),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
