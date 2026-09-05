package com.pushtomaindev.kinkitchen.ui.theme

import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

/**
 * Mirrors iOS `KinColors`. Values ported from Assets.xcassets colorsets,
 * preserving each color's light/dark pair.
 */
@Suppress("MagicNumber")
object KinPalette {
    // Base
    val BackgroundLight = Color(0xFFF8EFE3)
    val BackgroundDark = Color(0xFF101828)
    val SurfaceLight = Color(0xFFFFFDF9)
    val SurfaceDark = Color(0xFF1D2939)

    // Text
    val PrimaryTextLight = Color(0xFF1D2939)
    val PrimaryTextDark = Color(0xFFFCF8F1)
    val SecondaryTextLight = Color(0xFF667085)
    val SecondaryTextDark = Color(0xFF98A2B3)

    // Brand
    val PrimaryLight = Color(0xFFB70816)
    val PrimaryDark = Color(0xFFE02D3C)
    val SecondaryLight = Color(0xFF91B87D)
    val SecondaryDark = Color(0xFFA8C99A)
    val AccentLight = Color(0xFFFFC72C)
    val AccentDark = Color(0xFFFFD666)

    // Status
    val ErrorLight = Color(0xFFE53935)
    val ErrorDark = Color(0xFFF97066)
    val WarningLight = Color(0xFFF28C28)
    val WarningDark = Color(0xFFFDB022)
    val SuccessLight = Color(0xFF28A745)
    val SuccessDark = Color(0xFF4CCB70)
}

/** The semantic color slots iOS exposes via `KinColors`. */
@Immutable
data class KinColorScheme(
    val background: Color,
    val surface: Color,
    val primaryText: Color,
    val secondaryText: Color,
    val primary: Color,
    val secondary: Color,
    val accent: Color,
    val error: Color,
    val warning: Color,
    val success: Color,
)

val LightKinColors = KinColorScheme(
    background = KinPalette.BackgroundLight,
    surface = KinPalette.SurfaceLight,
    primaryText = KinPalette.PrimaryTextLight,
    secondaryText = KinPalette.SecondaryTextLight,
    primary = KinPalette.PrimaryLight,
    secondary = KinPalette.SecondaryLight,
    accent = KinPalette.AccentLight,
    error = KinPalette.ErrorLight,
    warning = KinPalette.WarningLight,
    success = KinPalette.SuccessLight,
)

val DarkKinColors = KinColorScheme(
    background = KinPalette.BackgroundDark,
    surface = KinPalette.SurfaceDark,
    primaryText = KinPalette.PrimaryTextDark,
    secondaryText = KinPalette.SecondaryTextDark,
    primary = KinPalette.PrimaryDark,
    secondary = KinPalette.SecondaryDark,
    accent = KinPalette.AccentDark,
    error = KinPalette.ErrorDark,
    warning = KinPalette.WarningDark,
    success = KinPalette.SuccessDark,
)

val LocalKinColors = staticCompositionLocalOf { LightKinColors }

/** Usage: `KinColors.primary` — the closest Compose analogue to iOS's `KinColors.primary`. */
object KinColors {
    val background: Color @Composable @ReadOnlyComposable get() = LocalKinColors.current.background
    val surface: Color @Composable @ReadOnlyComposable get() = LocalKinColors.current.surface
    val primaryText: Color @Composable @ReadOnlyComposable get() = LocalKinColors.current.primaryText
    val secondaryText: Color @Composable @ReadOnlyComposable get() = LocalKinColors.current.secondaryText
    val primary: Color @Composable @ReadOnlyComposable get() = LocalKinColors.current.primary
    val secondary: Color @Composable @ReadOnlyComposable get() = LocalKinColors.current.secondary
    val accent: Color @Composable @ReadOnlyComposable get() = LocalKinColors.current.accent
    val error: Color @Composable @ReadOnlyComposable get() = LocalKinColors.current.error
    val warning: Color @Composable @ReadOnlyComposable get() = LocalKinColors.current.warning
    val success: Color @Composable @ReadOnlyComposable get() = LocalKinColors.current.success
}
