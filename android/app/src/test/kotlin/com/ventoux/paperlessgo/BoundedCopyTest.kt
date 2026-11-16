package com.ventoux.paperlessgo

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

class BoundedCopyTest {
    @Test
    fun `copies a stream within the limit`() {
        val out = ByteArrayOutputStream()
        assertTrue(copyBounded(ByteArrayInputStream(ByteArray(100)), out, 100))
        assertEquals(100, out.size())
    }

    @Test
    fun `rejects a stream over the limit and stops reading`() {
        val out = ByteArrayOutputStream()
        val input = ByteArrayInputStream(ByteArray(10_000))
        assertFalse(copyBounded(input, out, 100))
        assertTrue(out.size() <= 100 + 8192)
        assertTrue(input.available() > 0)
    }
}
