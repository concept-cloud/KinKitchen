package com.pushtomaindev.kinkitchen.components.navigation

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.tooling.preview.Preview
import com.pushtomaindev.kinkitchen.components.buttons.KinIconButton
import com.pushtomaindev.kinkitchen.ui.theme.*

/** Mirrors iOS `KinNavigationBar`. */
@Composable
fun KinNavigationBar(
    title: String,
    modifier: Modifier = Modifier,
    showBackButton: Boolean = false,
    actionIcon: ImageVector? = null,
    actionContentDescription: String? = null,
    onBack: (() -> Unit)? = null,
    onAction: (() -> Unit)? = null,
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .background(KinColors.background)
            .padding(horizontal = KinSpacing.large, vertical = KinSpacing.small),
    ) {
        if (showBackButton) {
            KinIconButton(KinIcons.back, contentDescription = "Back") { onBack?.invoke() }
            Spacer(Modifier.width(KinSpacing.small))
        }

        Text(title, style = KinTypography.navigationTitle, color = KinColors.primaryText)

        Spacer(Modifier.weight(1f))

        if (actionIcon != null) {
            KinIconButton(actionIcon, contentDescription = actionContentDescription) { onAction?.invoke() }
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFFF8EFE3)
@Composable
private fun KinNavigationBarPreview() {
    KinKitchenTheme {
        KinNavigationBar("Profile", showBackButton = true, actionIcon = KinIcons.settings, actionContentDescription = "Settings")
    }
}
