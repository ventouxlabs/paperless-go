package com.ventoux.paperlessgo

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Parcelable
import android.provider.OpenableColumns
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.io.OutputStream
import java.util.concurrent.Executors

/**
 * Which part of an Intent carries the shared file, decided by [selectSource] from
 * the intent's action and Intent.data scheme alone. Kept as a pure decision separate
 * from the actual (Android-only) extraction so the action→source mapping — the exact
 * class of bug this file has shipped three times (share-intent fixes in 10411c1,
 * 810f061, cade169, each missing a different action type) — has a plain JUnit
 * regression test with no Android runtime required.
 */
internal enum class ShareSource { EXTRA_STREAM, INTENT_DATA, NONE }

/**
 * URI schemes that carry an actual shared file, as opposed to a non-file
 * ACTION_VIEW (e.g. the paperlessgo:// widget deep link). Shared between
 * [selectSource] and [shouldSuppressInitialRoute] so the two questions —
 * "is this a file?" and "should Flutter's embedding leave this alone?" —
 * can never drift apart the way this file's action→source mapping has
 * three times before (10411c1, 810f061, cade169): a new scheme added to
 * one and not the other silently reintroduces that class of bug.
 */
internal val SHARE_URI_SCHEMES = setOf("content", "file")

/**
 * The subset of [SHARE_URI_SCHEMES] this plugin will actually read. file:// is
 * excluded: this activity is exported, so any app can hand it a file:// URI naming
 * a path only this app can read (its own private data), and ContentResolver
 * opens file:// URIs with no grant check. content:// is safe because the
 * provider enforces the sender's URI grant. (file:// stays in
 * [SHARE_URI_SCHEMES] so Flutter's embedding still ignores it as a route.)
 */
private val COPYABLE_URI_SCHEMES = setOf("content")

internal fun isCopyableUri(scheme: String?): Boolean = scheme in COPYABLE_URI_SCHEMES

/**
 * Decides where to read a shared file's URI(s) from for a given intent action.
 *
 * - SEND / SEND_MULTIPLE: EXTRA_STREAM (share-sheet flow).
 * - VIEW: Intent.data, but ONLY for the content scheme — "Open with" from a file
 *   manager (see the ACTION_VIEW intent-filter in AndroidManifest.xml) uses this
 *   action, but so does the paperlessgo:// home-screen-widget deep link, which is
 *   NOT a file and must not be misread as one.
 * - anything else: no file.
 */
internal fun selectSource(action: String?, dataScheme: String?): ShareSource = when (action) {
    Intent.ACTION_SEND, Intent.ACTION_SEND_MULTIPLE -> ShareSource.EXTRA_STREAM
    Intent.ACTION_VIEW -> if (isCopyableUri(dataScheme)) {
        ShareSource.INTENT_DATA
    } else {
        ShareSource.NONE
    }
    else -> ShareSource.NONE
}

/**
 * Whether Flutter's default Android embedding should be stopped from
 * treating the launching Intent's data as an initial deep-link route.
 *
 * content/file schemes are real share URIs — SharePlugin (this file) is
 * the single source of truth for them, delivered over its own
 * method/event channel. Left alone, Flutter's embedding also reads
 * Intent.data at startup and pushes it as a route, racing SharePlugin's
 * own handling and forcing GoRouter through a forced /inbox redirect
 * before the actual share lands (see MainActivity.getInitialRoute()).
 * The paperlessgo:// widget deep link is also delivered via Intent.data
 * on an ACTION_VIEW intent, and legitimately needs Flutter's normal
 * routing — so only content/file are suppressed here. Deliberately
 * action-agnostic (unlike selectSource): MainActivity.stripDataFromShareIntent
 * already nulls Intent.data for SEND/SEND_MULTIPLE earlier in the same
 * lifecycle method, before this ever runs, so no other action can carry a
 * live content/file Intent.data by the time this is checked.
 */
internal fun shouldSuppressInitialRoute(scheme: String?): Boolean = scheme in SHARE_URI_SCHEMES

/**
 * Whether a share intent has already produced a delivery, from the two signals
 * that survive Activity/engine recreation.
 *
 * MainActivity calls setIntent() so activity.intent stays current for
 * getInitialShare — which also means the share intent lives on in the task
 * record. Without a guard it gets resolved again (copying a second file into
 * cache and re-pushing the user into the upload screen) by any later
 * getInitialShare.
 *
 * Three signals, because no single one covers every path:
 *  - [marked], an extra written onto the intent, covers a second query within
 *    one process;
 *  - [deliveredBeforeRestore] — a flag written into the Activity's saved state
 *    once a share has actually been handed to Dart. Survives process death,
 *    which the other two do not (measured on device). It is deliberately NOT
 *    "savedInstanceState != null": an Activity can be recreated with saved
 *    state BEFORE Dart ever called getInitialShare, and treating that as proof
 *    of delivery drops the file permanently;
 *  - LAUNCHED_FROM_HISTORY catches a Recents relaunch of an intent that was
 *    consumed before the mark existed.
 */
internal fun isAlreadyDelivered(
    marked: Boolean,
    flags: Int,
    deliveredBeforeRestore: Boolean = false,
): Boolean =
    marked ||
        deliveredBeforeRestore ||
        (flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0

/**
 * Whether resolving an intent should burn it.
 *
 * Marks whenever the intent carried at least one URI, because the payload
 * ([sharePayload]) now goes to Dart in every case — readable files are
 * routed and the shortfall is reported to the user. This used to mark only
 * on a complete result so a failed copy stayed retryable, but "retryable"
 * meant a later getInitialShare (Activity recreated with the same intent)
 * silently re-copied the readable files and pushed the upload screen a
 * second time, while the failure itself was never shown. An intent that
 * carried nothing is never marked: it was not a share.
 */
internal fun shouldMarkDelivered(resolvedCount: Int, requestedCount: Int): Boolean =
    requestedCount > 0

/**
 * The payload handed to Dart: the files that could be read plus how many the
 * intent asked for. A share whose every copy failed used to arrive as `[]`,
 * indistinguishable from "no share at all", so the user saw the start screen
 * and nothing else. Dart shows a notice when `requested` exceeds `files`.
 */
internal fun sharePayload(files: JSONArray, requested: Int): String =
    JSONObject().put("files", files).put("requested", requested).toString()

/**
 * Holds resolved shares until Dart's EventChannel listener attaches.
 *
 * Shares can be resolved before Flutter is listening — an `eventSink?.success`
 * on a null sink drops the file with no trace, which is exactly how a share
 * that copied successfully still vanished. Buffered payloads replay in arrival
 * order on [attach]. A list, not a single slot: two shares can arrive back to
 * back while the engine boots, and each has already been copied to cache, so
 * overwriting would strand one on disk.
 */
internal class ShareDeliveryBuffer {
    private var sink: ((String) -> Unit)? = null
    private val pending = mutableListOf<String>()

    val bufferedCount: Int get() = pending.size

    fun deliver(payload: String) {
        val current = sink
        if (current != null) current(payload) else pending.add(payload)
    }

    fun attach(listener: (String) -> Unit) {
        sink = listener
        if (pending.isEmpty()) return
        pending.forEach(listener)
        pending.clear()
    }

    fun detach() {
        sink = null
    }
}

/** Upper bound on a single shared file copied into cache (externally supplied stream). */
internal const val MAX_SHARE_BYTES: Long = 100L * 1024 * 1024

/**
 * Copies [input] to [output], giving up once more than [maxBytes] have been read.
 * Returns false when the limit was exceeded (the caller must discard the output).
 */
internal fun copyBounded(input: InputStream, output: OutputStream, maxBytes: Long): Boolean {
    val buffer = ByteArray(8192)
    var total = 0L
    while (true) {
        val n = input.read(buffer)
        if (n < 0) return true
        total += n
        if (total > maxBytes) return false
        output.write(buffer, 0, n)
    }
}

/**
 * Resolves shared files by reading their bytes directly via ContentResolver
 * and copying them to app cache. This exists because receive_sharing_intent's
 * FileDirectory.getAbsolutePath() resolves content:// URIs by translating them
 * into legacy content://downloads/public_downloads/<id> lookups, which throws
 * "Unknown URI" for modern SAF DocumentsProvider URIs (e.g. anything shared
 * via a Downloads/Files picker) — the file silently never reaches Dart.
 * ContentResolver.openInputStream() works for any content:// URI the intent
 * already granted read access to, regardless of provider.
 *
 * Any app can fire an implicit ACTION_VIEW at this activity (it's exported with
 * a BROWSABLE intent-filter) — that's the mechanism "Open with" relies on.
 * Android's URI-grant permission model is the trust boundary, not this code;
 * a URI without a valid grant fails in copyToCache() (caught, returns null),
 * it doesn't bypass anything.
 */
class SharePlugin(
    private val activity: Activity,
    private val deliveredBeforeRestore: () -> Boolean = { false },
    private val onDelivered: () -> Unit = {},
) {
    private val deliveries = ShareDeliveryBuffer()
    private val copyExecutor = Executors.newSingleThreadExecutor()

    companion object {
        private const val TAG = "PaperlessShare"
        private const val METHOD_CHANNEL = "com.ventoux.paperlessgo/share"
        private const val EVENT_CHANNEL = "com.ventoux.paperlessgo/share_stream"
        private const val EXTRA_DELIVERED = "com.ventoux.paperlessgo.SHARE_DELIVERED"

        /**
         * Whether to emit the verbose share trace.
         *
         * These lines carry the user's real filenames and provider URIs, and
         * Log.d compiles into release builds — the same leak that got the Dart
         * debugPrints removed. Log.isLoggable is false by default at DEBUG
         * level, so this is off everywhere until someone opts in with:
         *
         *   adb shell setprop log.tag.PaperlessShare DEBUG
         */
        private fun verbose(): Boolean = Log.isLoggable(TAG, Log.DEBUG)
    }

    fun register(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialShare" -> {
                        val current = activity.intent
                        if (current == null || wasDelivered(current)) {
                            if (verbose()) Log.d(TAG, "getInitialShare: intent already delivered, skipping")
                            result.success(sharePayload(JSONArray(), 0))
                        } else {
                            // Marked only on the main thread after the copy.
                            // Copying runs off the main thread: the stream is
                            // externally supplied and may be large or slow.
                            copyExecutor.execute {
                                val resolved = resolveIntentSafely(current)
                                activity.runOnUiThread {
                                    // Re-check: a concurrent request may have
                                    // delivered this intent while we copied.
                                    if (wasDelivered(current)) {
                                        result.success(sharePayload(JSONArray(), 0))
                                        return@runOnUiThread
                                    }
                                    if (shouldMarkDelivered(resolved.files.length(), resolved.requested)) {
                                        markDelivered(current)
                                    }
                                    result.success(sharePayload(resolved.files, resolved.requested))
                                }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    if (verbose()) Log.d(TAG, "onListen: replaying ${deliveries.bufferedCount} buffered share(s)")
                    deliveries.attach { events.success(it) }
                }

                override fun onCancel(arguments: Any?) {
                    deliveries.detach()
                }
            })
    }

    fun onNewIntent(intent: Intent) {
        if (verbose()) Log.d(TAG, "onNewIntent: action=${intent.action} data=${intent.data} type=${intent.type}")
        if (wasDelivered(intent)) {
            if (verbose()) Log.d(TAG, "onNewIntent: intent already delivered, skipping")
            return
        }
        copyExecutor.execute {
            val resolved = resolveIntentSafely(intent)
            activity.runOnUiThread {
                if (!wasDelivered(intent)) deliverResolved(intent, resolved)
            }
        }
    }

    /**
     * Runs on the copy executor, where an uncaught throw (e.g. a malformed
     * parcelable extra) would kill the worker and leave the Dart future
     * unanswered. Degrade to "nothing resolved" so the caller always replies.
     */
    private fun resolveIntentSafely(intent: Intent): Resolved = try {
        resolveIntent(intent)
    } catch (e: Exception) {
        Log.w(TAG, "resolveIntent failed: ${e.javaClass.simpleName}")
        Resolved(JSONArray(), 0)
    }

    private fun deliverResolved(intent: Intent, resolved: Resolved) {
        val files = resolved.files
        if (verbose()) Log.d(TAG, "onNewIntent: resolved ${files.length()} of ${resolved.requested} file(s)")
        // An intent that carried no file at all is not a share; say nothing.
        if (resolved.requested == 0) return
        // See shouldMarkDelivered: delivering the payload (even an empty one,
        // which Dart turns into a notice) spends the intent, so a recreated
        // Activity cannot re-copy and re-push the same share.
        if (shouldMarkDelivered(files.length(), resolved.requested)) {
            markDelivered(intent)
        }

        deliveries.deliver(sharePayload(files, resolved.requested))
    }

    private fun wasDelivered(intent: Intent): Boolean = isAlreadyDelivered(
        marked = intent.getBooleanExtra(EXTRA_DELIVERED, false),
        flags = intent.flags,
        deliveredBeforeRestore = deliveredBeforeRestore(),
    )

    private fun markDelivered(intent: Intent) {
        intent.putExtra(EXTRA_DELIVERED, true)
        // Also persist it into the Activity's saved state, which is the only
        // signal that survives process death.
        onDelivered()
    }

    /** Files that copied, alongside how many the intent actually asked for. */
    private data class Resolved(val files: JSONArray, val requested: Int)

    private fun resolveIntent(intent: Intent?): Resolved {
        if (intent == null) return Resolved(JSONArray(), 0)
        val uris: List<Uri> = when (selectSource(intent.action, intent.data?.scheme)) {
            ShareSource.EXTRA_STREAM -> when (intent.action) {
                Intent.ACTION_SEND ->
                    parcelableExtra<Uri>(intent, Intent.EXTRA_STREAM)?.let { listOf(it) } ?: emptyList()
                Intent.ACTION_SEND_MULTIPLE ->
                    parcelableArrayListExtra<Uri>(intent, Intent.EXTRA_STREAM) ?: emptyList()
                else -> emptyList()
            }
            ShareSource.INTENT_DATA -> intent.data?.let { listOf(it) } ?: emptyList()
            ShareSource.NONE -> emptyList()
        }.filter { isCopyableUri(it.scheme) }
        if (verbose()) Log.d(TAG, "resolveIntent: action=${intent.action} extracted ${uris.size} uri(s): $uris")

        val results = JSONArray()
        for (uri in uris) {
            copyToCache(uri, intent.type)?.let { results.put(it) }
        }
        return Resolved(results, uris.size)
    }

    private fun copyToCache(uri: Uri, intentMimeType: String?): JSONObject? {
        return try {
            val resolver = activity.contentResolver
            val displayName = queryDisplayName(uri) ?: "shared_${System.currentTimeMillis()}"
            val mimeType = intentMimeType ?: resolver.getType(uri)
            val targetFile = File(activity.cacheDir, "share_${System.currentTimeMillis()}_$displayName")
            if (verbose()) Log.d(TAG, "copyToCache: uri=$uri displayName=$displayName mimeType=$mimeType target=${targetFile.absolutePath}")
            val copied = resolver.openInputStream(uri)?.use { input ->
                FileOutputStream(targetFile).use { output -> copyBounded(input, output, MAX_SHARE_BYTES) }
            } ?: false
            if (!copied) targetFile.delete()
            if (verbose()) Log.d(TAG, "copyToCache: copied=$copied exists=${targetFile.exists()} size=${targetFile.length()}")
            if (!copied) return null

            JSONObject()
                .put("path", targetFile.absolutePath)
                .put("filename", displayName)
                .put("mimeType", mimeType)
        } catch (e: Exception) {
            Log.e(TAG, "copyToCache failed: ${e.javaClass.simpleName}")
            null
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        if (uri.scheme != "content") return uri.lastPathSegment
        return activity.contentResolver
            .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (!cursor.moveToFirst()) return@use null
                val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (idx >= 0) cursor.getString(idx) else null
            }
    }

    @Suppress("DEPRECATION")
    private inline fun <reified T : Parcelable> parcelableExtra(intent: Intent, key: String): T? =
        if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(key, T::class.java)
        } else {
            intent.getParcelableExtra(key) as? T
        }

    @Suppress("DEPRECATION")
    private inline fun <reified T : Parcelable> parcelableArrayListExtra(
        intent: Intent,
        key: String,
    ): ArrayList<T>? =
        if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableArrayListExtra(key, T::class.java)
        } else {
            intent.getParcelableArrayListExtra(key)
        }
}
