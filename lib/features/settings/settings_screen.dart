import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/server_profiles.dart';
import '../../core/design_tokens.dart';
import '../upload_queue/upload_queue_notifier.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/export_destination_service.dart';
import '../ai_chat/chat_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppTokens.of(context);
    final aiUrl = ref.watch(aiChatUrlProvider);
    final authState = ref.watch(authStateProvider).valueOrNull;
    final themeMode = ref.watch(themeModeNotifierProvider);
    final biometricEnabled = ref.watch(biometricLockProvider);
    final profilesState = ref.watch(serverProfilesNotifierProvider);
    final aiUsername = ref.watch(aiChatUsernameProvider);
    final downloadsDestination = ref.watch(downloadsDestinationProvider);

    return Scaffold(
      backgroundColor: tokens.paper,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Spacing.xxl),
        children: [
          _SettingsSection(
            title: 'Account',
            children: [
              ListTile(
                leading: Icon(Icons.dns_outlined, color: tokens.inkSoft),
                title: const Text('Server'),
                subtitle: Text(authState?.serverUrl ?? 'Not connected'),
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
                      tooltip: 'Remove profile',
                      onPressed: () => ref
                          .read(serverProfilesNotifierProvider.notifier)
                          .removeProfile(idx),
                    ),
                  );
                }),
              ListTile(
                leading: Icon(Icons.add, color: tokens.inkSoft),
                title: const Text('Save current server as profile'),
                onTap: () => _addProfile(context, ref),
              ),
              ListTile(
                leading: Icon(Icons.logout, color: tokens.stamp),
                title: Text('Sign out', style: TextStyle(color: tokens.stamp)),
                onTap: () => _signOut(context, ref),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Appearance',
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
                        Text('Theme',
                            style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                    const SizedBox(height: Spacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
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
            ],
          ),
          _SettingsSection(
            title: 'Security',
            children: [
              SwitchListTile(
                secondary: Icon(Icons.fingerprint, color: tokens.inkSoft),
                title: const Text('Biometric Lock'),
                subtitle: const Text('Require authentication on app launch'),
                value: biometricEnabled,
                onChanged: (enabled) => _toggleBiometric(context, ref, enabled),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Storage',
            children: [
              ListTile(
                leading: Icon(Icons.folder_outlined, color: tokens.inkSoft),
                title: const Text('Downloads location'),
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
            title: 'AI Chat',
            children: [
              ListTile(
                leading: Icon(Icons.smart_toy_outlined, color: tokens.inkSoft),
                title: const Text('Paperless-AI URL'),
                subtitle: Text(
                  aiUrl?.isNotEmpty == true ? aiUrl! : 'Not configured',
                  style: aiUrl?.isNotEmpty == true
                      ? null
                      : TextStyle(color: tokens.inkSoft),
                ),
                trailing: const Icon(Icons.edit, size: 18),
                onTap: () => _editAiUrl(context, ref, aiUrl),
              ),
              ListTile(
                leading: Icon(Icons.key_outlined, color: tokens.inkSoft),
                title: const Text('Paperless-AI Credentials'),
                subtitle: Text(
                  aiUsername?.isNotEmpty == true
                      ? 'Logged in as $aiUsername'
                      : 'Not configured (required for chat)',
                  style: aiUsername?.isNotEmpty == true
                      ? null
                      : TextStyle(color: tokens.inkSoft),
                ),
                trailing: const Icon(Icons.edit, size: 18),
                onTap: () => _editAiCredentials(context, ref),
              ),
              ListTile(
                leading: Icon(Icons.wifi_tethering, color: tokens.inkSoft),
                title: const Text('Verify Connection'),
                subtitle: const Text('Check server reachability and credentials'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _verifyAiConnection(context, ref),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Data',
            children: [
              ListTile(
                leading: Icon(Icons.label_outline, color: tokens.inkSoft),
                title: const Text('Manage Labels'),
                subtitle: const Text('Tags, correspondents, document types'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/labels'),
              ),
              ListTile(
                leading: Icon(Icons.route_outlined, color: tokens.inkSoft),
                title: const Text('Workflows'),
                subtitle: const Text('View and manage automation rules'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/workflows'),
              ),
              ListTile(
                leading: Icon(Icons.extension_outlined, color: tokens.inkSoft),
                title: const Text('Custom Fields'),
                subtitle: const Text('Create and manage field definitions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/custom-fields'),
              ),
              ListTile(
                leading: Icon(Icons.bookmark_outline, color: tokens.inkSoft),
                title: const Text('Upload Templates'),
                subtitle: const Text('Save metadata presets for quick upload'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/templates'),
              ),
              _UploadQueueTile(tokens: tokens),
              ListTile(
                leading: Icon(Icons.delete_outline, color: tokens.stamp),
                title: Text('Trash', style: TextStyle(color: tokens.stamp)),
                subtitle: const Text('View and restore deleted documents'),
                trailing: Icon(Icons.chevron_right, color: tokens.stamp),
                onTap: () => context.push('/trash'),
              ),
            ],
          ),
          _SettingsSection(
            title: 'About',
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
        title: const Text('Sign out?'),
        content: const Text('You will need to log in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
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
        title: const Text('Save Server Profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Profile name',
            hintText: 'e.g., Home Server',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, controller.text.trim());
            },
            child: const Text('Save'),
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
            const SnackBar(
                content: Text('Biometric authentication is not available on this device')),
          );
        }
        return;
      }
      // Verify biometric before enabling
      final authenticated = await biometricService.authenticate(
        reason: 'Verify to enable biometric lock',
      );
      if (!authenticated || !context.mounted) return;
    }
    ref.read(biometricLockProvider.notifier).setEnabled(enabled);
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
                title: const Text('Choose a different folder'),
                onTap: () => Navigator.pop(ctx, 'choose'),
              ),
              ListTile(
                leading: const Icon(Icons.folder_off_outlined),
                title: const Text('Forget this folder'),
                subtitle: const Text('Downloads will ask each time'),
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
        const SnackBar(content: Text('Set the Paperless-AI URL first.')),
      );
      return;
    }
    final username = ref.read(aiChatUsernameProvider) ?? '';
    final password = ref.read(aiChatPasswordProvider) ?? '';
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Set your Paperless-AI credentials first.')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Verifying...'),
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
        content: Text(error ?? 'Paperless-AI connection verified'),
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
          title: const Text('Paperless-AI Credentials'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your Paperless-AI login credentials. Required for chat.',
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
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
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
              child: const Text('Cancel'),
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
                            'Set the Paperless-AI URL first.');
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
                  : const Text('Verify & save'),
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
              const SnackBar(content: Text('Credentials verified')),
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
        title: const Text('Paperless-AI URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the URL of your Paperless-AI instance (e.g., http://your-server:8083)',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'http://your-server:8083',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, controller.text.trim());
            },
            child: const Text('Save'),
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
              'Ask each time',
              style: TextStyle(color: tokens.inkSoft),
            ),
          DestinationStatus.unavailable => Text(
              '${value.displayName} — no longer available, tap to choose again',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        },
      AsyncError() => Text(
          'Could not check folder access',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      _ => Text('Checking…', style: TextStyle(color: tokens.inkSoft)),
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

    return ListTile(
      leading: Icon(Icons.upload_file_outlined, color: tokens.inkSoft),
      title: const Text('Upload queue'),
      subtitle: Text(
        switch ((waiting, stuck)) {
          (0, _) => 'Nothing waiting to upload',
          (_, 0) => '$waiting waiting to upload',
          (_, final s) => '$waiting waiting · $s need attention',
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
