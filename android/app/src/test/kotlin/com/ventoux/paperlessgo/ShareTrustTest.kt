package com.ventoux.paperlessgo

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

/**
 * The exported activity copies whatever content:// URI it is handed, with this
 * app's own identity. Our own providers (merged from plugins, exported or not)
 * grant us access without any URI grant, so a URI naming one of them would make
 * us copy our own private files on another app's behalf.
 */
class ProviderTrustTest {
    private val own = "com.ventouxlabs.paperlessgo"

    @Test
    fun `provider of another package is copyable`() {
        assertTrue(isForeignProvider("com.android.providers.downloads", own))
    }

    @Test
    fun `own provider is not copyable`() {
        assertFalse(isForeignProvider(own, own))
    }

    @Test
    fun `unresolvable provider is not copyable`() {
        assertFalse(isForeignProvider(null, own))
    }

    @Test
    fun `userId prefix is stripped like ContentResolver does`() {
        assertEquals("$own.flutter.share_provider", providerAuthority("0@$own.flutter.share_provider"))
    }

    @Test
    fun `plain authority is unchanged`() {
        assertEquals("media", providerAuthority("media"))
    }

    @Test
    fun `missing or empty authority yields null`() {
        assertNull(providerAuthority(null))
        assertNull(providerAuthority(""))
        assertNull(providerAuthority("0@"))
    }
}

/** DISPLAY_NAME comes from the sending app's provider and must not steer the cache path. */
class SafeShareNameTest {
    @get:Rule
    val tmp = TemporaryFolder()

    private val fallback = "shared_1"

    @Test
    fun `ordinary name is kept`() {
        assertEquals("invoice 2026.pdf", safeShareName("invoice 2026.pdf", fallback))
    }

    @Test
    fun `directory parts are dropped`() {
        assertEquals("x.xml", safeShareName("../../shared_prefs/x.xml", fallback))
        assertEquals("c.pdf", safeShareName("a/b\\c.pdf", fallback))
    }

    @Test
    fun `unusable names fall back`() {
        for (name in listOf(null, "", ".", "..", "/", "/../", "a/..", "\\")) {
            assertEquals("name=$name", fallback, safeShareName(name, fallback))
        }
    }

    @Test
    fun `hostile names stay directly inside the cache dir`() {
        val dir = tmp.root.canonicalFile
        for (name in listOf("../../x", "a/b\\c", "..", "/", "/../", "../", "share/../../../etc")) {
            val target = File(dir, "share_1_" + safeShareName(name, fallback)).canonicalFile
            assertEquals("name=$name", dir, target.parentFile)
        }
    }
}
