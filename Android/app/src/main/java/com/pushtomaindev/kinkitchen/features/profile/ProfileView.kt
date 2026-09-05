package com.pushtomaindev.kinkitchen.features.profile

import android.graphics.BitmapFactory
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.LibraryBooks
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.compose.ui.unit.sp
import com.pushtomaindev.kinkitchen.models.user.Profile
import com.pushtomaindev.kinkitchen.services.supabase.AuthService
import com.pushtomaindev.kinkitchen.services.supabase.ProfileService
import com.pushtomaindev.kinkitchen.ui.theme.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** Destinations pushed from the profile screen. */
private enum class ProfileRoute { PROFILE, DIETARY, SETTINGS }

/** Mirrors iOS `ProfileView`. */
@Composable
fun ProfileView(
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    var profile by remember { mutableStateOf<Profile?>(null) }
    var profilePhotoData by remember { mutableStateOf<ByteArray?>(null) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var isLoading by remember { mutableStateOf(true) }
    var hasLoadedProfile by rememberSaveable { mutableStateOf(false) }
    var isEditingProfile by remember { mutableStateOf(false) }
    // iOS pushes these inside the tab's NavigationStack, so the tab bar stays
    // visible — unlike Edit Profile, which is presented as a sheet.
    var route by remember { mutableStateOf(ProfileRoute.PROFILE) }

    suspend fun loadProfile() {
        isLoading = true
        errorMessage = null
        try {
            val loaded = ProfileService.fetchCurrentProfile()
            profile = loaded
            profilePhotoData = loaded.profilePhotoPath?.let { path ->
                runCatching { ProfileService.fetchProfilePhoto(path) }.getOrNull()
            }
        } catch (e: Exception) {
            errorMessage = "Unable to load your profile."
        } finally {
            isLoading = false
        }
    }

    // iOS guards on hasLoadedProfile so returning to the tab does not refetch.
    LaunchedEffect(Unit) {
        if (!hasLoadedProfile) {
            loadProfile()
            hasLoadedProfile = true
        } else {
            isLoading = false
        }
    }

    val photoPicker = rememberLauncherForActivityResult(
        ActivityResultContracts.PickVisualMedia()
    ) { uri ->
        if (uri == null) return@rememberLauncherForActivityResult
        scope.launch {
            val bytes = withContext(Dispatchers.IO) {
                runCatching {
                    context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
                }.getOrNull()
            }
            if (bytes == null) {
                errorMessage = "Unable to load the selected photo."
                return@launch
            }
            try {
                ProfileService.uploadProfilePhoto(bytes)
                loadProfile()
            } catch (e: Exception) {
                errorMessage = "Unable to upload profile photo."
            }
        }
    }

    if (route != ProfileRoute.PROFILE) {
        when (route) {
            ProfileRoute.DIETARY -> DietaryProfileView(modifier) { route = ProfileRoute.PROFILE }
            ProfileRoute.SETTINGS -> SettingsView(modifier) { route = ProfileRoute.PROFILE }
            ProfileRoute.PROFILE -> Unit
        }
        return
    }

    Box(modifier.fillMaxSize().background(KinColors.background)) {
        if (isLoading) {
            CircularProgressIndicator(
                color = KinColors.primary,
                modifier = Modifier.align(Alignment.Center),
            )
        } else {
            Column(
                verticalArrangement = Arrangement.spacedBy(KinSpacing.xLarge),
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(KinSpacing.xLarge),
            ) {
                ProfileHeader(
                    profile = profile,
                    photoData = profilePhotoData,
                    onPickPhoto = {
                        photoPicker.launch(
                            PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                        )
                    },
                    onEdit = { isEditingProfile = true },
                )

                profile?.bio?.trim()?.takeIf { it.isNotEmpty() }?.let { bio ->
                    Column(verticalArrangement = Arrangement.spacedBy(KinSpacing.small)) {
                        Text("About", style = KinTypography.title, color = KinColors.primaryText)
                        Text(bio, style = KinTypography.body, color = KinColors.secondaryText)
                    }
                }

                errorMessage?.let {
                    Text(it, style = KinTypography.caption, color = KinColors.error)
                }

                Column(verticalArrangement = Arrangement.spacedBy(KinSpacing.small)) {
                    NavigationRow("Dietary Profile", KinIcons.recipes) { route = ProfileRoute.DIETARY }
                    PlaceholderRow("My Recipes", Icons.AutoMirrored.Filled.MenuBook)
                    PlaceholderRow("My Cookbooks", Icons.Filled.LibraryBooks)
                    PlaceholderRow("Saved Recipes", KinIcons.save)
                    NavigationRow("Settings", KinIcons.settings) { route = ProfileRoute.SETTINGS }
                    PlaceholderRow("App Info", KinIcons.info)
                }

                Spacer(Modifier.height(KinSpacing.small))

                SignOutRow {
                    scope.launch {
                        runCatching { AuthService.signOut() }
                            .onFailure { errorMessage = "Unable to sign out. Please try again." }
                    }
                }
            }
        }

        if (isEditingProfile) {
            val dismissEdit = {
                isEditingProfile = false
                // iOS reloads the profile when the edit sheet closes.
                scope.launch { loadProfile() }
                Unit
            }

            // iOS presents this with .sheet, which covers the tab bar too. A
            // plain overlay would sit inside the tab content and leave Cancel
            // trapped behind the tab bar, so use a full-screen dialog — which
            // also wires up the system back gesture.
            Dialog(
                onDismissRequest = dismissEdit,
                properties = DialogProperties(usePlatformDefaultWidth = false),
            ) {
                EditProfileView(
                    modifier = Modifier.fillMaxSize().background(KinColors.background).systemBarsPadding(),
                    onDismiss = dismissEdit,
                )
            }
        }
    }
}

@Composable
private fun ProfileHeader(
    profile: Profile?,
    photoData: ByteArray?,
    onPickPhoto: () -> Unit,
    onEdit: () -> Unit,
) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(KinSpacing.large),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Box(contentAlignment = Alignment.BottomEnd) {
            val bitmap = remember(photoData) {
                photoData?.let { BitmapFactory.decodeByteArray(it, 0, it.size) }
            }

            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .size(120.dp)
                    .clip(CircleShape)
                    .background(KinColors.surface)
                    .clickable(role = Role.Button, onClick = onPickPhoto),
            ) {
                if (bitmap != null) {
                    Image(
                        bitmap = bitmap.asImageBitmap(),
                        contentDescription = "Profile photo",
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.size(120.dp).clip(CircleShape),
                    )
                } else {
                    Icon(
                        KinIcons.profile,
                        contentDescription = null,
                        tint = KinColors.secondaryText,
                        modifier = Modifier.size(48.dp),
                    )
                }
            }

            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .size(30.dp)
                    .clip(CircleShape)
                    .background(KinColors.primary)
                    .clickable(role = Role.Button, onClick = onPickPhoto),
            ) {
                Icon(
                    KinIcons.camera,
                    contentDescription = "Change photo",
                    tint = KinColors.background,
                    modifier = Modifier.size(14.dp),
                )
            }
        }

        Column(
            verticalArrangement = Arrangement.spacedBy(KinSpacing.medium),
            modifier = Modifier.weight(1f).heightIn(min = 120.dp),
        ) {
            BasicText(
                text = displayNameOf(profile),
                style = KinTypography.largeTitle.copy(color = KinColors.primaryText),
                maxLines = 1,
                // Mirrors iOS .minimumScaleFactor(0.7): shrink to fit, don't clip.
                autoSize = TextAutoSize.StepBased(
                    minFontSize = 24.sp,
                    maxFontSize = 34.sp,
                    stepSize = 1.sp,
                ),
                modifier = Modifier.fillMaxWidth(),
            )

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(KinSpacing.medium),
            ) {
                Text(
                    profile?.username?.trim()?.takeIf { it.isNotEmpty() }?.let { "@$it" }.orEmpty(),
                    style = KinTypography.body,
                    color = KinColors.secondaryText,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f),
                )

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(KinSpacing.small),
                    modifier = Modifier.clickable(role = Role.Button, onClick = onEdit),
                ) {
                    Icon(
                        KinIcons.edit,
                        contentDescription = null,
                        tint = KinColors.primary,
                        modifier = Modifier.size(14.dp),
                    )
                    Text("Edit", style = KinTypography.caption, color = KinColors.primary)
                }
            }

            profile?.location?.trim()?.takeIf { it.isNotEmpty() }?.let {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(KinSpacing.small),
                ) {
                    Icon(
                        KinIcons.location,
                        contentDescription = null,
                        tint = KinColors.secondaryText,
                        modifier = Modifier.size(14.dp),
                    )
                    Text(
                        it,
                        style = KinTypography.caption,
                        color = KinColors.secondaryText,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
            }
        }
    }
}

@Composable
private fun RowShell(content: @Composable RowScope.() -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(KinSpacing.medium),
        modifier = Modifier
            .fillMaxWidth()
            .clip(KinRadius.mediumShape)
            .background(KinColors.surface)
            .padding(KinSpacing.medium),
        content = content,
    )
}

@Composable
private fun NavigationRow(title: String, icon: ImageVector, onClick: () -> Unit) {
    Box(Modifier.clip(KinRadius.mediumShape).clickable(role = Role.Button, onClick = onClick)) {
        RowShell {
            Icon(icon, contentDescription = null, tint = KinColors.primary, modifier = Modifier.width(24.dp))
            Text(title, style = KinTypography.body, color = KinColors.primaryText)
            Spacer(Modifier.weight(1f))
            Icon(
                KinIcons.forward,
                contentDescription = null,
                tint = KinColors.secondaryText,
                modifier = Modifier.size(16.dp),
            )
        }
    }
}

@Composable
private fun PlaceholderRow(title: String, icon: ImageVector) {
    RowShell {
        Icon(icon, contentDescription = null, tint = KinColors.primary, modifier = Modifier.width(24.dp))
        Text(title, style = KinTypography.body, color = KinColors.primaryText)
        Spacer(Modifier.weight(1f))
        Text("Coming Soon", style = KinTypography.caption, color = KinColors.secondaryText)
    }
}

@Composable
private fun SignOutRow(onClick: () -> Unit) {
    Box(Modifier.clip(KinRadius.mediumShape).clickable(role = Role.Button, onClick = onClick)) {
        RowShell {
            Icon(Icons.AutoMirrored.Filled.Logout, contentDescription = null, tint = KinColors.error)
            Text("Sign Out", style = KinTypography.body, color = KinColors.error)
            Spacer(Modifier.weight(1f))
        }
    }
}

/** Mirrors iOS `displayName`. */
internal fun displayNameOf(profile: Profile?): String {
    val stored = profile?.displayName?.trim().orEmpty()
    if (stored.isNotEmpty()) return stored

    val full = listOfNotNull(
        profile?.firstName?.trim()?.takeIf { it.isNotEmpty() },
        profile?.lastName?.trim()?.takeIf { it.isNotEmpty() },
    ).joinToString(" ")

    return full.ifEmpty { "Your Profile" }
}
