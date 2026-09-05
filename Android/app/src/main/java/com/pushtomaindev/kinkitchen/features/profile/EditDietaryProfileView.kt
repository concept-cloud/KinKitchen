package com.pushtomaindev.kinkitchen.features.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import com.pushtomaindev.kinkitchen.components.buttons.KinPrimaryButton
import com.pushtomaindev.kinkitchen.components.feedback.KinLoadingView
import com.pushtomaindev.kinkitchen.components.labels.KinChip
import com.pushtomaindev.kinkitchen.components.labels.KinFlowLayout
import com.pushtomaindev.kinkitchen.components.navigation.KinNavigationBar
import com.pushtomaindev.kinkitchen.services.supabase.DietaryService
import com.pushtomaindev.kinkitchen.ui.theme.*
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch

/** One selectable lookup row: id plus display name. */
private data class DietaryItem(val id: String, val name: String)

/** Mirrors iOS `EditDietaryProfileView`. */
@Composable
fun EditDietaryProfileView(
    modifier: Modifier = Modifier,
    onDismiss: () -> Unit,
) {
    val scope = rememberCoroutineScope()

    var allergens by remember { mutableStateOf<List<DietaryItem>>(emptyList()) }
    var restrictions by remember { mutableStateOf<List<DietaryItem>>(emptyList()) }
    var preferences by remember { mutableStateOf<List<DietaryItem>>(emptyList()) }

    var selectedAllergens by remember { mutableStateOf<Set<String>>(emptySet()) }
    var selectedRestrictions by remember { mutableStateOf<Set<String>>(emptySet()) }
    var selectedPreferences by remember { mutableStateOf<Set<String>>(emptySet()) }

    // iOS keeps the loaded selection so saving can diff against it.
    var originalAllergens by remember { mutableStateOf<Set<String>>(emptySet()) }
    var originalRestrictions by remember { mutableStateOf<Set<String>>(emptySet()) }
    var originalPreferences by remember { mutableStateOf<Set<String>>(emptySet()) }

    var isLoading by remember { mutableStateOf(true) }
    var isSaving by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) {
        isLoading = true
        errorMessage = null
        try {
            coroutineScope {
                val a = async { DietaryService.fetchAllergens() }
                val r = async { DietaryService.fetchDietaryRestrictions() }
                val p = async { DietaryService.fetchDietaryPreferences() }
                val sa = async { DietaryService.fetchSelectedAllergens() }
                val sr = async { DietaryService.fetchSelectedDietaryRestrictions() }
                val sp = async { DietaryService.fetchSelectedDietaryPreferences() }

                allergens = a.await().map { DietaryItem(it.id, it.name) }
                restrictions = r.await().map { DietaryItem(it.id, it.name) }
                preferences = p.await().map { DietaryItem(it.id, it.name) }

                selectedAllergens = sa.await().toSet()
                selectedRestrictions = sr.await().toSet()
                selectedPreferences = sp.await().toSet()

                originalAllergens = selectedAllergens
                originalRestrictions = selectedRestrictions
                originalPreferences = selectedPreferences
            }
        } catch (e: Exception) {
            errorMessage = e.message ?: "Unable to load your dietary options."
        } finally {
            isLoading = false
        }
    }

    fun saveChanges() {
        if (isSaving) return
        scope.launch {
            isSaving = true
            errorMessage = null
            try {
                // iOS writes only the difference, so untouched rows are left alone.
                (selectedAllergens - originalAllergens).forEach { DietaryService.addAllergen(it) }
                (originalAllergens - selectedAllergens).forEach { DietaryService.removeAllergen(it) }

                (selectedRestrictions - originalRestrictions).forEach {
                    DietaryService.addDietaryRestriction(it)
                }
                (originalRestrictions - selectedRestrictions).forEach {
                    DietaryService.removeDietaryRestriction(it)
                }

                (selectedPreferences - originalPreferences).forEach {
                    DietaryService.addDietaryPreference(it)
                }
                (originalPreferences - selectedPreferences).forEach {
                    DietaryService.removeDietaryPreference(it)
                }

                onDismiss()
            } catch (e: Exception) {
                errorMessage = e.message ?: "Unable to save your dietary profile."
            } finally {
                isSaving = false
            }
        }
    }

    Column(modifier.fillMaxSize().background(KinColors.background)) {
        KinNavigationBar("Edit Dietary Profile", showBackButton = true, onBack = onDismiss)

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
                SelectableSection("Allergens", allergens, selectedAllergens) { id ->
                    selectedAllergens = selectedAllergens.toggled(id)
                }
                SelectableSection("Dietary Restrictions", restrictions, selectedRestrictions) { id ->
                    selectedRestrictions = selectedRestrictions.toggled(id)
                }
                SelectableSection("Dietary Preferences", preferences, selectedPreferences) { id ->
                    selectedPreferences = selectedPreferences.toggled(id)
                }

                errorMessage?.let {
                    Text(it, style = KinTypography.body, color = KinColors.error)
                }

                KinPrimaryButton(
                    title = if (isSaving) "Saving..." else "Save Changes",
                    color = KinColors.success,
                    enabled = !isSaving,
                ) { saveChanges() }
            }
        }
    }
}

@Composable
private fun SelectableSection(
    title: String,
    items: List<DietaryItem>,
    selectedIds: Set<String>,
    onToggle: (String) -> Unit,
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(KinSpacing.medium),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Text(title, style = KinTypography.title, color = KinColors.primaryText)

        KinFlowLayout(spacing = KinSpacing.small) {
            items.forEach { item ->
                KinChip(
                    title = item.name,
                    isSelected = item.id in selectedIds,
                    modifier = Modifier.clickable(role = Role.Checkbox) { onToggle(item.id) },
                )
            }
        }
    }
}

private fun Set<String>.toggled(id: String): Set<String> =
    if (id in this) this - id else this + id
