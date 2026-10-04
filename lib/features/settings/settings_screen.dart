import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/server_profiles.dart';
import '../../core/design_tokens.dart';
import '../upload_queue/upload_queue_notifier.dart';
import '../../core/services/biometric_service.dart';
import '../../core/settings/start_screen.dart';
import '../../core/services/export_destination_providers.dart';
import '../../core/services/export_destination_service.dart';
import '../ai_chat/chat_notifier.dart';
import '../../l10n/l10n.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppTokens.of(context);
    final aiUrl = ref.watch(aiChatUrlProvider);
    final authState = ref.watch(authStateProvider).valueOrNull;
    final themeMode = ref.watch(themeModeNotifierProvider);
    final startScreen =
        ref.watch(startScreenProvider).valueOrNull ?? StartScreen.fallback;
    final biometricEnabled = ref.watch(biometricLockProvider);
    final profilesState = ref.watch(serverProfilesNotifierProvider);
    final aiUsername = ref.watch(aiChatUsernameProvider);
    final downloadsDestination = ref.watch(downloadsDestinationProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: tokens.paper,
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Spacing.xxl),
        children: [
          _SettingsSection(
            title: l10n.settingsSectionAccount,
            children: [
              ListTile(
                leading: Icon(Icons.dns_outlined, color: tokens.inkSoft),
                title: Text(l10n.settingsServer),
                subtitle: Text(
                    authState?.serverUrl ?? l10n.settingsServerNotConnected),
              ),
              if (profilesState.profiles.length > 1)
                ...profilesState.profiles.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final profile = entry.value;
                  final isActive = idx == profilesState.activeIndex;
                  return ListTile(
                    leading: Icon(
                      isActive
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isActive ? tokens.accentEmphasis : tokens.inkSoft,
                    ),
                    title: Text(
                        profile.name.isEmpty ? profile.serverUrl : profile.name),
                    subtitle: Text(profile.serverUrl,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: isActive
                        ? null
                        : () => ref
                            .read(serverProfilesNotifierProvider.notifier)
                            .switchToProfile(idx),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: l10n.settingsRemoveProfileTooltip,
                      onPressed: () => ref
                          .read(serverProfilesNotifierProvider.notifier)
                          .removeProfile(idx),
                    ),
                  );
                }),
              ListTile(
                leading: Icon(Icons.add, color: tokens.inkSoft),
                title: Text(l10n.settingsSaveProfile),
                onTap: () => _addProfile(context, ref),
              ),
              ListTile(
                leading: Icon(Icons.logout, color: tokens.stamp),
                title: Text(l10n.settingsSignOut,
                    style: TextStyle(color: tokens.stamp)),
                onTap: () => _signOut(context, ref),
              ),
            ],
          ),
          _SettingsSection(
            title: l10n.settingsSectionAppearance,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.lg, Spacing.md, Spacing.lg, Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_outlined, color: tokens.inkSoft),
                        const SizedBox(width: Spacing.lg),
                        Text(l10n.settingsTheme,
                            style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text(l10n.settingsThemeSystem),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text(l10n.settingsThemeLight),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text(l10n.settingsThemeDark),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (selection) => ref
                            .read(themeModeNotifierProvider.notifier)
                            .setThemeMode(selection.first),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.lg, Spacing.md, Spacing.lg, Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.home_outlined, color: tokens.inkSoft),
                        const SizedBox(width: Spacing.lg),
                        Text(l10n.settingsStartScreen,
                            style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<StartScreen>(
                        showSelectedIcon: false,
                        segments: [
                          for (final screen in StartScreen.values)
                            ButtonSegment(
                              value: screen,
                              label: Text(_startScreenLabel(l10n, screen)),
                            ),
                        ],
                        selected: {startScreen},
                        onSelectionChanged: (selection) =>
                            _setStartScreen(context, ref, selection.first),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          _SettingsSection(
            title: l10n.settingsSectionSecurity,
            children: [
              SwitchListTile(
                secondary: Icon(Icons.fingerprint, color: tokens.inkSoft),
                title: Text(l10n.settingsBiometricLock),
                subtitle: Text(l10n.settingsBiometricLockSubtitle),
                value: biometricEnabled,
                onChanged: (enabled) => _toggleBiometric(context, ref, enabled),
              ),
            ],
          ),
          _SettingsSection(
            title: l10n.settingsSectionStorage,
            children: [
              ListTile(
                leading: Icon(Icons.folder_outlined, color: tokens.inkSoft),
                title: Text(l10n.settingsDownloadFolder),
                subtitle: _DownloadsLocationSubtitle(
                  destination: downloadsDestination,
                  tokens: tokens,
                ),
                trailing: const Icon(Icons.edit, size: 18),
                onTap: () => _chooseDownloadsFolder(context, ref),
              ),
            ],
          ),
          _SettingsSection(
            title: l10n.settingsSectionAiChat,
            children: [
              ListTile(
                leading: Icon(Icons.smart_toy_outlined, color: tokens.inkSoft),
                title: Text(l10n.settingsAiUrl),
                subtitle: Text(
                  aiUrl?.isNotEmpty == true
                      ? aiUrl!
                      : l10n.settingsAiUrlNotConfigured,
                  style: aiUrl?.isNotEmpty == true
                      ? null
                      : TextStyle(color: tokens.inkSoft),
                ),
                trailing: const Icon(Icons.edit, size: 18),
                onTap: () => _editAiUrl(context, ref, aiUrl),
              ),
              ListTile(
                leading: Icon(Icons.key_outlined, color: tokens.inkSoft),
                title: Text(l10n.settingsAiCredentials),
                subtitle: Text(
                  aiUsername?.isNotEmpty == true
                      ? l10n.settingsAiLoggedInAs(aiUsername!)
                      : l10n.settingsAiCredentialsNotConfigured,
                  style: aiUsername?.isNotEmpty == true
                      ? null
                      : TextStyle(color: tokens.inkSoft),
                ),
                trailing: const Icon(Icons.edit, size: 18),
                onTap: () => _editAiCredentials(context, ref),
              ),
              ListTile(
                leading: Icon(Icons.wifi_tethering, color: tokens.inkSoft),
                title: Text(l10n.settingsAiVerify),
                subtitle: Text(l10n.settingsAiVerifySubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _verifyAiConnection(context, ref),
              ),
            ],
          ),
          _SettingsSection(
            title: l10n.settingsSectionData,
            children: [
              ListTile(
                leading: Icon(Icons.label_outline, color: tokens.inkSoft),
                title: Text(l10n.settingsManageLabels),
                subtitle: Text(l10n.settingsManageLabelsSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/labels'),
              ),
              ListTile(
                leading: Icon(Icons.route_outlined, color: tokens.inkSoft),
                title: Text(l10n.settingsWorkflows),
                subtitle: Text(l10n.settingsWorkflowsSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/workflows'),
              ),
              ListTile(
                leading: Icon(Icons.extension_outlined, color: tokens.inkSoft),
                title: Text(l10n.settingsCustomFields),
                subtitle: Text(l10n.settingsCustomFieldsSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/custom-fields'),
              ),
              ListTile(
                leading: Icon(Icons.bookmark_outline, color: tokens.inkSoft),
                title: Text(l10n.settingsUploadTemplates),
                subtitle: Text(l10n.settingsUploadTemplatesSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/templates'),
              ),
              _UploadQueueTile(tokens: tokens),
              ListTile(
                leading: Icon(Icons.delete_outline, color: tokens.stamp),
                title: Text(l10n.settingsTrash,
                    style: TextStyle(color: tokens.stamp)),
                subtitle: Text(l10n.settingsTrashSubtitle),
                trailing: Icon(Icons.chevron_right, color: tokens.stamp),
                onTap: () => context.push('/trash'),
              ),
            ],
          ),
          _SettingsSection(
            title: l10n.settingsSectionAbout,
            children: [
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '...';
                  final build = snapshot.data?.buildNumber ?? '';
                  return ListTile(
                    leading: Icon(Icons.info_outline, color: tokens.inkSoft),
                    title: const Text('Paperless Go'),
                    subtitle:
                        Text('v$version${build.isNotEmpty ? '+$build' : ''}'),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.settingsSignOutConfirmTitle),
        content: Text(ctx.l10n.settingsSignOutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.settingsSignOut),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authStateProvider.notifier).logout();
    }
  }

  void _addProfile(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.settingsSaveProfileTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: ctx.l10n.settingsProfileNameLabel,
            hintText: ctx.l10n.settingsProfileNameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, controller.text.trim());
            },
            child: Text(ctx.l10n.commonSave),
          ),
        ],
      ),
    ).then((name) {
      if (name != null && name is String && name.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(serverProfilesNotifierProvider.notifier)
              .addCurrentAsProfile(name);
        });
      }
    });
  }

  Future<void> _toggleBiometric(
      BuildContext context, WidgetRef ref, bool enabled) async {
    if (enabled) {
      final biometricService = BiometricService();
      final isAvailable = await biometricService.isAvailable();
      if (!isAvailable) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(context.l10n.settingsBiometricUnavailable)),
          );
        }
        return;
      }
      // Verify biometric before enabling
      if (!context.mounted) return;
      final authenticated = await biometricService.authenticate(
        reason: context.l10n.settingsBiometricVerifyReason,
      );
      if (!authenticated || !context.mounted) return;
    }
    ref.read(biometricLockProvider.notifier).setEnabled(enabled);
  }

  Future<void> _setStartScreen(
      BuildContext context, WidgetRef ref, StartScreen screen) async {
    final saved = await ref.read(startScreenProvider.notifier).set(screen);
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.settingsStartScreenSaveFailed)),
      );
    }
  }

  Future<void> _chooseDownloadsFolder(
      BuildContext context, WidgetRef ref) async {
    final current = ref.read(downloadsDestinationProvider).valueOrNull;
    if (current != null && current.status != DestinationStatus.unset) {
      final action = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.folder_open_outlined),
                title: Text(ctx.l10n.settingsDownloadFolderChooseOther),
                onTap: () => Navigator.pop(ctx, 'choose'),
              ),
              ListTile(
                leading: const Icon(Icons.folder_off_outlined),
                title: Text(ctx.l10n.settingsDownloadFolderForget),
                subtitle: Text(ctx.l10n.settingsDownloadFolderForgetSubtitle),
                onTap: () => Navigator.pop(ctx, 'forget'),
              ),
            ],
          ),
        ),
      );
      if (action == null || !context.mounted) return;
      if (action == 'forget') {
        await ref.read(downloadsDestinationProvider.notifier).clear();
        return;
      }
    }

    try {
      await ref.read(downloadsDestinationProvider.notifier).choose();
    } on ExportSaveException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _verifyAiConnection(BuildContext context, WidgetRef ref) async {
    final service = ref.read(chatServiceProvider);
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.settingsAiUrlRequired)),
      );
      return;
    }
    final username = ref.read(aiChatUsernameProvider) ?? '';
    final password = ref.read(aiChatPasswordProvider) ?? '';
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.l10n.settingsAiCredentialsRequired)),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Text(ctx.l10n.settingsAiVerifying),
            ],
          ),
        ),
      ),
    );

    String? error;
    try {
      await service.login(username, password);
    } on Exception catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }

    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? context.l10n.settingsAiVerified),
        backgroundColor:
            error != null ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  void _editAiCredentials(BuildContext context, WidgetRef ref) {
    final usernameController = TextEditingController(
      text: ref.read(aiChatUsernameProvider) ?? '',
    );
    final passwordController = TextEditingController(
      text: ref.read(aiChatPasswordProvider) ?? '',
    );
    var verifying = false;
    String? verifyError;
    showDialog<(String, String)>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(ctx.l10n.settingsAiCredentials),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ctx.l10n.settingsAiCredentialsDescription,
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              AutofillGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameController,
                      autofocus: true,
                      autofillHints: const [AutofillHints.username],
                      decoration: InputDecoration(
                        labelText: ctx.l10n.commonUsername,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: ctx.l10n.commonPassword,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              if (verifyError != null) ...[
                const SizedBox(height: 12),
                Text(
                  verifyError!,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx).colorScheme.error,
                      ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: verifying ? null : () => Navigator.pop(ctx),
              child: Text(ctx.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: verifying
                  ? null
                  : () async {
                      final username = usernameController.text.trim();
                      final password = passwordController.text;
                      final service = ref.read(chatServiceProvider);
                      if (service == null) {
                        setState(() => verifyError =
                            ctx.l10n.settingsAiUrlRequired);
                        return;
                      }
                      setState(() {
                        verifying = true;
                        verifyError = null;
                      });
                      try {
                        await service.login(username, password);
                        if (!ctx.mounted) return;
                        // Verified — capture values before popping;
                        // controllers are disposed after the exit animation.
                        Navigator.pop(ctx, (username, password));
                      } on Exception catch (e) {
                        if (!ctx.mounted) return;
                        setState(() {
                          verifying = false;
                          verifyError = e
                              .toString()
                              .replaceFirst('Exception: ', '');
                        });
                      }
                    },
              child: verifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(ctx.l10n.settingsAiVerifyAndSave),
            ),
          ],
        ),
      ),
    ).then((result) {
      if (result != null) {
        // Defer provider updates until after the dialog exit animation
        // completes to avoid rebuilding the widget tree mid-animation.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(aiChatUsernameProvider.notifier).set(result.$1);
          ref.read(aiChatPasswordProvider.notifier).set(result.$2);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(context.l10n.settingsAiCredentialsVerified)),
            );
          }
        });
      }
      // Do NOT dispose controllers here — the dialog exit animation is
      // still using them. They will be garbage collected.
    });
  }

  void _editAiUrl(BuildContext context, WidgetRef ref, String? currentUrl) {
    final controller = TextEditingController(text: currentUrl ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.settingsAiUrl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ctx.l10n.settingsAiUrlDescription,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: ctx.l10n.settingsAiUrlFieldLabel,
                hintText: 'http://your-server:8083',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, controller.text.trim());
            },
            child: Text(ctx.l10n.commonSave),
          ),
        ],
      ),
    ).then((url) {
      if (url != null && url is String) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(aiChatUrlProvider.notifier).setUrl(url);
        });
      }
    });
  }
}

/// Translated name of a [StartScreen], for the Settings row. A switch rather
/// than a field on the enum so the label follows the app language.
String _startScreenLabel(AppLocalizations l10n, StartScreen screen) =>
    switch (screen) {
      StartScreen.library => l10n.settingsStartScreenLibrary,
      StartScreen.inbox => l10n.settingsStartScreenInbox,
    };

/// The truthful state of the downloads folder, including the case where a
/// folder was chosen but Android has since revoked access to it.
class _DownloadsLocationSubtitle extends StatelessWidget {
  const _DownloadsLocationSubtitle({
    required this.destination,
    required this.tokens,
  });

  final AsyncValue<ExportDestination> destination;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return switch (destination) {
      AsyncData(:final value) => switch (value.status) {
          DestinationStatus.ready => Text(value.displayName),
          DestinationStatus.unset => Text(
              context.l10n.settingsDownloadFolderAskEachTime,
              style: TextStyle(color: tokens.inkSoft),
            ),
          DestinationStatus.unavailable => Text(
              context.l10n.settingsDownloadFolderUnavailable(value.displayName),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        },
      AsyncError() => Text(
          context.l10n.settingsDownloadFolderCheckFailed,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      _ => Text(context.l10n.settingsDownloadFolderChecking,
          style: TextStyle(color: tokens.inkSoft)),
    };
  }
}

/// A titled group of settings rows: a small Space Grotesk heading above a
/// card that carries the 16dp radius and 1px line border from the design
/// system (elevation in dark mode comes from that border, never shadows).
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Spacing.lg, Spacing.lg, Spacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Spacing.xs, 0, Spacing.xs, Spacing.sm),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: tokens.inkSoft,
                    ),
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            color: tokens.card,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.lg),
              side: BorderSide(color: tokens.line),
            ),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: tokens.line),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Settings entry point for the upload queue, badged when something is stuck.
///
/// The badge is the point: uploads that have stopped retrying hold onto their
/// files, and before this there was nothing anywhere in the app that said so.
class _UploadQueueTile extends ConsumerWidget {
  const _UploadQueueTile({required this.tokens});

  final AppTokens tokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stuck = ref.watch(uploadsNeedingAttentionProvider);
    final waiting =
        (ref.watch(pendingUploadsProvider).valueOrNull ?? const []).length;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return ListTile(
      leading: Icon(Icons.upload_file_outlined, color: tokens.inkSoft),
      title: Text(l10n.settingsUploadQueue),
      subtitle: Text(
        switch ((waiting, stuck)) {
          (0, _) => l10n.settingsUploadQueueEmpty,
          (_, 0) => l10n.settingsUploadQueueWaiting(waiting),
          (_, final s) => l10n.settingsUploadQueueNeedsAttention(waiting, s),
        },
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (stuck > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.error,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Text(
                '$stuck',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: colorScheme.onError),
              ),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => context.push('/upload-queue'),
    );
  }
}
