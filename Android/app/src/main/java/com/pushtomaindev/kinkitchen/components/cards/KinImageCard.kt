package com.pushtomaindev.kinkitchen.components.cards

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import com.pushtomaindev.kinkitchen.ui.theme.*

/** Mirrors iOS `KinImageCard`. */
@Composable
fun KinImageCard(
    painter: Painter,
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    contentDescription: String? = null,
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(KinSpacing.medium),
        modifier = modifier
            .clip(KinRadius.largeShape)
            .background(KinColors.surface)
            .padding(KinSpacing.large),
    ) {
        Image(
            painter = painter,
            contentDescription = contentDescription,
            contentScale = ContentScale.Crop,
            modifier = Modifier
                .fillMaxWidth()
                .height(160.dp)
                .clip(KinRadius.mediumShape),
        )

        Text(title, style = KinTypography.title3, color = KinColors.primaryText)

        if (subtitle != null) {
            Text(subtitle, style = KinTypography.subheadline, color = KinColors.secondaryText)
        }
    }
}
