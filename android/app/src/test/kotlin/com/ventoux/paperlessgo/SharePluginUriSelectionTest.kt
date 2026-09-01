package com.ventoux.paperlessgo

import android.content.Intent
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Regression coverage for [selectSource] — the action→source dispatch that decides
 * where a shared file's URI comes from. This exact mapping has silently dropped an
 * action type three separate times (share-intent fixes in 10411c1, 810f061, cade169),
 * each time shipping a "fix" for one action while another (most recently ACTION_VIEW
 * / "Open with") fell through to the `else -> emptyList()` branch with no test to
 * catch it.
 */
class SharePluginUriSelectionTest {
    @Test
    fun `ACTION_SEND selects EXTRA_STREAM`() {
        assertEquals(ShareSource.EXTRA_STREAM, selectSource(Intent.ACTION_SEND, null))
    }

    @Test
    fun `ACTION_SEND_MULTIPLE selects EXTRA_STREAM`() {
        assertEquals(ShareSource.EXTRA_STREAM, selectSource(Intent.ACTION_SEND_MULTIPLE, null))
    }

    @Test
    fun `ACTION_VIEW with content scheme selects INTENT_DATA`() {
        assertEquals(ShareSource.INTENT_DATA, selectSource(Intent.ACTION_VIEW, "content"))
    }

    @Test
    fun `ACTION_VIEW with file scheme selects INTENT_DATA`() {
        assertEquals(ShareSource.INTENT_DATA, selectSource(Intent.ACTION_VIEW, "file"))
    }

    @Test
    fun `ACTION_VIEW with paperlessgo scheme is ignored (widget deep link, not a file)`() {
        assertEquals(ShareSource.NONE, selectSource(Intent.ACTION_VIEW, "paperlessgo"))
    }

    @Test
    fun `ACTION_VIEW with null scheme is ignored`() {
        assertEquals(ShareSource.NONE, selectSource(Intent.ACTION_VIEW, null))
    }

    @Test
    fun `unrecognized action is ignored`() {
        assertEquals(ShareSource.NONE, selectSource(Intent.ACTION_MAIN, "content"))
    }

    @Test
    fun `null action is ignored`() {
        assertEquals(ShareSource.NONE, selectSource(null, "content"))
    }
}

/**
 * Regression coverage for [shouldSuppressInitialRoute] — whether Flutter's default
 * Android embedding should be stopped from treating the launching Intent's data as
 * an initial deep-link route. Left unsuppressed for content/file schemes, an
 * ACTION_VIEW ("Open with") share races SharePlugin's own channel-based handling:
 * GoRouter's redirect() sees the raw content://file:// URI as an attempted route and
 * force-navigates to /inbox before the share actually lands, wiping whatever screen
 * the user was on. paperlessgo:// (the widget deep link) is also ACTION_VIEW and
 * must NOT be suppressed — it needs Flutter's normal routing to reach GoRouter.
 */
class InitialRouteSuppressionTest {
    @Test
    fun `content scheme is suppressed`() {
        assertTrue(shouldSuppressInitialRoute("content"))
    }

    @Test
    fun `file scheme is suppressed`() {
        assertTrue(shouldSuppressInitialRoute("file"))
    }

    @Test
    fun `paperlessgo scheme is not suppressed (widget deep link)`() {
        assertFalse(shouldSuppressInitialRoute("paperlessgo"))
    }

    @Test
    fun `null scheme is not suppressed`() {
        assertFalse(shouldSuppressInitialRoute(null))
    }
}
