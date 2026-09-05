package com.pushtomaindev.kinkitchen.components.labels

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.pushtomaindev.kinkitchen.ui.theme.KinSpacing
import kotlin.math.max

/**
 * Mirrors iOS `KinFlowLayout` — wraps children onto new rows when they no
 * longer fit, matching the Swift measure/place algorithm line for line.
 */
@Composable
fun KinFlowLayout(
    modifier: Modifier = Modifier,
    spacing: Dp = KinSpacing.small,
    content: @Composable () -> Unit,
) {
    Layout(content = content, modifier = modifier) { measurables, constraints ->
        val gap = spacing.roundToPx()
        val maxWidth = constraints.maxWidth

        // Children size themselves freely, but never wider than the container.
        val placeables = measurables.map {
            it.measure(constraints.copy(minWidth = 0, minHeight = 0))
        }

        var width = 0
        var height = 0
        var rowWidth = 0
        var rowHeight = 0

        for (p in placeables) {
            if (rowWidth + p.width > maxWidth && rowWidth > 0) {
                width = max(width, rowWidth)
                height += rowHeight + gap
                rowWidth = 0
                rowHeight = 0
            }
            if (rowWidth > 0) rowWidth += gap
            rowWidth += p.width
            rowHeight = max(rowHeight, p.height)
        }
        width = max(width, rowWidth)
        height += rowHeight

        layout(width.coerceIn(constraints.minWidth, constraints.maxWidth), height) {
            var x = 0
            var y = 0
            var placedRowHeight = 0

            for (p in placeables) {
                if (x + p.width > maxWidth && x > 0) {
                    x = 0
                    y += placedRowHeight + gap
                    placedRowHeight = 0
                }
                p.placeRelative(x, y)
                x += p.width + gap
                placedRowHeight = max(placedRowHeight, p.height)
            }
        }
    }
}
