package com.pushtomaindev.kinkitchen.components.navigation

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import com.pushtomaindev.kinkitchen.ui.theme.*

/**
 * Mirrors iOS `KinSectionHeader` (declared in KinSelectionHeader.swift —
 * the Swift filename does not match its type).
 */
@Composable
fun KinSectionHeader(
    title: String,
    modifier: Modifier = Modifier,
    actionTitle: String? = null,
    onAction: (() -> Unit)? = null,
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier.fillMaxWidth(),
    ) {
        Text(title, style = KinTypography.sectionTitle, color = KinColors.primaryText)

        Spacer(Modifier.weight(1f))

        if (actionTitle != null && onAction != null) {
            Text(
                text = actionTitle,
                style = KinTypography.subheadline,
                color = KinColors.primary,
                modifier = Modifier.clickable(role = Role.Button, onClick = onAction),
            )
        }
    }
}
