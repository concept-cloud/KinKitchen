package com.pushtomaindev.kinkitchen.features.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import com.pushtomaindev.kinkitchen.components.feedback.KinLoadingView
import com.pushtomaindev.kinkitchen.components.labels.KinChip
import com.pushtomaindev.kinkitchen.components.labels.KinFlowLayout
import com.pushtomaindev.kinkitchen.components.navigation.KinNavigationBar
import com.pushtomaindev.kinkitchen.services.supabase.DietaryService
import com.pushtomaindev.kinkitchen.services.supabase.ProfileService
import com.pushtomaindev.kinkitchen.ui.theme.*
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.datetime.Instant
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime

/** Mirrors iOS `DietaryProfileView`. */
@Composable
fun DietaryProfileView(
    modifier: Modifier = Modifier,
    onBack: () -> Unit,
) {
    var allergens by remember { mutableStateOf<List<String>>(emptyList()) }
    var restrictions by remember { mutableStateOf<List<String>>(emptyList()) }
    var preferences by remember { mutableStateOf<List<String>>(emptyList()) }
    var lastUpdated by remember { mutableStateOf<Instant?>(null) }

    var isLoading by remember { mutableStateOf(true) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var isEditing by remember { mutableStateOf(false) }
    var reloadToken by remember { mutableIntStateOf(0) }

    // iOS reloads whenever the edit destination is dismissed.
    LaunchedEffect(reloadToken) {
        isLoading = true
        errorMessage = null
        try {
            // iOS fires these concurrently with `async let`.
            coroutineScope {
                val allAllergens = async { DietaryService.fetchAllergens() }
                val allRestrictions = async { DietaryService.fetchDietaryRestrictions() }
                val allPreferences = async { DietaryService.fetchDietaryPreferences() }
                val selectedAllergens = async { DietaryService.fetchSelectedAllergens() }
                val selectedRestrictions = async { DietaryService.fetchSelectedDietaryRestrictions() }
                val selectedPreferences = async { DietaryService.fetchSelectedDietaryPreferences() }
                val updated = async { ProfileService.fetchDietaryLastUpdated() }

                val allergenIds = selectedAllergens.await().toSet()
                val restrictionIds = selectedRestrictions.await().toSet()
                val preferenceIds = selectedPreferences.await().toSet()

                allergens = allAllergens.await().filter { it.id in allergenIds }.map { it.name }
                restrictions = allRestrictions.await().filter { it.id in restrictionIds }.map { it.name }
                preferences = allPreferences.await().filter { it.id in preferenceIds }.map { it.name }
                lastUpdated = updated.await()
            }
        } catch (e: Exception) {
            errorMessage = "Unable to load your dietary profile."
        } finally {
            isLoading = false
        }
    }

    Column(modifier.fillMaxSize().background(KinColors.background)) {
        KinNavigationBar("Dietary Profile", showBackButton = true, onBack = onBack)

        if (isLoading) {
            Box(Modifier.fillMaxSize()) { KinLoadingView() }
        } else {
            Column(
                verticalArrangement = Arrangement.spacedBy(KinSpacing.xLarge),
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(KinSpacing.xLarge),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
                    Text(
                        lastUpdated?.let { "Last updated ${it.abbreviatedDate()}" }
                            ?: "Last updated unavailable",
                        style = KinTypography.subheadline,
                        color = KinColors.primary,
                    )

                    Spacer(Modifier.weight(1f))

                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(KinSpacing.small),
                        modifier = Modifier.clickable(role = Role.Button) { isEditing = true },
                    ) {
                        Icon(
                            KinIcons.edit,
                            contentDescription = null,
                            tint = KinColors.primary,
                            modifier = Modifier.size(16.dp),
                        )
                        Text("Edit", style = KinTypography.subheadline, color = KinColors.primary)
                    }
                }

                DietarySection("Allergens", allergens, "No allergens selected.")
                DietarySection("Dietary Restrictions", restrictions, "No dietary restrictions selected.")
                DietarySection("Dietary Preferences", preferences, "No dietary preferences selected.")

                errorMessage?.let {
                    Text(it, style = KinTypography.body, color = KinColors.error)
                }
            }
        }
    }

    if (isEditing) {
        EditDietaryProfileView(
            modifier = Modifier.fillMaxSize().background(KinColors.background),
            onDismiss = {
                isEditing = false
                reloadToken++
            },
        )
    }
}

/** Mirrors iOS `dietarySection`. */
@Composable
private fun DietarySection(title: String, items: List<String>, emptyMessage: String) {
    Column(
        verticalArrangement = Arrangement.spacedBy(KinSpacing.medium),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Text(title, style = KinTypography.title, color = KinColors.primaryText)

        if (items.isEmpty()) {
            Text(emptyMessage, style = KinTypography.body, color = KinColors.secondaryText)
        } else {
            KinFlowLayout(spacing = KinSpacing.small) {
                items.forEach { KinChip(it, isSelected = true) }
            }
        }
    }
}

/** Matches iOS `.dateTime.month(.abbreviated).day().year()`. */
private fun Instant.abbreviatedDate(): String {
    val d = toLocalDateTime(TimeZone.currentSystemDefault()).date
    val month = d.month.name.lowercase().replaceFirstChar { it.uppercase() }.take(3)
    return "$month ${d.dayOfMonth}, ${d.year}"
}
