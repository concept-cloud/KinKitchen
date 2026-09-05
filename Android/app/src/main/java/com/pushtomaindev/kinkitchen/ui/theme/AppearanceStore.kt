package com.pushtomaindev.kinkitchen.ui.theme

import android.content.Context
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

/** Mirrors the values iOS stores in `@AppStorage("kinAppearanceMode")`. */
enum class AppearanceMode(val stored: String) {
    LIGHT("light"),
    DARK("dark");

    companion object {
        fun from(stored: String?) = entries.firstOrNull { it.stored == stored } ?: LIGHT
    }
}

/**
 * Mirrors iOS `@AppStorage("kinAppearanceMode")`. iOS applies an explicit
 * `.preferredColorScheme` rather than following the system setting, and
 * defaults to light, so this does the same.
 */
object AppearanceStore {

    private const val PREFS = "kin_settings"
    private const val KEY = "kinAppearanceMode"

    private var prefs: android.content.SharedPreferences? = null

    /** Backed by Compose state so a change recomposes the theme immediately. */
    var mode by mutableStateOf(AppearanceMode.LIGHT)
        private set

    fun init(context: Context) {
        if (prefs != null) return
        val p = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        prefs = p
        mode = AppearanceMode.from(p.getString(KEY, AppearanceMode.LIGHT.stored))
    }

    fun select(newMode: AppearanceMode) {
        mode = newMode
        prefs?.edit()?.putString(KEY, newMode.stored)?.apply()
    }
}

val LocalAppearanceMode = compositionLocalOf { AppearanceMode.LIGHT }
