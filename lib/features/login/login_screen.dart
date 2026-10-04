import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/auth_service.dart';
import '../../core/design_tokens.dart';
import '../../core/api/api_error_mapper.dart';
import '../../core/services/user_trust_store.dart';
import '../../l10n/l10n.dart';

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

  bool _useTokenLogin = false;
  bool _obscurePassword = true;
  bool _testing = false;
  bool? _connectionOk;
  String? _connectionReason;

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final url = _normalizeUrl(_serverUrlController.text.trim());
    if (url.isEmpty || url.startsWith('http://')) {
      setState(() {
        _connectionOk = false;
        _connectionReason = null;
      });
      return;
    }

    setState(() {
      _testing = true;
      _connectionOk = null;
      _connectionReason = null;
    });
    try {
      await UserTrustStore.refresh();
      final authService = ref.read(authServiceProvider);
      final probe = await authService.testConnection(url);
      if (mounted) {
        setState(() {
          _connectionOk = probe.ok;
          _connectionReason = probe.reason;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }

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
          SnackBar(
            content: Text(
              context.l10n.loginConnectionError(friendlyApiMessage(e)),
            ),
          ),
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
    final l10n = context.l10n;

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
                        l10n.loginSubtitle,
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
                          labelText: l10n.loginServerUrlLabel,
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
                                  tooltip: l10n.loginTestConnectionTooltip,
                                ),
                        ),
                        autofillHints: const [AutofillHints.url],
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        validator: (v) {
                          if (v == null ||
                              v.trim().isEmpty ||
                              v.trim() == 'https://') {
                            return l10n.loginServerUrlRequired;
                          }
                          final url = v.trim().toLowerCase();
                          if (!url.startsWith('http://') &&
                              !url.startsWith('https://')) {
                            return l10n.loginServerUrlSchemeRequired;
                          }
                          if (url.startsWith('http://')) {
                            return l10n.loginServerUrlHttpBlocked;
                          }
                          final parsed = Uri.tryParse(v.trim());
                          if (parsed == null || parsed.host.isEmpty) {
                            return l10n.loginServerUrlInvalid;
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {
                          // Refresh for HTTP warning, and drop any stale
                          // reason from testing a previously-typed URL.
                          _connectionOk = null;
                          _connectionReason = null;
                        }),
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
                                  l10n.loginHttpWarning,
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
                        title: Text(l10n.loginUseApiToken),
                        value: _useTokenLogin,
                        onChanged: (v) => setState(() => _useTokenLogin = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: Spacing.sm),

                      if (_useTokenLogin) ...[
                        TextFormField(
                          controller: _tokenController,
                          decoration: InputDecoration(
                            labelText: l10n.loginApiTokenLabel,
                            prefixIcon: const Icon(Icons.key_outlined),
                          ),
                          autocorrect: false,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return l10n.loginApiTokenRequired;
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: l10n.commonUsername,
                            prefixIcon: const Icon(Icons.person_outlined),
                          ),
                          autofillHints: const [AutofillHints.username],
                          autocorrect: false,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return l10n.loginUsernameRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Spacing.lg),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: l10n.commonPassword,
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
                              return l10n.loginPasswordRequired;
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
                            : Text(l10n.loginSubmit),
                      ),
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
