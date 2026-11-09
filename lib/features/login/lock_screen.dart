import 'package:flutter/material.dart';

import '../../core/services/biometric_service.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  /// Clears the session and returns to login. Offered only when this device
  /// cannot authenticate, so the user is never stranded; it is not a bypass.
  final VoidCallback? onSignOut;

  final BiometricService? biometrics;

  const LockScreen({
    super.key,
    required this.onUnlocked,
    this.onSignOut,
    this.biometrics,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  late final BiometricService _biometricService =
      widget.biometrics ?? BiometricService();
  bool _isAuthenticating = false;
  bool _cannotAuthenticate = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    final available = await _biometricService.isAvailable();
    final result = available
        ? await _biometricService.authenticateResult()
        : BiometricResult.unavailable;
    if (!mounted) return;
    if (result == BiometricResult.success) {
      widget.onUnlocked();
    } else {
      setState(() {
        _isAuthenticating = false;
        _cannotAuthenticate = result == BiometricResult.unavailable;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Paperless Go',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Authenticate to continue',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isAuthenticating ? null : _authenticate,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Unlock'),
            ),
            if (_cannotAuthenticate && widget.onSignOut != null) ...[
              const SizedBox(height: 16),
              Text(
                'This device cannot verify you. Signing out clears the '
                'saved session so you can log in again.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              TextButton(
                onPressed: widget.onSignOut,
                child: const Text('Sign out'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
