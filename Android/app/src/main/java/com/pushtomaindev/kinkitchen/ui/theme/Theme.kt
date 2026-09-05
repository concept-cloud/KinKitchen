package com.pushtomaindev.kinkitchen.ui.theme

import android.app.Activity
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat
import androidx.compose.ui.graphics.Color

private fun materialSchemeFrom(kin: KinColorScheme, dark: Boolean) = if (dark) {
    darkColorScheme(
        primary = kin.primary,
        onPrimary = Color.White,
        secondary = kin.secondary,
        onSecondary = KinPalette.PrimaryTextLight,
        tertiary = kin.accent,
        onTertiary = KinPalette.PrimaryTextLight,
        background = kin.background,
        onBackground = kin.primaryText,
        surface = kin.surface,
        onSurface = kin.primaryText,
        onSurfaceVariant = kin.secondaryText,
        error = kin.error,
        onError = Color.White,
    )
} else {
    lightColorScheme(
        primary = kin.primary,
        onPrimary = Color.White,
        secondary = kin.secondary,
        onSecondary = KinPalette.PrimaryTextLight,
        tertiary = kin.accent,
        onTertiary = KinPalette.PrimaryTextLight,
        background = kin.background,
        onBackground = kin.primaryText,
        surface = kin.surface,
        onSurface = kin.primaryText,
        onSurfaceVariant = kin.secondaryText,
        error = kin.error,
        onError = Color.White,
    )
}

/**
 * iOS drives appearance from `@AppStorage("kinAppearanceMode")` via
 * `.preferredColorScheme`, so the app's own setting wins over the system
 * theme. [darkTheme] defaults to that stored preference for the same reason.
 */
@Composable
fun KinKitchenTheme(
    darkTheme: Boolean = AppearanceStore.mode == AppearanceMode.DARK,
    content: @Composable () -> Unit
) {
    val kinColors = if (darkTheme) DarkKinColors else LightKinColors
    val appearance = if (darkTheme) AppearanceMode.DARK else AppearanceMode.LIGHT

    // enableEdgeToEdge() picks system-bar icon colour from the *system*
    // theme. The app sets its own appearance, so keep the icons legible
    // against whichever background we actually painted.
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            WindowCompat.getInsetsController(window, view).apply {
                isAppearanceLightStatusBars = !darkTheme
                isAppearanceLightNavigationBars = !darkTheme
            }
        }
    }

    CompositionLocalProvider(
        LocalKinColors provides kinColors,
        LocalAppearanceMode provides appearance,
    ) {
        MaterialTheme(
            colorScheme = materialSchemeFrom(kinColors, darkTheme),
            typography = KinMaterialTypography,
            content = content
        )
    }
}
