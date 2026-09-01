package com.ventoux.paperlessgo

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    private lateinit var sharePlugin: SharePlugin

    /**
     * Whether a share was already handed to Dart before this Activity was
     * rebuilt.
     *
     * A restored task still carries the intent that started it, so without a
     * guard the share is resolved and delivered a second time: the file is
     * re-copied to cache and the user is dropped back into an upload flow they
     * already finished. Verified on a Pixel 9 Pro Fold — neither an extra
     * written onto the intent nor FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY survives
     * process death.
     *
     * This is persisted in the saved-state bundle, which does survive, and is
     * set only once a delivery actually happened. Using "savedInstanceState is
     * non-null" instead would suppress a share whose Activity was recreated
     * BEFORE Dart ever asked for it, dropping the file permanently.
     */
    private var shareDelivered = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PdfRendererPlugin.register(flutterEngine)
        sharePlugin = SharePlugin(
            this,
            deliveredBeforeRestore = { shareDelivered },
            onDelivered = { shareDelivered = true },
        )
        sharePlugin.register(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        shareDelivered = savedInstanceState?.getBoolean(STATE_SHARE_DELIVERED, false) ?: false
        stripDataFromShareIntent(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        // A genuinely new intent carries a share that has not been delivered
        // yet, whatever happened to the previous one.
        shareDelivered = false
        stripDataFromShareIntent(intent)
        super.onNewIntent(intent)
        // Activity.intent otherwise still points at whatever launched the process,
        // so a later getInitialShare() (SharePlugin reads activity.intent) resolves
        // the *stale* intent and returns zero files for a share that just arrived.
        setIntent(intent)
        sharePlugin.onNewIntent(intent)
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putBoolean(STATE_SHARE_DELIVERED, shareDelivered)
    }

    companion object {
        private const val STATE_SHARE_DELIVERED = "com.ventoux.paperlessgo.SHARE_DELIVERED"
    }

    /**
     * Some sharing apps (e.g. GrapheneOS PDF Viewer) set Intent.data on a
     * SEND/SEND_MULTIPLE intent in addition to the standard EXTRA_STREAM.
     * Flutter's embedding treats any non-null Intent.data as a deep-link
     * route to push automatically, racing SharePlugin's own handling and
     * surfacing the raw content:// URI as an unmatched route ("Page not
     * found"). SharePlugin reads files from EXTRA_STREAM/ClipData, never
     * from Intent.data, so clearing it here is safe and only affects
     * share intents — the paperlessgo:// widget deep links (ACTION_VIEW)
     * are untouched.
     */
    private fun stripDataFromShareIntent(intent: Intent) {
        if (intent.action == Intent.ACTION_SEND || intent.action == Intent.ACTION_SEND_MULTIPLE) {
            intent.data = null
        }
    }

    /**
     * Suppresses Flutter's default "Intent.data becomes the initial route"
     * behavior for content/file share URIs — see [shouldSuppressInitialRoute]
     * in SharePlugin.kt. Deliberately does NOT touch Intent.data itself
     * (unlike stripDataFromShareIntent for SEND/SEND_MULTIPLE): SharePlugin
     * still reads Intent.data directly off activity.intent for the
     * ACTION_VIEW case, so nulling it here would silently drop the share.
     */
    override fun getInitialRoute(): String? {
        if (shouldSuppressInitialRoute(intent?.data?.scheme)) return null
        return super.getInitialRoute()
    }
}
