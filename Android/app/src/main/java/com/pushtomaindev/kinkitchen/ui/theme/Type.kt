package com.pushtomaindev.kinkitchen.ui.theme

import androidx.compose.material3.Typography

/**
 * Material's typography slots, backed by the Kin type scale so stock Material
 * components (TextField, Snackbar, …) pick up Arvo/Lora automatically.
 */
val KinMaterialTypography = Typography(
    displayLarge = KinTypography.largeTitle,
    displayMedium = KinTypography.title,
    displaySmall = KinTypography.title2,
    headlineLarge = KinTypography.title,
    headlineMedium = KinTypography.title2,
    headlineSmall = KinTypography.title3,
    titleLarge = KinTypography.navigationTitle,
    titleMedium = KinTypography.headline,
    titleSmall = KinTypography.subheadline,
    bodyLarge = KinTypography.body,
    bodyMedium = KinTypography.callout,
    bodySmall = KinTypography.footnote,
    labelLarge = KinTypography.button,
    labelMedium = KinTypography.caption,
    labelSmall = KinTypography.caption2,
)
