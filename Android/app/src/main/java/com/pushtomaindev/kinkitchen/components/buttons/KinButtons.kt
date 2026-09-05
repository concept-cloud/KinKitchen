package com.pushtomaindev.kinkitchen.components.buttons

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.pushtomaindev.kinkitchen.ui.theme.*

/** Mirrors iOS `KinPrimaryButton`. */
@Composable
fun KinPrimaryButton(
    title: String,
    modifier: Modifier = Modifier,
    color: Color = KinColors.primary,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    Text(
        text = title,
        style = KinTypography.button,
        color = KinColors.background,
        textAlign = TextAlign.Center,
        modifier = modifier
            .fillMaxWidth()
            .clip(KinRadius.mediumShape)
            .background(color)
            .clickable(enabled = enabled, role = Role.Button, onClick = onClick)
            .padding(vertical = KinSpacing.medium),
    )
}

/** Mirrors iOS `KinSecondaryButton`. */
@Composable
fun KinSecondaryButton(
    title: String,
    modifier: Modifier = Modifier,
    color: Color = KinColors.primary,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    Text(
        text = title,
        style = KinTypography.button,
        color = color,
        textAlign = TextAlign.Center,
        modifier = modifier
            .fillMaxWidth()
            .clip(KinRadius.mediumShape)
            .background(KinColors.surface)
            .border(1.dp, color, KinRadius.mediumShape)
            .clickable(enabled = enabled, role = Role.Button, onClick = onClick)
            .padding(vertical = KinSpacing.medium),
    )
}

/** Mirrors iOS `KinDestructiveButton`. */
@Composable
fun KinDestructiveButton(
    title: String,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    Text(
        text = title,
        style = KinTypography.button,
        color = Color.White,
        textAlign = TextAlign.Center,
        modifier = modifier
            .fillMaxWidth()
            .clip(KinRadius.mediumShape)
            .background(KinColors.error)
            .clickable(enabled = enabled, role = Role.Button, onClick = onClick)
            .padding(vertical = KinSpacing.medium),
    )
}

/**
 * Mirrors iOS `KinIconButton`. The 44dp frame matches iOS's minimum tap
 * target, which also clears Android's 48dp guidance once padding is included.
 */
@Composable
fun KinIconButton(
    icon: ImageVector,
    contentDescription: String?,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    Box(
        contentAlignment = Alignment.Center,
        modifier = modifier
            .size(44.dp)
            .clip(CircleShape)
            .background(KinColors.surface)
            .clickable(enabled = enabled, role = Role.Button, onClick = onClick),
    ) {
        Icon(
            imageVector = icon,
            contentDescription = contentDescription,
            tint = KinColors.primary,
            modifier = Modifier.size(20.dp),
        )
    }
}

@Preview(showBackground = true, backgroundColor = 0xFFF8EFE3)
@Composable
private fun KinButtonsPreview() {
    KinKitchenTheme {
        Column(
            verticalArrangement = Arrangement.spacedBy(KinSpacing.medium),
            modifier = Modifier.background(KinColors.background).padding(KinSpacing.large),
        ) {
            KinPrimaryButton("Continue") {}
            KinSecondaryButton("Cancel") {}
            KinDestructiveButton("Delete") {}
            Row(horizontalArrangement = Arrangement.spacedBy(KinSpacing.small)) {
                KinIconButton(KinIcons.add, "Add") {}
                KinIconButton(KinIcons.edit, "Edit") {}
                KinIconButton(KinIcons.favorite, "Favorite") {}
            }
        }
    }
}
