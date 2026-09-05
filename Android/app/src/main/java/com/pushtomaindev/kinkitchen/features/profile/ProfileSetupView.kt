package com.pushtomaindev.kinkitchen.features.profile

import android.content.Context
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.pushtomaindev.kinkitchen.components.buttons.KinPrimaryButton
import com.pushtomaindev.kinkitchen.components.inputs.KinPhotoPicker
import com.pushtomaindev.kinkitchen.components.inputs.KinTextEditor
import com.pushtomaindev.kinkitchen.components.inputs.KinTextField
import com.pushtomaindev.kinkitchen.services.supabase.ProfileService
import com.pushtomaindev.kinkitchen.services.supabase.UsernameAvailability
import com.pushtomaindev.kinkitchen.ui.theme.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.datetime.*

/** Mirrors iOS `ProfileSetupView.ProfileSetupMode`. */
private enum class ProfileSetupMode { CREATE, UPDATE }

/** Mirrors iOS `ProfileSetupView.ProfileFormField`. */
private enum class ProfileFormField { FIRST_NAME, LAST_NAME, USERNAME }

private const val MIN_AGE = 13
private const val MAX_AGE = 120
private const val DEFAULT_AGE = 18
private const val USERNAME_MIN_LENGTH = 3
private const val USERNAME_DEBOUNCE_MS = 500L

/** Mirrors iOS `ProfileSetupView`. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileSetupView(
    modifier: Modifier = Modifier,
    onProfileCompleted: () -> Unit,
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val today = remember { Clock.System.todayIn(TimeZone.currentSystemDefault()) }

    var mode by remember { mutableStateOf(ProfileSetupMode.CREATE) }

    var firstName by rememberSaveable { mutableStateOf("") }
    var lastName by rememberSaveable { mutableStateOf("") }
    var username by rememberSaveable { mutableStateOf("") }
    var location by rememberSaveable { mutableStateOf("") }
    var bio by rememberSaveable { mutableStateOf("") }
    var birthDate by remember { mutableStateOf(today.minus(DEFAULT_AGE, DateTimeUnit.YEAR)) }

    // Tracks which required fields already existed in Supabase; existing
    // values are shown read-only during profile completion.
    var hadExistingFirstName by remember { mutableStateOf(false) }
    var hadExistingLastName by remember { mutableStateOf(false) }
    var hadExistingUsername by remember { mutableStateOf(false) }
    var hasExistingBirthDate by remember { mutableStateOf(false) }

    var profilePhotoData by remember { mutableStateOf<ByteArray?>(null) }
    var usernameAvailability by remember { mutableStateOf(UsernameAvailability.UNKNOWN) }

    var errorMessage by remember { mutableStateOf<String?>(null) }
    var isShowingErrorAlert by remember { mutableStateOf(false) }
    var isShowingParentPermissionAlert by remember { mutableStateOf(false) }
    var isShowingDatePicker by remember { mutableStateOf(false) }
    var isSaving by remember { mutableStateOf(false) }
    var fieldToFocus by remember { mutableStateOf<ProfileFormField?>(null) }

    val firstNameFocus = remember { FocusRequester() }
    val lastNameFocus = remember { FocusRequester() }
    val usernameFocus = remember { FocusRequester() }

    // iOS: .task { await loadExistingProfile() }
    LaunchedEffect(Unit) {
        runCatching { ProfileService.fetchCurrentProfile() }
            .onSuccess { profile ->
                val f = profile.firstName?.trim().orEmpty()
                val l = profile.lastName?.trim().orEmpty()
                val u = profile.username?.trim().orEmpty()
                val d = profile.displayName?.trim().orEmpty()
                val loc = profile.location?.trim().orEmpty()
                val b = profile.bio?.trim().orEmpty()
                val existingBirthDate = ProfileService.birthDate(profile.birthDate)

                val hasExistingProfileData = f.isNotEmpty() || l.isNotEmpty() ||
                    u.isNotEmpty() || d.isNotEmpty() || loc.isNotEmpty() || b.isNotEmpty() ||
                    existingBirthDate != null || profile.profilePhotoPath != null

                mode = if (hasExistingProfileData) ProfileSetupMode.UPDATE else ProfileSetupMode.CREATE
                firstName = f
                lastName = l
                username = u
                location = loc
                bio = b
                hadExistingFirstName = f.isNotEmpty()
                hadExistingLastName = l.isNotEmpty()
                hadExistingUsername = u.isNotEmpty()

                if (existingBirthDate != null) {
                    birthDate = existingBirthDate
                    hasExistingBirthDate = true
                } else {
                    hasExistingBirthDate = false
                }
            }
            .onFailure { mode = ProfileSetupMode.CREATE }
    }

    // iOS: .task(id: username). Re-keying cancels the previous run, so the
    // delay below debounces exactly as the Swift version does.
    LaunchedEffect(username, mode, hadExistingUsername) {
        usernameAvailability = UsernameAvailability.UNKNOWN
        val clean = username.trim()

        if (mode == ProfileSetupMode.UPDATE && hadExistingUsername) return@LaunchedEffect
        if (clean.length < USERNAME_MIN_LENGTH) return@LaunchedEffect

        delay(USERNAME_DEBOUNCE_MS)
        usernameAvailability = UsernameAvailability.CHECKING

        runCatching { ProfileService.isUsernameAvailable(clean) }
            .onSuccess {
                usernameAvailability =
                    if (it) UsernameAvailability.AVAILABLE else UsernameAvailability.TAKEN
            }
            .onFailure { usernameAvailability = UsernameAvailability.UNKNOWN }
    }

    fun completeProfile() {
        if (isSaving) return
        errorMessage = null

        val cleanFirstName = firstName.trim()
        val cleanLastName = lastName.trim()
        val cleanUsername = username.trim()

        fun fail(message: String, focus: ProfileFormField) {
            errorMessage = message
            fieldToFocus = focus
            isShowingErrorAlert = true
        }

        if (cleanFirstName.isEmpty()) return fail("First name is required.", ProfileFormField.FIRST_NAME)
        if (cleanLastName.isEmpty()) return fail("Last name is required.", ProfileFormField.LAST_NAME)
        if (cleanUsername.isEmpty()) return fail("Username is required.", ProfileFormField.USERNAME)

        // Existing users keep their current username; only new or missing
        // usernames need an availability check.
        if (mode == ProfileSetupMode.CREATE || !hadExistingUsername) {
            if (cleanUsername.length < USERNAME_MIN_LENGTH) {
                return fail("Username must be at least 3 characters.", ProfileFormField.USERNAME)
            }
            if (usernameAvailability != UsernameAvailability.AVAILABLE) {
                return fail(
                    if (usernameAvailability == UsernameAvailability.TAKEN) {
                        "That username is already taken. Please choose another."
                    } else {
                        "Please wait for the username availability check to complete."
                    },
                    ProfileFormField.USERNAME,
                )
            }
        }

        if (!isAtLeast13(birthDate, today)) {
            isShowingParentPermissionAlert = true
            return
        }

        scope.launch {
            isSaving = true
            try {
                ProfileService.completeInitialProfile(
                    firstName = cleanFirstName,
                    lastName = cleanLastName,
                    username = cleanUsername,
                    location = location,
                    birthDate = birthDate,
                    bio = bio,
                )
                profilePhotoData?.let { ProfileService.uploadProfilePhoto(it) }
                onProfileCompleted()
            } catch (e: Exception) {
                errorMessage = "Unable to complete your profile. Please try again."
                isShowingErrorAlert = true
            } finally {
                isSaving = false
            }
        }
    }

    Column(
        verticalArrangement = Arrangement.spacedBy(KinSpacing.xLarge),
        modifier = modifier
            .fillMaxSize()
            .background(KinColors.background)
            .verticalScroll(rememberScrollState())
            .padding(KinSpacing.xLarge),
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(KinSpacing.small)) {
            Text(
                if (mode == ProfileSetupMode.CREATE) "Create Your Profile" else "Update Your Profile",
                style = KinTypography.largeTitle,
                color = KinColors.primaryText,
                maxLines = 1,
            )
            Text(
                if (mode == ProfileSetupMode.CREATE) {
                    "Tell us a little about yourself."
                } else {
                    "We need a little more information to complete your profile."
                },
                style = KinTypography.body,
                color = KinColors.secondaryText,
            )
        }

        if (mode == ProfileSetupMode.CREATE) {
            ProfilePhotoSection(
                photoData = profilePhotoData,
                onPhotoSelected = { uri ->
                    if (uri == null) return@ProfilePhotoSection
                    scope.launch {
                        val bytes = readBytes(context, uri)
                        if (bytes == null) {
                            errorMessage = "Unable to load the selected photo."
                            isShowingErrorAlert = true
                        } else {
                            profilePhotoData = bytes
                        }
                    }
                },
            )
        }

        Column(verticalArrangement = Arrangement.spacedBy(KinSpacing.large)) {
            if (mode == ProfileSetupMode.UPDATE && hadExistingFirstName) {
                ProfileValueRow("First Name", firstName)
            } else {
                LabeledField("First Name") {
                    KinTextField(
                        "Enter First Name", firstName, { firstName = it },
                        modifier = Modifier.focusRequester(firstNameFocus),
                    )
                }
            }

            if (mode == ProfileSetupMode.UPDATE && hadExistingLastName) {
                ProfileValueRow("Last Name", lastName)
            } else {
                LabeledField("Last Name") {
                    KinTextField(
                        "Enter Last Name", lastName, { lastName = it },
                        modifier = Modifier.focusRequester(lastNameFocus),
                    )
                }
            }

            if (mode == ProfileSetupMode.UPDATE && hadExistingUsername) {
                ProfileValueRow("Username", "@$username")
            } else {
                LabeledField("Username") {
                    KinTextField(
                        "Choose Username", username, { username = it },
                        modifier = Modifier.focusRequester(usernameFocus),
                    )
                    UsernameAvailabilityRow(usernameAvailability)
                }
            }

            if (mode == ProfileSetupMode.UPDATE && hasExistingBirthDate) {
                ProfileValueRow("Birthday", birthDate.longDisplayDate())
            } else {
                BirthdaySection(birthDate) { isShowingDatePicker = true }
            }

            if (mode == ProfileSetupMode.CREATE) {
                KinTextField("City, State", location, { location = it })

                Column(verticalArrangement = Arrangement.spacedBy(KinSpacing.small)) {
                    Text("Quick Bio", style = KinTypography.body, color = KinColors.primaryText)
                    KinTextEditor(bio, { bio = it })
                    Text("Optional", style = KinTypography.caption, color = KinColors.secondaryText)
                }
            } else {
                if (location.trim().isNotEmpty()) ProfileValueRow("City, State", location)
                if (bio.trim().isNotEmpty()) ProfileValueRow("Quick Bio", bio)

                Text(
                    "You can change your profile photo, location, bio, and other profile " +
                        "information later from Edit Profile.",
                    style = KinTypography.caption,
                    color = KinColors.secondaryText,
                )
            }
        }

        errorMessage?.let {
            Text(it, style = KinTypography.caption, color = KinColors.error)
        }

        KinPrimaryButton(
            title = when {
                isSaving && mode == ProfileSetupMode.CREATE -> "Creating Profile..."
                isSaving -> "Updating Profile..."
                else -> "Continue"
            },
            color = KinColors.success,
            enabled = !isSaving,
        ) { completeProfile() }
    }

    if (isShowingParentPermissionAlert) {
        AlertDialog(
            onDismissRequest = { isShowingParentPermissionAlert = false },
            title = { Text("Parent Permission Required", style = KinTypography.title3) },
            text = {
                Text(
                    "Kin Kitchen requires a parent or guardian to create and manage " +
                        "accounts for children under 13.",
                    style = KinTypography.body,
                )
            },
            confirmButton = {
                TextButton(onClick = { isShowingParentPermissionAlert = false }) { Text("OK") }
            },
            containerColor = KinColors.surface,
        )
    }

    if (isShowingErrorAlert) {
        AlertDialog(
            onDismissRequest = { isShowingErrorAlert = false },
            title = { Text("Profile Setup", style = KinTypography.title3) },
            text = { Text(errorMessage.orEmpty(), style = KinTypography.body) },
            confirmButton = {
                TextButton(onClick = {
                    isShowingErrorAlert = false
                    when (fieldToFocus) {
                        ProfileFormField.FIRST_NAME -> firstNameFocus.requestFocus()
                        ProfileFormField.LAST_NAME -> lastNameFocus.requestFocus()
                        ProfileFormField.USERNAME -> usernameFocus.requestFocus()
                        null -> Unit
                    }
                    fieldToFocus = null
                }) { Text("OK") }
            },
            containerColor = KinColors.surface,
        )
    }

    if (isShowingDatePicker) {
        val zone = TimeZone.currentSystemDefault()
        val state = rememberDatePickerState(
            initialSelectedDateMillis = birthDate.atStartOfDayIn(TimeZone.UTC).toEpochMilliseconds(),
            selectableDates = object : SelectableDates {
                // iOS constrains the picker to (today - 120 years)...today.
                override fun isSelectableDate(utcTimeMillis: Long): Boolean {
                    val date = Instant.fromEpochMilliseconds(utcTimeMillis)
                        .toLocalDateTime(TimeZone.UTC).date
                    return date <= today && date >= today.minus(MAX_AGE, DateTimeUnit.YEAR)
                }
            },
        )

        DatePickerDialog(
            onDismissRequest = { isShowingDatePicker = false },
            confirmButton = {
                TextButton(onClick = {
                    state.selectedDateMillis?.let {
                        birthDate = Instant.fromEpochMilliseconds(it)
                            .toLocalDateTime(TimeZone.UTC).date
                    }
                    isShowingDatePicker = false
                }) { Text("OK") }
            },
            dismissButton = {
                TextButton(onClick = { isShowingDatePicker = false }) { Text("Cancel") }
            },
        ) { DatePicker(state = state) }
    }
}

@Composable
private fun LabeledField(title: String, content: @Composable ColumnScope.() -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(KinSpacing.small)) {
        Text(title, style = KinTypography.caption, color = KinColors.secondaryText)
        content()
    }
}

/** Mirrors iOS `profileValueRow` — a completed field shown read-only. */
@Composable
private fun ProfileValueRow(title: String, value: String) {
    Column(verticalArrangement = Arrangement.spacedBy(KinSpacing.small)) {
        Text(title, style = KinTypography.caption, color = KinColors.secondaryText)
        Text(value, style = KinTypography.body, color = KinColors.primaryText)
    }
}

@Composable
private fun ProfilePhotoSection(photoData: ByteArray?, onPhotoSelected: (Uri?) -> Unit) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(KinSpacing.large),
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth(),
    ) {
        val bitmap = remember(photoData) {
            photoData?.let { BitmapFactory.decodeByteArray(it, 0, it.size) }
        }

        if (bitmap != null) {
            Image(
                bitmap = bitmap.asImageBitmap(),
                contentDescription = "Profile photo",
                contentScale = ContentScale.Crop,
                modifier = Modifier.size(88.dp).clip(CircleShape),
            )
        } else {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier.size(88.dp).clip(CircleShape).background(KinColors.surface),
            ) {
                Icon(
                    KinIcons.profile,
                    contentDescription = null,
                    tint = KinColors.secondaryText,
                    modifier = Modifier.size(38.dp),
                )
            }
        }

        Column(verticalArrangement = Arrangement.spacedBy(KinSpacing.small)) {
            Text("Profile Photo", style = KinTypography.body, color = KinColors.primaryText)
            KinPhotoPicker(onPhotoSelected = onPhotoSelected)
            Text("Optional", style = KinTypography.caption, color = KinColors.secondaryText)
        }
    }
}

@Composable
private fun BirthdaySection(birthDate: LocalDate, onPick: () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(KinSpacing.small)) {
        Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
            Text("Birthday", style = KinTypography.body, color = KinColors.primaryText)
            Spacer(Modifier.weight(1f))
            TextButton(onClick = onPick) {
                Text(birthDate.longDisplayDate(), style = KinTypography.body, color = KinColors.primary)
            }
        }
        Text(
            "You must be at least 13 years old.",
            style = KinTypography.caption,
            color = KinColors.secondaryText,
        )
    }
}

/** Mirrors iOS `usernameAvailabilityView`. */
@Composable
private fun UsernameAvailabilityRow(availability: UsernameAvailability) {
    when (availability) {
        UsernameAvailability.UNKNOWN -> Unit
        UsernameAvailability.CHECKING -> Text(
            "Checking availability...",
            style = KinTypography.caption,
            color = KinColors.secondaryText,
        )
        UsernameAvailability.AVAILABLE -> IconCaption(
            KinIcons.success, "Username is available", KinColors.success
        )
        UsernameAvailability.TAKEN -> IconCaption(
            KinIcons.error, "Username is already taken", KinColors.error
        )
    }
}

@Composable
private fun IconCaption(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    text: String,
    color: androidx.compose.ui.graphics.Color,
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(KinSpacing.xSmall),
    ) {
        Icon(icon, contentDescription = null, tint = color, modifier = Modifier.size(14.dp))
        Text(text, style = KinTypography.caption, color = color)
    }
}

/** Mirrors iOS `isAtLeast13`. */
private fun isAtLeast13(birthDate: LocalDate, today: LocalDate): Boolean =
    birthDate <= today.minus(MIN_AGE, DateTimeUnit.YEAR)

private suspend fun readBytes(context: Context, uri: Uri): ByteArray? =
    withContext(Dispatchers.IO) {
        runCatching {
            context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
        }.getOrNull()
    }
