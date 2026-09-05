package com.pushtomaindev.kinkitchen.components.labels

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import com.pushtomaindev.kinkitchen.ui.theme.*

/** Mirrors iOS `KinBadge`. */
@Composable
fun KinBadge(title: String, color: Color, modifier: Modifier = Modifier) {
    Text(
        text = title,
        style = KinTypography.caption,
        color = KinColors.background,
        modifier = modifier
            .clip(CircleShape)
            .background(color)
            .padding(horizontal = KinSpacing.small, vertical = KinSpacing.xSmall),
    )
}

/** Mirrors iOS `KinChip`. */
@Composable
fun KinChip(title: String, modifier: Modifier = Modifier, isSelected: Boolean = false) {
    Text(
        text = title,
        style = KinTypography.caption,
        color = if (isSelected) KinColors.background else KinColors.primaryText,
        modifier = modifier
            .clip(CircleShape)
            .background(if (isSelected) KinColors.primary else KinColors.surface)
            .padding(horizontal = KinSpacing.medium, vertical = KinSpacing.small),
    )
}

/** Mirrors iOS `KinStatusType`. */
enum class KinStatusType {
    SUCCESS, WARNING, ERROR, INFO;

    val color: Color
        @Composable @ReadOnlyComposable get() = when (this) {
            SUCCESS -> KinColors.success
            WARNING -> KinColors.warning
            ERROR -> KinColors.error
            INFO -> KinColors.secondary
        }
}

/** Mirrors iOS `KinStatusBadge`. */
@Composable
fun KinStatusBadge(title: String, status: KinStatusType, modifier: Modifier = Modifier) {
    Text(
        text = title,
        style = KinTypography.caption,
        color = KinColors.background,
        modifier = modifier
            .clip(CircleShape)
            .background(status.color)
            .padding(horizontal = KinSpacing.small, vertical = KinSpacing.xSmall),
    )
}

@Preview(showBackground = true, backgroundColor = 0xFFF8EFE3)
@Composable
private fun KinLabelsPreview() {
    KinKitchenTheme {
        Column(
            verticalArrangement = Arrangement.spacedBy(KinSpacing.small),
            modifier = Modifier.background(KinColors.background).padding(KinSpacing.large),
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(KinSpacing.small)) {
                KinBadge("New", KinColors.primary)
                KinChip("Vegan", isSelected = true)
                KinChip("Gluten Free")
            }
            Row(horizontalArrangement = Arrangement.spacedBy(KinSpacing.small)) {
                KinStatusBadge("Safe", KinStatusType.SUCCESS)
                KinStatusBadge("Check", KinStatusType.WARNING)
                KinStatusBadge("Allergen", KinStatusType.ERROR)
                KinStatusBadge("Info", KinStatusType.INFO)
            }
        }
    }
}
