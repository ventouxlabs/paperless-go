package com.ventoux.paperlessgo

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import java.security.cert.X509Certificate

/**
 * Exposes Android's user-installed CA certificates to Dart.
 *
 * Dart's `HttpClient` builds its trust store from the Android *system* CA
 * store only — it never reads a CA the user installs under Settings →
 * Security → Install a certificate (dart-lang/sdk#50435). A Paperless server
 * behind a private CA therefore fails the TLS handshake even after the CA is
 * installed on the device. This plugin reads the "user:" aliases out of
 * "AndroidCAStore" so the Dart side can add them to its own trust store.
 */
class UserCertificatesPlugin {
    companion object {
        private const val CHANNEL = "com.ventoux.paperlessgo/user_certificates"

        fun register(flutterEngine: FlutterEngine) {
            val mainHandler = Handler(Looper.getMainLooper())
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "getUserCaCertificates" -> {
                            // AndroidCAStore reads hit disk. Run off the platform
                            // thread so a wedged keystore can't ANR the app, and
                            // post the outcome back to the main thread, which
                            // MethodChannel.Result requires.
                            Thread {
                                try {
                                    val certs = getUserCaCertificates()
                                    mainHandler.post { result.success(certs) }
                                } catch (e: Exception) {
                                    mainHandler.post {
                                        result.error("KEYSTORE_ERROR", e.message, null)
                                    }
                                }
                            }.start()
                        }
                        else -> result.notImplemented()
                    }
                }
        }

        private fun getUserCaCertificates(): List<ByteArray> {
            val store = KeyStore.getInstance("AndroidCAStore")
            store.load(null, null)
            return store.aliases().toList()
                .filter { it.startsWith("user:") }
                .mapNotNull { store.getCertificate(it) as? X509Certificate }
                .map { it.encoded }
        }
    }
}
