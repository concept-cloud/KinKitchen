package com.pushtomaindev.kinkitchen.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.unit.dp

/** Mirrors iOS `KinRadius`. */
object KinRadius {
    val small = 8.dp
    val medium = 12.dp
    val large = 16.dp
    val xLarge = 24.dp
    val pill = 999.dp

    val smallShape = RoundedCornerShape(small)
    val mediumShape = RoundedCornerShape(medium)
    val largeShape = RoundedCornerShape(large)
    val xLargeShape = RoundedCornerShape(xLarge)
    val pillShape = RoundedCornerShape(pill)
}
