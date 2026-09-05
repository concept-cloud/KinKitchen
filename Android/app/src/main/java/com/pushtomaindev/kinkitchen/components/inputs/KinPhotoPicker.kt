package com.pushtomaindev.kinkitchen.components.inputs

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import com.pushtomaindev.kinkitchen.ui.theme.*

/**
 * Mirrors iOS `KinPhotoPicker`. Uses Android's system photo picker, the
 * closest analogue to `PhotosPicker`: it needs no storage permission and
 * exposes only the images the user explicitly selects.
 */
@Composable
fun KinPhotoPicker(
    onPhotoSelected: (Uri?) -> Unit,
    modifier: Modifier = Modifier,
    title: String = "Choose Photo",
) {
    val launcher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia(),
        onResult = onPhotoSelected,
    )

    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(KinSpacing.small),
        modifier = modifier.clickable(role = Role.Button) {
            launcher.launch(
                PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
            )
        },
    ) {
        Icon(KinIcons.photo, contentDescription = null, tint = KinColors.primary)
        Text(title, style = KinTypography.button, color = KinColors.primary)
    }
}
