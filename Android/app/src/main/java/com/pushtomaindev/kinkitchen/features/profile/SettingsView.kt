package com.pushtomaindev.kinkitchen.features.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.LightMode
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import com.pushtomaindev.kinkitchen.components.navigation.KinNavigationBar
import com.pushtomaindev.kinkitchen.ui.theme.*

/** Mirrors iOS `SettingsView`. */
@Composable
fun SettingsView(
    modifier: Modifier = Modifier,
    onBack: () -> Unit,
) {
    Column(modifier.fillMaxSize().background(KinColors.background)) {
        KinNavigationBar("Settings", showBackButton = true, onBack = onBack)

        Column(
            verticalArrangement = Arrangement.spacedBy(KinSpacing.xLarge),
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(KinSpacing.xLarge),
        ) {
            Column(
                verticalArrangement = Arrangement.spacedBy(KinSpacing.medium),
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(KinRadius.mediumShape)
                    .background(KinColors.surface)
                    .padding(KinSpacing.large),
            ) {
                Text("Appearance", style = KinTypography.title, color = KinColors.primaryText)
                Text(
                    "Choose how Kin Kitchen appears on this device.",
                    style = KinTypography.caption,
                    color = KinColors.secondaryText,
                )

                // iOS uses a segmented Picker bound to the stored mode.
                Row(
                    horizontalArrangement = Arrangement.spacedBy(KinSpacing.small),
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    AppearanceOption(
                        label = "Light",
                        icon = Icons.Filled.LightMode,
                        selected = AppearanceStore.mode == AppearanceMode.LIGHT,
                        modifier = Modifier.weight(1f),
                    ) { AppearanceStore.select(AppearanceMode.LIGHT) }

                    AppearanceOption(
                        label = "Dark",
                        icon = Icons.Filled.DarkMode,
                        selected = AppearanceStore.mode == AppearanceMode.DARK,
                        modifier = Modifier.weight(1f),
                    ) { AppearanceStore.select(AppearanceMode.DARK) }
                }
            }
        }
    }
}

@Composable
private fun AppearanceOption(
    label: String,
    icon: ImageVector,
    selected: Boolean,
    modifier: Modifier = Modifier,
    onSelect: () -> Unit,
) {
    val content = if (selected) KinColors.background else KinColors.primaryText

    Row(
        horizontalArrangement = Arrangement.spacedBy(KinSpacing.small, Alignment.CenterHorizontally),
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .clip(KinRadius.smallShape)
            .background(if (selected) KinColors.primary else KinColors.background)
            .selectable(selected = selected, role = Role.RadioButton, onClick = onSelect)
            .padding(vertical = KinSpacing.medium),
    ) {
        Icon(icon, contentDescription = null, tint = content, modifier = Modifier.size(18.dp))
        Text(label, style = KinTypography.subheadline, color = content)
    }
}
