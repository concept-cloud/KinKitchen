package com.pushtomaindev.kinkitchen.services

import androidx.test.ext.junit.runners.AndroidJUnit4
import com.pushtomaindev.kinkitchen.services.supabase.AuthService
import com.pushtomaindev.kinkitchen.services.supabase.DietaryService
import com.pushtomaindev.kinkitchen.services.supabase.SupabaseManager
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.status.SessionStatus
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.storage.storage
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import org.junit.Assume.assumeTrue
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * On-device checks that the Supabase client actually stands up: credentials
 * reach BuildConfig, the session manager can persist to SharedPreferences,
 * and Postgrest reaches the network. Read-only — creates no data.
 */
@RunWith(AndroidJUnit4::class)
class SupabaseClientSmokeTest {

    @Test
    fun clientInitializesWithAllThreeModules() {
        val client = SupabaseManager.client
        assertNotNull("Auth module missing", client.auth)
        assertNotNull("Postgrest module missing", client.postgrest)
        assertNotNull("Storage module missing", client.storage)
    }

    /**
     * These checks describe a signed-out device. On a device with a live
     * session they are not meaningful, so skip rather than fail: a real
     * session is a valid state, not a defect.
     */
    private fun assumeSignedOut() {
        assumeTrue(
            "skipped: a session is active on this device",
            AuthService.currentUserOrNull() == null,
        )
    }

    @Test
    fun sessionSettlesRatherThanHanging() = runBlocking {
        // Exercises SettingsSessionManager: without a usable Context this
        // throws instead of settling. A signed-in device also refreshes its
        // token here, which is slower than a cold no-session start.
        withTimeout(45_000) { AuthService.awaitInitialization() }

        val status = AuthService.sessionStatus.value
        assertTrue(
            "expected a settled session status, got $status",
            status is SessionStatus.NotAuthenticated || status is SessionStatus.Authenticated,
        )
        assertTrue("isLoadingSession should have cleared", !AuthService.isLoadingSession.value)
    }

    @Test
    fun noSessionMeansNoCurrentUser() = runBlocking {
        withTimeout(45_000) { AuthService.awaitInitialization() }
        assumeSignedOut()
        assertNull(AuthService.currentUserOrNull())
    }

    @Test
    fun postgrestReachesTheNetworkAndDecodes() = runBlocking {
        // Anonymous reads are RLS-filtered, so the row count may be zero.
        // What matters is that the request completes and decodes without
        // throwing — that exercises Ktor, TLS, and kotlinx-serialization.
        val allergens = withTimeout(20_000) { DietaryService.fetchAllergens() }
        assertNotNull(allergens)
    }

    @Test
    fun unauthenticatedWritePathFailsCleanly() = runBlocking {
        withTimeout(45_000) { AuthService.awaitInitialization() }
        assumeSignedOut()
        // requireUserId() must raise a clear error rather than NPE when
        // no one is signed in.
        val error = runCatching {
            withTimeout(20_000) { DietaryService.fetchSelectedAllergens() }
        }.exceptionOrNull()
        assertNotNull("expected an error with no session", error)
        assertTrue(
            "expected a clear 'no authenticated user' message, got: ${error?.message}",
            error?.message?.contains("No authenticated user") == true,
        )
    }
}
