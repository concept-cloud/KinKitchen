package com.pushtomaindev.kinkitchen.components.cards

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import com.pushtomaindev.kinkitchen.ui.theme.KinColors
import com.pushtomaindev.kinkitchen.ui.theme.KinRadius
import com.pushtomaindev.kinkitchen.ui.theme.KinSpacing

/** Mirrors iOS `KinCard`. */
@Composable
fun KinCard(
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(
        modifier = modifier
            .clip(KinRadius.largeShape)
            .background(KinColors.surface)
            .padding(KinSpacing.large),
        content = content,
    )
}
