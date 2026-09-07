package com.ventoux.paperlessgo

import android.content.Intent
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Test

/**
 * Regression coverage for the two ways a *successfully resolved* share still
 * reached the user as nothing at all — both observed in logcat on a real
 * device share, after the URI selection covered by [SharePluginUriSelectionTest]
 * had already been fixed:
 *
 *  - "resolved 1 file(s), eventSink=false" — the intent beat Dart's
 *    EventChannel listener and the payload was dropped on a null sink.
 *  - "getInitialShare returned: []" — activity.intent was stale, so the
 *    follow-up query resolved the wrong intent.
 *
 * Fixing the second (calling setIntent) is what makes the third case below
 * possible, so the delivery mark is tested alongside it.
 */
class ShareDeliveryBufferTest {
    @Test
    fun `payload delivered while a listener is attached goes straight through`() {
        val buffer = ShareDeliveryBuffer()
        val received = mutableListOf<String>()
        buffer.attach { received.add(it) }

        buffer.deliver("[{\"path\":\"/a.pdf\"}]")

        assertEquals(listOf("[{\"path\":\"/a.pdf\"}]"), received)
    }

    @Test
    fun `payload delivered before any listener is replayed on attach`() {
        val buffer = ShareDeliveryBuffer()
        buffer.deliver("[{\"path\":\"/a.pdf\"}]")
        assertEquals(1, buffer.bufferedCount)

        val received = mutableListOf<String>()
        buffer.attach { received.add(it) }

        assertEquals(listOf("[{\"path\":\"/a.pdf\"}]"), received)
        assertEquals(0, buffer.bufferedCount)
    }

    @Test
    fun `two shares arriving before a listener are both replayed, in order`() {
        val buffer = ShareDeliveryBuffer()
        buffer.deliver("first")
        buffer.deliver("second")

        val received = mutableListOf<String>()
        buffer.attach { received.add(it) }

        assertEquals(listOf("first", "second"), received)
    }

    @Test
    fun `a replayed payload is not delivered again on a later attach`() {
        val buffer = ShareDeliveryBuffer()
        buffer.deliver("only once")
        buffer.attach { }
        buffer.detach()

        val received = mutableListOf<String>()
        buffer.attach { received.add(it) }

        assertEquals(emptyList<String>(), received)
    }

    @Test
    fun `payloads buffer again after the listener detaches`() {
        val buffer = ShareDeliveryBuffer()
        buffer.attach { }
        buffer.detach()

        buffer.deliver("while detached")

        assertEquals(1, buffer.bufferedCount)
    }
}

class ShareMarkOnDeliveryTest {
    @Test
    fun `a resolved file burns the intent`() {
        assertTrue(shouldMarkDelivered(resolvedCount = 1, requestedCount = 1))
    }

    @Test
    fun `an empty resolve still burns the intent, because Dart reports it`() {
        // Previously left unmarked so a transient copy failure stayed
        // retryable. Now the empty payload reaches Dart as a "could not read
        // the shared file" notice, and an unmarked intent would only let a
        // recreated Activity deliver that same failure (or, for a partial
        // result, re-copy and re-push the readable files) a second time.
        assertTrue(shouldMarkDelivered(resolvedCount = 0, requestedCount = 1))
    }

    @Test
    fun `a fully delivered multi-file share burns the intent`() {
        assertTrue(shouldMarkDelivered(resolvedCount = 3, requestedCount = 3))
    }

    @Test
    fun `a PARTIAL multi-file share burns the intent too`() {
        // The two readable files are routed and the third is reported as
        // skipped; nothing is lost without trace any more, and re-resolving
        // would duplicate the two that worked.
        assertTrue(shouldMarkDelivered(resolvedCount = 2, requestedCount = 3))
    }

    @Test
    fun `an intent that requested nothing is never marked`() {
        assertFalse(shouldMarkDelivered(resolvedCount = 0, requestedCount = 0))
    }
}

class ShareDeliveryMarkTest {
    @Test
    fun `a fresh share intent has not been delivered`() {
        assertFalse(isAlreadyDelivered(marked = false, flags = 0))
    }

    @Test
    fun `a marked intent is not resolved a second time`() {
        assertTrue(isAlreadyDelivered(marked = true, flags = 0))
    }

    @Test
    fun `relaunching from Recents does not re-deliver the share`() {
        assertTrue(
            isAlreadyDelivered(
                marked = false,
                flags = Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY,
            ),
        )
    }

    @Test
    fun `a share already delivered before a restore is not delivered twice`() {
        // Measured on a Pixel 9 Pro Fold: kill the process, relaunch from
        // Recents, and the share was resolved and copied a second time —
        // neither the intent extra nor LAUNCHED_FROM_HISTORY survived.
        assertTrue(
            isAlreadyDelivered(marked = false, flags = 0, deliveredBeforeRestore = true),
        )
    }

    @Test
    fun `a restore BEFORE any delivery still delivers the share`() {
        // The blunt version of this guard keyed on "savedInstanceState != null",
        // which is true for an Activity recreated before Dart ever asked for
        // the share — suppressing it dropped the file permanently.
        assertFalse(
            isAlreadyDelivered(marked = false, flags = 0, deliveredBeforeRestore = false),
        )
    }

    @Test
    fun `unrelated intent flags do not suppress a real share`() {
        assertFalse(
            isAlreadyDelivered(
                marked = false,
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION,
            ),
        )
    }
}

/**
 * The payload must let Dart tell "no share" apart from "a share we could not
 * read": both used to arrive as `[]`.
 */
class SharePayloadTest {
    @Test
    fun `a fully failed copy still reports how many files were asked for`() {
        val payload = JSONObject(sharePayload(JSONArray(), 1))
        assertEquals(0, payload.getJSONArray("files").length())
        assertEquals(1, payload.getInt("requested"))
    }

    @Test
    fun `readable files travel alongside the requested count`() {
        val files = JSONArray().put(JSONObject().put("path", "/a.pdf"))
        val payload = JSONObject(sharePayload(files, 2))
        assertEquals(1, payload.getJSONArray("files").length())
        assertEquals("/a.pdf", payload.getJSONArray("files").getJSONObject(0).getString("path"))
        assertEquals(2, payload.getInt("requested"))
    }
}
