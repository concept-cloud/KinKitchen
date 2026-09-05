package com.pushtomaindev.kinkitchen.services.supabase

import io.github.jan.supabase.auth.exception.AuthErrorCode
import io.github.jan.supabase.auth.exception.AuthRestException
import io.github.jan.supabase.exceptions.HttpRequestException
import java.io.IOException

/**
 * Turns a Supabase failure into something safe to show a user.
 *
 * Do NOT surface `Throwable.message` from supabase-kt directly: `RestException`
 * builds its message from the whole HTTP exchange, so it includes the request
 * URL and the `Authorization` / `apikey` headers. Rendering that in the UI puts
 * credentials on screen — and into any screenshot or bug report of it.
 *
 * iOS shows `error.localizedDescription`, which is already short; this is the
 * Android equivalent rather than an extra layer.
 */
fun Throwable.userFacingAuthMessage(): String = when (this) {
    is AuthRestException -> when (errorCode) {
        AuthErrorCode.InvalidCredentials -> "That email or password is incorrect."
        AuthErrorCode.EmailNotConfirmed ->
            "Check your email and confirm your account before signing in."
        AuthErrorCode.UserAlreadyExists, AuthErrorCode.EmailExists ->
            "An account with that email already exists."
        AuthErrorCode.WeakPassword -> "Please choose a stronger password."
        AuthErrorCode.SignupDisabled -> "New accounts are not being accepted right now."
        AuthErrorCode.UserBanned -> "This account has been suspended."
        AuthErrorCode.OverRequestRateLimit, AuthErrorCode.OverEmailSendRateLimit ->
            "Too many attempts. Please wait a minute and try again."
        AuthErrorCode.SessionExpired, AuthErrorCode.SessionNotFound ->
            "Your session expired. Please sign in again."
        // errorDescription is the server's short text, without request details.
        else -> errorDescription.ifBlank { GENERIC }
    }

    is HttpRequestException, is IOException ->
        "Could not reach Kin Kitchen. Check your connection and try again."

    else -> GENERIC
}

private const val GENERIC = "Something went wrong. Please try again."
