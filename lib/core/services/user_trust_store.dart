import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds Android user-installed CA certificates to Dart's TLS trust store.
///
/// Dart's `HttpClient` builds its trust store from the Android *system* CA
/// store only — it never reads a CA the user installs under Settings →
/// Security → Install a certificate (dart-lang/sdk#50435). Without this, a
/// Paperless server behind a private CA fails the TLS handshake even after
/// the user installs its root on the device — for dio AND for
/// cached_network_image/flutter_cache_manager (thumbnails), which construct
/// their own `HttpClient` and bypass dio entirely.
class UserTrustStore {
  UserTrustStore._();

  static const _channel = MethodChannel(
    'com.ventoux.paperlessgo/user_certificates',
  );

  /// Bounds how long a wedged native keystore read can hold up startup (or a
  /// [refresh] call). Applied inside [install] itself so every caller is
  /// covered, not just the ones that remember to wrap it.
  static const Duration installTimeout = Duration(seconds: 2);

  /// Reads the user-installed CAs and installs an [HttpOverrides] whose
  /// clients trust them in addition to the system roots. Never throws.
  ///
  /// The read can come back three ways, each handled differently:
  ///  - it fails (error, missing plugin, or [installTimeout] expires): leave
  ///    [HttpOverrides.global] exactly as it is — fail closed to whatever
  ///    trust state is already in effect rather than guessing;
  ///  - it succeeds with zero CAs: clear [HttpOverrides.global] IF AND ONLY
  ///    IF this class is the one that installed it (see [isInstalled]).
  ///    A user can remove a CA they installed earlier, and a stale override
  ///    trusting a certificate that's no longer in the store must not
  ///    outlive that removal. Never clobber a foreign [HttpOverrides] some
  ///    other code installed;
  ///  - it succeeds with at least one CA: install an override for them.
  static Future<void> install() async {
    final ders = await _readUserCertificates().timeout(
      installTimeout,
      onTimeout: () => null,
    );
    if (ders == null) return;
    if (ders.isEmpty) {
      if (isInstalled) HttpOverrides.global = null;
      return;
    }
    final context = buildSecurityContext(ders);
    HttpOverrides.global = _UserTrustOverrides(context);
  }

  /// Re-reads the store, e.g. right before a connection probe, so a CA the
  /// user installed or removed while the app was open is picked up without a
  /// restart — for any `HttpClient` created AFTER this call returns. It
  /// cannot reach a client that already exists: dio's `IOHttpClientAdapter`
  /// caches its `HttpClient` on first use, and the thumbnail cache manager
  /// holds one for the process's lifetime, so both still need an app
  /// restart, not just a refresh.
  static Future<void> refresh() => install();

  /// Whether [HttpOverrides.current] is an override this class installed,
  /// as opposed to none, or one some other code installed. Used by [install]
  /// so an empty read only ever clears trust state this class is
  /// responsible for.
  @visibleForTesting
  static bool get isInstalled => HttpOverrides.current is _UserTrustOverrides;

  /// Returns the user-installed CAs, `[]` if there are none, or `null` if
  /// the store couldn't be read at all (error, missing plugin, or timeout).
  /// The `null` case is distinct from `[]` — see [install].
  static Future<List<Uint8List>?> _readUserCertificates() async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>(
        'getUserCaCertificates',
      );
      return result
              ?.map((e) => Uint8List.fromList((e as List).cast<int>()))
              .toList() ??
          const [];
    } on MissingPluginException {
      // Non-Android host (or a test) — no plugin registered.
      return null;
    } on PlatformException catch (e) {
      debugPrint('User CA store unavailable: ${e.code}');
      return null;
    }
  }

  /// Builds a [SecurityContext] that trusts the system roots plus every
  /// certificate in [ders] that parses. Each certificate is added on its own
  /// so one duplicate or malformed entry can't discard the rest. (An expired
  /// certificate is NOT skipped here — `setTrustedCertificatesBytes` accepts
  /// it; expiry is checked later, by the TLS verifier at handshake time.)
  @visibleForTesting
  static SecurityContext buildSecurityContext(Iterable<Uint8List> ders) {
    final context = SecurityContext(withTrustedRoots: true);
    for (final der in ders) {
      try {
        context.setTrustedCertificatesBytes(utf8.encode(derToPem(der)));
      } on TlsException catch (e) {
        debugPrint('Skipping unusable user CA certificate: ${e.message}');
      }
    }
    return context;
  }

  /// Converts a DER-encoded certificate to PEM: base64, wrapped at 64
  /// characters, with BEGIN/END CERTIFICATE markers and a trailing newline.
  @visibleForTesting
  static String derToPem(Uint8List der) {
    final body = base64.encode(der);
    final buffer = StringBuffer('-----BEGIN CERTIFICATE-----\n');
    for (var i = 0; i < body.length; i += 64) {
      final end = i + 64 < body.length ? i + 64 : body.length;
      buffer.writeln(body.substring(i, end));
    }
    buffer.writeln('-----END CERTIFICATE-----');
    return buffer.toString();
  }
}

/// Falls back to a [SecurityContext] that trusts the user-installed CAs for
/// any [HttpClient] created without one of its own — which covers dio's
/// default adapter as well as cached_network_image/flutter_cache_manager.
class _UserTrustOverrides extends HttpOverrides {
  _UserTrustOverrides(this._context);

  final SecurityContext _context;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context ?? _context);
  }
}
