package com.pushtomaindev.kinkitchen.components.feedback

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.pushtomaindev.kinkitchen.components.buttons.KinPrimaryButton
import com.pushtomaindev.kinkitchen.ui.theme.*

/** Mirrors iOS `KinEmptyState`. */
@Composable
fun KinEmptyState(
    icon: ImageVector,
    title: String,
    message: String,
    modifier: Modifier = Modifier,
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(KinSpacing.medium),
        modifier = modifier.padding(KinSpacing.xLarge),
    ) {
        Icon(icon, contentDescription = null, tint = KinColors.secondaryText, modifier = Modifier.size(42.dp))
        Text(title, style = KinTypography.title3, color = KinColors.primaryText)
        Text(message, style = KinTypography.body, color = KinColors.secondaryText, textAlign = TextAlign.Center)
    }
}

/** Mirrors iOS `KinErrorView`. */
@Composable
fun KinErrorView(
    message: String,
    modifier: Modifier = Modifier,
    onRetry: (() -> Unit)? = null,
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(KinSpacing.medium),
        modifier = modifier.padding(KinSpacing.xLarge),
    ) {
        Icon(KinIcons.error, contentDescription = null, tint = KinColors.error, modifier = Modifier.size(36.dp))
        Text("Something Went Wrong", style = KinTypography.title3, color = KinColors.primaryText)
        Text(message, style = KinTypography.body, color = KinColors.secondaryText, textAlign = TextAlign.Center)

        if (onRetry != null) {
            KinPrimaryButton("Retry", onClick = onRetry)
        }
    }
}

/** Mirrors iOS `KinLoadingView`. */
@Composable
fun KinLoadingView(
    modifier: Modifier = Modifier,
    message: String = "Loading...",
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(KinSpacing.medium, Alignment.CenterVertically),
        modifier = modifier.fillMaxSize(),
    ) {
        CircularProgressIndicator(color = KinColors.primary)
        Text(message, style = KinTypography.body, color = KinColors.secondaryText)
    }
}

/** Mirrors iOS `KinWarning`. */
@Composable
fun KinWarning(
    title: String,
    message: String,
    modifier: Modifier = Modifier,
) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(KinSpacing.medium),
        modifier = modifier
            .fillMaxWidth()
            .clip(KinRadius.largeShape)
            .background(KinColors.surface)
            .padding(KinSpacing.large),
    ) {
        Icon(KinIcons.warning, contentDescription = null, tint = KinColors.warning)

        Column(verticalArrangement = Arrangement.spacedBy(KinSpacing.xSmall)) {
            Text(title, style = KinTypography.headline, color = KinColors.primaryText)
            Text(message, style = KinTypography.body, color = KinColors.secondaryText)
        }
    }
}

@Preview(showBackground = true, backgroundColor = 0xFFF8EFE3)
@Composable
private fun KinFeedbackPreview() {
    KinKitchenTheme {
        Column(
            verticalArrangement = Arrangement.spacedBy(KinSpacing.large),
            modifier = Modifier.background(KinColors.background).padding(KinSpacing.large),
        ) {
            KinWarning("Contains Peanuts", "Two guests have a severe peanut allergy.")
            KinEmptyState(KinIcons.recipes, "No Recipes Yet", "Recipes you save will show up here.")
            KinErrorView("Could not reach the server.") {}
        }
    }
}
