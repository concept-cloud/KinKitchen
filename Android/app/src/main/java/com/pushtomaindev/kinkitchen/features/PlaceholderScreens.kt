package com.pushtomaindev.kinkitchen.features

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.pushtomaindev.kinkitchen.ui.theme.*

/**
 * Shared body for the three feature screens that are placeholders in iOS
 * today (Gatherings, Recipes, Cookbooks).
 */
@Composable
private fun PlaceholderScreen(
    icon: ImageVector,
    title: String,
    message: String,
    modifier: Modifier = Modifier,
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(KinSpacing.large, Alignment.CenterVertically),
        modifier = modifier
            .fillMaxSize()
            .background(KinColors.background)
            .padding(horizontal = KinSpacing.large),
    ) {
        Icon(icon, contentDescription = null, tint = KinColors.primary, modifier = Modifier.size(48.dp))
        Text(title, style = KinTypography.largeTitle, color = KinColors.primaryText)
        Text(message, style = KinTypography.body, color = KinColors.secondaryText, textAlign = TextAlign.Center)
    }
}

/** Mirrors iOS `GatheringsView`. */
@Composable
fun GatheringsView(modifier: Modifier = Modifier) = PlaceholderScreen(
    icon = KinIcons.gatherings,
    title = "Gatherings",
    message = "Your upcoming gatherings will appear here.",
    modifier = modifier,
)

/** Mirrors iOS `RecipesView`. */
@Composable
fun RecipesView(modifier: Modifier = Modifier) = PlaceholderScreen(
    icon = KinIcons.recipes,
    title = "Recipes",
    message = "Your recipes will appear here.",
    modifier = modifier,
)

/** Mirrors iOS `CookbooksView`. */
@Composable
fun CookbooksView(modifier: Modifier = Modifier) = PlaceholderScreen(
    icon = KinIcons.cookbooks,
    title = "Cookbooks",
    message = "Your private cookbooks and recipe collections will appear here.",
    modifier = modifier,
)
