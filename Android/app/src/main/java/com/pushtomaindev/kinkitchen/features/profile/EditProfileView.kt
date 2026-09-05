package com.pushtomaindev.kinkitchen.features.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pushtomaindev.kinkitchen.components.buttons.KinPrimaryButton
import com.pushtomaindev.kinkitchen.components.buttons.KinSecondaryButton
import com.pushtomaindev.kinkitchen.components.feedback.KinLoadingView
import com.pushtomaindev.kinkitchen.components.inputs.KinTextEditor
import com.pushtomaindev.kinkitchen.components.inputs.KinTextField
import com.pushtomaindev.kinkitchen.services.supabase.ProfileService
import com.pushtomaindev.kinkitchen.ui.theme.*
import kotlinx.coroutines.launch
import kotlinx.datetime.*

private const val MIN_AGE = 13
private const val MAX_AGE = 120

/** Mirrors iOS `EditProfileView`. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditProfileView(
    modifier: Modifier = Modifier,
    onDismiss: () -> Unit,
) {
    val scope = rememberCoroutineScope()
    val today = remember { Clock.System.todayIn(TimeZone.currentSystemDefault()) }

    // iOS constrains the picker to (today - 120y)...(today - 13y), so the age
    // rule is enforced by the picker rather than by a save-time check.
    val oldestAllowed = remember(today) { today.minus(MAX_AGE, DateTimeUnit.YEAR) }
    val youngestAllowed = remember(today) { today.minus(MIN_AGE, DateTimeUnit.YEAR) }

    var firstName by rememberSaveable { mutableStateOf("") }
    var lastName by rememberSaveable { mutableStateOf("") }
    var displayName by rememberSaveable { mutableStateOf("") }
    var username by rememberSaveable { mutableStateOf("") }
    var location by rememberSaveable { mutableStateOf("") }
    var bio by rememberSaveable { mutableStateOf("") }
    var birthDate by remember { mutableStateOf(youngestAllowed) }

    var errorMessage by remember { mutableStateOf<String?>(null) }
    var isLoading by remember { mutableStateOf(true) }
    var isSaving by remember { mutableStateOf(false) }
    var isShowingDatePicker by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        isLoading = true
        errorMessage = null
        try {
            val profile = ProfileService.fetchCurrentProfile()
            firstName = profile.firstName.orEmpty()
            lastName = profile.lastName.orEmpty()
            displayName = profile.displayName.orEmpty()
            username = profile.username.orEmpty()
            location = profile.location.orEmpty()
            bio = profile.bio.orEmpty()
            ProfileService.birthDate(profile.birthDate)?.let { birthDate = it }
        } catch (e: Exception) {
            errorMessage = "Unable to load your profile."
        } finally {
            isLoading = false
        }
    }

    fun saveProfile() {
        if (isSaving) return

        val cleanFirstName = firstName.trim()
        val cleanLastName = lastName.trim()
        val cleanDisplayName = displayName.trim()
        val cleanUsername = username.trim()

        errorMessage = when {
            cleanFirstName.isEmpty() -> "First name is required."
            cleanLastName.isEmpty() -> "Last name is required."
            cleanDisplayName.isEmpty() -> "Display name is required."
            cleanUsername.isEmpty() -> "Username is required."
            else -> null
        }
        if (errorMessage != null) return

        scope.launch {
            isSaving = true
            try {
                ProfileService.updateProfile(
                    firstName = cleanFirstName,
                    lastName = cleanLastName,
                    displayName = cleanDisplayName,
                    username = cleanUsername,
                    location = location,
                    birthDate = birthDate,
                    bio = bio,
                )
                onDismiss()
            } catch (e: Exception) {
                errorMessage = "Unable to save your profile."
            } finally {
                isSaving = false
            }
        }
    }

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(KinSpacing.xLarge),
        modifier = modifier
            .fillMaxSize()
            .background(KinColors.background)
            .verticalScroll(rememberScrollState())
            .padding(KinSpacing.xLarge),
    ) {
        Text("Edit Profile", style = KinTypography.largeTitle, color = KinColors.primaryText)

        if (isLoading) {
            Box(Modifier.fillMaxWidth().height(200.dp)) { KinLoadingView() }
        } else {
            Column(verticalArrangement = Arrangement.spacedBy(KinSpacing.large)) {
                KinTextField("First Name", firstName, { firstName = it })
                KinTextField("Last Name", lastName, { lastName = it })
                KinTextField("Display Name", displayName, { displayName = it })
                KinTextField("Username", username, { username = it })
                KinTextField("Location", location, { location = it })

                Column(verticalArrangement = Arrangement.spacedBy(KinSpacing.small)) {
                    Text("Birthday", style = KinTypography.body, color = KinColors.primaryText)
                    KinSecondaryButton(birthDate.longDisplayDate()) { isShowingDatePicker = true }
                }

                Column(verticalArrangement = Arrangement.spacedBy(KinSpacing.small)) {
                    Text("Bio", style = KinTypography.body, color = KinColors.primaryText)
                    KinTextEditor(bio, { bio = it })
                }
            }

            errorMessage?.let {
                Text(it, style = KinTypography.caption, color = KinColors.error)
            }

            KinPrimaryButton(
                title = if (isSaving) "Saving..." else "Save",
                color = KinColors.success,
                enabled = !isSaving,
            ) { saveProfile() }

            KinSecondaryButton("Cancel") { onDismiss() }
        }
    }

    if (isShowingDatePicker) {
        val state = rememberDatePickerState(
            initialSelectedDateMillis = birthDate.atStartOfDayIn(TimeZone.UTC).toEpochMilliseconds(),
            selectableDates = object : SelectableDates {
                override fun isSelectableDate(utcTimeMillis: Long): Boolean {
                    val date = Instant.fromEpochMilliseconds(utcTimeMillis)
                        .toLocalDateTime(TimeZone.UTC).date
                    return date in oldestAllowed..youngestAllowed
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

/** Matches iOS `.formatted(date: .long, time: .omitted)`. */
internal fun LocalDate.longDisplayDate(): String {
    val month = month.name.lowercase().replaceFirstChar { it.uppercase() }
    return "$month $dayOfMonth, $year"
}
