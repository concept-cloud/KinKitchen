package com.pushtomaindev.kinkitchen.components.navigation

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.pushtomaindev.kinkitchen.ui.theme.*

/** Mirrors iOS `KinTabBarItem`. */
data class KinTabBarItem(val title: String, val icon: ImageVector)

/** Mirrors iOS `KinTabBar`. */
@Composable
fun KinTabBar(
    items: List<KinTabBarItem>,
    selectedIndex: Int,
    modifier: Modifier = Modifier,
    onSelect: (Int) -> Unit,
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(KinColors.surface)
            .padding(vertical = KinSpacing.small),
    ) {
        items.forEachIndexed { index, item ->
            val selected = index == selectedIndex
            val tint = if (selected) KinColors.primary else KinColors.secondaryText

            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(KinSpacing.xSmall),
                modifier = Modifier
                    .weight(1f)
                    .clickable(
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
                        role = Role.Tab,
                    ) { onSelect(index) },
            ) {
                Icon(item.icon, contentDescription = item.title, tint = tint, modifier = Modifier.size(24.dp))
                Text(item.title, style = KinTypography.caption2, color = tint)
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun KinTabBarPreview() {
    KinKitchenTheme {
        KinTabBar(
            items = listOf(
                KinTabBarItem("Home", KinIcons.home),
                KinTabBarItem("Gatherings", KinIcons.gatherings),
                KinTabBarItem("Recipes", KinIcons.recipes),
                KinTabBarItem("Cookbooks", KinIcons.cookbooks),
                KinTabBarItem("Profile", KinIcons.profile),
            ),
            selectedIndex = 0,
        ) {}
    }
}
