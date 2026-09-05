package com.pushtomaindev.kinkitchen.services.supabase

import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.auth.status.SessionStatus
import io.github.jan.supabase.auth.user.UserInfo
import kotlinx.coroutines.flow.FlowCollector
import kotlinx.coroutines.flow.StateFlow

/**
 * A [StateFlow] whose value is computed from [source] on every read.
 *
 * `map { }.stateIn(scope, ...)` would publish through a background scope, so
 * `.value` can lag the source by a dispatch — right after `signIn` returns,
 * a reader could still observe the previous state. Deriving on read keeps
 * these views exactly as current as `Auth.sessionStatus` itself.
 */
private class DerivedStateFlow<T, R>(
    private val source: StateFlow<T>,
    private val transform: (T) -> R,
) : StateFlow<R> {

    override val value: R get() = transform(source.value)

    override val replayCache: List<R> get() = listOf(value)

    override suspend fun collect(collector: FlowCollector<R>): Nothing {
        source.collect { collector.emit(transform(it)) }
        error("StateFlow collection never completes.")
    }
}

/**
 * Mirrors iOS `AuthService`.
 *
 * iOS subscribes to `authStateChanges` and republishes three `@Published`
 * values; supabase-kt already exposes session state as a `StateFlow`, so
 * these are views over it rather than separately tracked state. That also
 * removes the manual task cancellation iOS needs in `deinit`.
 */
object AuthService {

    private val auth get() = SupabaseManager.client.auth

    val sessionStatus: StateFlow<SessionStatus> get() = auth.sessionStatus

    /** Mirrors iOS `currentUser`. */
    val currentUser: StateFlow<UserInfo?> =
        DerivedStateFlow(auth.sessionStatus) { (it as? SessionStatus.Authenticated)?.session?.user }

    /** Mirrors iOS `isAuthenticated`. */
    val isAuthenticated: StateFlow<Boolean> =
        DerivedStateFlow(auth.sessionStatus) { it is SessionStatus.Authenticated }

    /**
     * Mirrors iOS `isLoadingSession`. True until the stored session has been
     * loaded and refreshed, so the UI can hold the auth gate closed.
     */
    val isLoadingSession: StateFlow<Boolean> =
        DerivedStateFlow(auth.sessionStatus) { it is SessionStatus.Initializing }

    /** Synchronous read, equivalent to iOS's `auth.currentUser`. */
    fun currentUserOrNull(): UserInfo? = auth.currentUserOrNull()

    /** Suspends until the session has been restored from storage. */
    suspend fun awaitInitialization() = auth.awaitInitialization()

    suspend fun signUp(email: String, password: String) {
        auth.signUpWith(Email) {
            this.email = email
            this.password = password
        }
    }

    suspend fun signIn(email: String, password: String) {
        auth.signInWith(Email) {
            this.email = email
            this.password = password
        }
    }

    suspend fun signOut() {
        auth.signOut()
    }
}

/**
 * The signed-in user's id, or an error when there is no session — the Kotlin
 * equivalent of iOS's `try await client.auth.session.user`.
 */
internal fun requireUserId(): String =
    SupabaseManager.client.auth.currentUserOrNull()?.id
        ?: error("No authenticated user.")
