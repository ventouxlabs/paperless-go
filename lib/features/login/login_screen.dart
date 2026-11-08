import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_service.dart';
import '../../core/design_tokens.dart';
import '../../core/api/api_error_mapper.dart';
import '../../core/services/user_trust_store.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController(text: 'https://');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _tokenController = TextEditingController();
  final _appClientIdController = TextEditingController();

  List<SsoProvider> _ssoProviders = const [];
  bool _useTokenLogin = false;
  bool _obscurePassword = true;
  bool _testing = false;
  bool? _connectionOk;
  String? _connectionReason;
  Timer? _autoTest;

  @override
  void dispose() {
    _autoTest?.cancel();
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _tokenController.dispose();
    _appClientIdController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    _autoTest?.cancel();
    final url = _normalizeUrl(_serverUrlController.text.trim());
    if (url.isEmpty || url.startsWith('http://')) {
      setState(() {
        _connectionOk = false;
        _connectionReason = null;
        _ssoProviders = const [];
      });
      return;
    }

    setState(() {
      _testing = true;
      _connectionOk = null;
      _connectionReason = null;
      _ssoProviders = const [];
    });
    try {
      await UserTrustStore.refresh();
      final authService = ref.read(authServiceProvider);
      final probe = await authService.testConnection(url);
      if (!mounted || !_isCurrentUrl(url)) return;
      setState(() {
        _connectionOk = probe.ok;
        _connectionReason = probe.reason;
        _testing = false;
      });
      if (!probe.ok) return;
      final providers = await authService.fetchSsoProviders(url);
      if (mounted && _isCurrentUrl(url)) {
        setState(() => _ssoProviders = providers);
      }
    } finally {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }

  /// Checks the server once typing pauses, so the SSO button can appear
  /// without the user finding the test icon.
  void _scheduleAutoTest() {
    _autoTest?.cancel();
    final host = Uri.tryParse(
      _normalizeUrl(_serverUrlController.text.trim()),
    )?.host;
    if (host == null || host.isEmpty) return;
    _autoTest = Timer(const Duration(milliseconds: 800), _testConnection);
  }

  bool _isCurrentUrl(String url) =>
      _normalizeUrl(_serverUrlController.text.trim()) == url;

  String _normalizeUrl(String url) {
    if (url.isEmpty) return '';
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url.replaceAll(RegExp(r'/+$'), '');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final serverUrl = _normalizeUrl(_serverUrlController.text.trim());
    final authNotifier = ref.read(authStateProvider.notifier);

    try {
      await UserTrustStore.refresh();
      if (_useTokenLogin) {
        await authNotifier.loginWithToken(
          serverUrl,
          _tokenController.text.trim(),
        );
      } else {
        await authNotifier.loginWithCredentials(
          serverUrl,
          _usernameController.text.trim(),
          _passwordController.text,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: ${friendlyApiMessage(e)}')),
        );
      }
    }
  }

  Future<void> _ssoLogin(SsoProvider provider) async {
    final serverUrl = _normalizeUrl(_serverUrlController.text.trim());
    try {
      await UserTrustStore.refresh();
      await ref
          .read(authStateProvider.notifier)
          .loginWithSso(
            serverUrl,
            provider,
            appClientId: _appClientIdController.text.trim(),
          );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: ${friendlyApiMessage(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;
    final tokens = AppTokens.of(context);
    final connectionReason = _connectionReason;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: tokens.accentEmphasis,
                      ),
                      const SizedBox(height: Spacing.lg),
                      Text(
                        'Paperless Go',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        'Connect to your Paperless-ngx server',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: tokens.inkSoft),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Spacing.xxl),

                      // Server URL
                      TextFormField(
                        controller: _serverUrlController,
                        decoration: InputDecoration(
                          labelText: 'Server URL',
                          hintText: 'https://paperless.example.com',
                          prefixIcon: const Icon(Icons.dns_outlined),
                          suffixIcon: _testing
                              ? const Padding(
                                  padding: EdgeInsets.all(Spacing.md),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(
                                    _connectionOk == null
                                        ? Icons.wifi_find
                                        : _connectionOk!
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color: _connectionOk == null
                                        ? null
                                        : _connectionOk!
                                        ? tokens.accentEmphasis
                                        : tokens.stamp,
                                  ),
                                  onPressed: _testConnection,
                                  tooltip: 'Test connection',
                                ),
                        ),
                        autofillHints: const [AutofillHints.url],
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        validator: (v) {
                          if (v == null ||
                              v.trim().isEmpty ||
                              v.trim() == 'https://') {
                            return 'Enter your server URL';
                          }
                          final url = v.trim().toLowerCase();
                          if (!url.startsWith('http://') &&
                              !url.startsWith('https://')) {
                            return 'URL must start with https:// or http://';
                          }
                          if (url.startsWith('http://')) {
                            return 'This app requires https:// — plain http:// connections '
                                'are blocked. Put your server behind a reverse proxy or '
                                'Tailscale Serve for a valid HTTPS address.';
                          }
                          final parsed = Uri.tryParse(v.trim());
                          if (parsed == null || parsed.host.isEmpty) {
                            return 'Enter a valid URL';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _testConnection(),
                        onChanged: (_) {
                          _scheduleAutoTest();
                          setState(() {
                            // Refresh for HTTP warning, and drop any stale
                            // reason from testing a previously-typed URL.
                            _connectionOk = null;
                            _connectionReason = null;
                            _ssoProviders = const [];
                          });
                        },
                      ),

                      // HTTP warning
                      if (_serverUrlController.text
                          .trim()
                          .toLowerCase()
                          .startsWith('http://'))
                        Padding(
                          padding: const EdgeInsets.only(top: Spacing.sm),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 16,
                                color: tokens.stamp,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'http:// is blocked by this app — use https:// instead',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: tokens.stamp),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Connection test failure reason
                      if (_connectionOk == false && connectionReason != null)
                        Padding(
                          padding: const EdgeInsets.only(top: Spacing.sm),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 16,
                                color: tokens.stamp,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  connectionReason,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: tokens.stamp),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: Spacing.lg),

                      // Token/credentials toggle
                      SwitchListTile(
                        title: const Text('Login with API token'),
                        value: _useTokenLogin,
                        onChanged: (v) => setState(() => _useTokenLogin = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: Spacing.sm),

                      if (_useTokenLogin) ...[
                        TextFormField(
                          controller: _tokenController,
                          decoration: const InputDecoration(
                            labelText: 'API Token',
                            prefixIcon: Icon(Icons.key_outlined),
                          ),
                          autocorrect: false,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter your API token';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outlined),
                          ),
                          autofillHints: const [AutofillHints.username],
                          autocorrect: false,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter your username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Spacing.lg),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          autofillHints: const [AutofillHints.password],
                          obscureText: _obscurePassword,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter your password';
                            }
                            return null;
                          },
                        ),
                      ],

                      const SizedBox(height: Spacing.xl),
                      FilledButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                TextInput.finishAutofillContext();
                                _submit();
                              },
                        child: isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: tokens.onAccent,
                                ),
                              )
                            : const Text('Login'),
                      ),
                      if (_ssoProviders.isNotEmpty) ...[
                        const SizedBox(height: Spacing.lg),
                        for (final provider in _ssoProviders)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Spacing.sm),
                            child: OutlinedButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () => _ssoLogin(provider),
                              icon: const Icon(Icons.open_in_browser),
                              label: Text('Sign in with ${provider.name}'),
                            ),
                          ),
                        ExpansionTile(
                          title: const Text('Advanced'),
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(
                            bottom: Spacing.sm,
                          ),
                          children: [
                            TextFormField(
                              controller: _appClientIdController,
                              decoration: const InputDecoration(
                                labelText: 'App client ID',
                                helperText:
                                    'Only for Dex cross-client setups. '
                                    'Leave empty otherwise.',
                              ),
                              autocorrect: false,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
