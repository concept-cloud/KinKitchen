package com.pushtomaindev.kinkitchen.ui.theme

import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.pushtomaindev.kinkitchen.R

val Arvo = FontFamily(
    Font(R.font.arvo_regular, FontWeight.Normal),
    Font(R.font.arvo_bold, FontWeight.Bold),
)

val Lora = FontFamily(
    Font(R.font.lora_regular, FontWeight.Normal),
    Font(R.font.lora_bold, FontWeight.Bold),
)

/**
 * Mirrors iOS `KinTypography`. iOS point sizes map 1:1 to sp — both are
 * ~1/160 inch at baseline density, and both scale with the user's text size.
 */
object KinTypography {
    private fun arvoBold(size: Int) =
        TextStyle(fontFamily = Arvo, fontWeight = FontWeight.Bold, fontSize = size.sp)

    private fun arvoRegular(size: Int) =
        TextStyle(fontFamily = Arvo, fontWeight = FontWeight.Normal, fontSize = size.sp)

    private fun loraRegular(size: Int) =
        TextStyle(fontFamily = Lora, fontWeight = FontWeight.Normal, fontSize = size.sp)

    val largeTitle = arvoBold(34)
    val title = arvoBold(28)
    val title2 = arvoBold(22)
    val title3 = arvoBold(20)

    val headline = arvoBold(17)
    val subheadline = arvoRegular(15)

    val body = loraRegular(17)
    val callout = loraRegular(16)
    val footnote = loraRegular(13)
    val caption = loraRegular(12)
    val caption2 = loraRegular(11)

    val button = arvoBold(17)
    val navigationTitle = arvoBold(20)
    val sectionTitle = arvoBold(22)
}
