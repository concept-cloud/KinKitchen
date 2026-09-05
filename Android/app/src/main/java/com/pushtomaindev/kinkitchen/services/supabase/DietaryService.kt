package com.pushtomaindev.kinkitchen.services.supabase

import com.pushtomaindev.kinkitchen.models.user.Allergen
import com.pushtomaindev.kinkitchen.models.user.DietaryPreference
import com.pushtomaindev.kinkitchen.models.user.DietaryRestriction
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Mirrors iOS `DietaryService`. */
object DietaryService {

    private val client get() = SupabaseManager.client

    // MARK: - Allergens

    suspend fun fetchAllergens(): List<Allergen> =
        client.from("allergens")
            .select { order("name", Order.ASCENDING) }
            .decodeList()

    suspend fun fetchSelectedAllergens(): List<String> {
        val userId = requireUserId()
        return client.from("user_allergens")
            .select { filter { eq("user_id", userId) } }
            .decodeList<UserAllergenSelection>()
            .map { it.allergenId }
    }

    suspend fun addAllergen(allergenId: String) {
        client.from("user_allergens")
            .insert(UserAllergenSelection(requireUserId(), allergenId))
    }

    suspend fun removeAllergen(allergenId: String) {
        val userId = requireUserId()
        client.from("user_allergens").delete {
            filter {
                eq("user_id", userId)
                eq("allergen_id", allergenId)
            }
        }
    }

    // MARK: - Dietary Restrictions

    suspend fun fetchDietaryRestrictions(): List<DietaryRestriction> =
        client.from("dietary_restrictions")
            .select { order("name", Order.ASCENDING) }
            .decodeList()

    suspend fun fetchSelectedDietaryRestrictions(): List<String> {
        val userId = requireUserId()
        return client.from("user_dietary_restrictions")
            .select { filter { eq("user_id", userId) } }
            .decodeList<UserDietaryRestrictionSelection>()
            .map { it.restrictionId }
    }

    suspend fun addDietaryRestriction(restrictionId: String) {
        client.from("user_dietary_restrictions")
            .insert(UserDietaryRestrictionSelection(requireUserId(), restrictionId))
    }

    suspend fun removeDietaryRestriction(restrictionId: String) {
        val userId = requireUserId()
        client.from("user_dietary_restrictions").delete {
            filter {
                eq("user_id", userId)
                eq("restriction_id", restrictionId)
            }
        }
    }

    // MARK: - Dietary Preferences

    suspend fun fetchDietaryPreferences(): List<DietaryPreference> =
        client.from("dietary_preferences")
            .select { order("name", Order.ASCENDING) }
            .decodeList()

    suspend fun fetchSelectedDietaryPreferences(): List<String> {
        val userId = requireUserId()
        return client.from("user_dietary_preferences")
            .select { filter { eq("user_id", userId) } }
            .decodeList<UserDietaryPreferenceSelection>()
            .map { it.preferenceId }
    }

    suspend fun addDietaryPreference(preferenceId: String) {
        client.from("user_dietary_preferences")
            .insert(UserDietaryPreferenceSelection(requireUserId(), preferenceId))
    }

    suspend fun removeDietaryPreference(preferenceId: String) {
        val userId = requireUserId()
        client.from("user_dietary_preferences").delete {
            filter {
                eq("user_id", userId)
                eq("preference_id", preferenceId)
            }
        }
    }
}

// Join-table rows. Kept private to this file, matching iOS.

@Serializable
private data class UserAllergenSelection(
    @SerialName("user_id") val userId: String,
    @SerialName("allergen_id") val allergenId: String,
)

@Serializable
private data class UserDietaryRestrictionSelection(
    @SerialName("user_id") val userId: String,
    @SerialName("restriction_id") val restrictionId: String,
)

@Serializable
private data class UserDietaryPreferenceSelection(
    @SerialName("user_id") val userId: String,
    @SerialName("preference_id") val preferenceId: String,
)
