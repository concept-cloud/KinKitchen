package com.pushtomaindev.kinkitchen.services.supabase

import com.pushtomaindev.kinkitchen.models.user.Profile
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Columns
import io.github.jan.supabase.storage.storage
import kotlinx.datetime.Clock
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.TimeZone
import kotlinx.datetime.plus
import kotlinx.datetime.Instant
import kotlinx.datetime.LocalDate
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Mirrors iOS `UsernameAvailability`. */
enum class UsernameAvailability { UNKNOWN, CHECKING, AVAILABLE, TAKEN }

/**
 * Mirrors iOS `ProfileRequirement`. Any new requirement is added here and in
 * [ProfileService.missingProfileRequirements].
 */
enum class ProfileRequirement { FIRST_NAME, LAST_NAME, USERNAME, BIRTH_DATE }

/** Mirrors iOS `ProfileService`. */
object ProfileService {

    private const val PHOTO_BUCKET = "profile-photos"

    private val client get() = SupabaseManager.client

    // MARK: - Profile

    suspend fun fetchCurrentProfile(): Profile {
        val userId = requireUserId()
        return client.from("profiles")
            .select { filter { eq("id", userId) } }
            .decodeSingle()
    }

    suspend fun isUsernameAvailable(username: String): Boolean {
        val clean = username.trim()
        if (clean.isEmpty()) return false

        return client.from("profiles")
            .select { filter { eq("username", clean) }; limit(1) }
            .decodeList<Profile>()
            .isEmpty()
    }

    suspend fun isCurrentProfileComplete(): Boolean =
        missingProfileRequirements(fetchCurrentProfile()).isEmpty()

    suspend fun completeInitialProfile(
        firstName: String,
        lastName: String,
        username: String,
        location: String,
        birthDate: LocalDate,
        bio: String,
    ) {
        val userId = requireUserId()
        val cleanFirst = firstName.trim()
        val cleanLast = lastName.trim()

        val updates = ProfileUpdate(
            firstName = cleanFirst,
            lastName = cleanLast,
            displayName = "$cleanFirst $cleanLast",
            username = username.trim(),
            location = location.trim(),
            birthDate = birthDate.toString(),
            bio = bio.trim(),
        )

        client.from("profiles").update(updates) { filter { eq("id", userId) } }
    }

    suspend fun updateProfile(
        firstName: String,
        lastName: String,
        displayName: String,
        username: String,
        location: String,
        birthDate: LocalDate,
        bio: String,
    ) {
        val userId = requireUserId()

        val updates = ProfileUpdate(
            firstName = firstName.trim(),
            lastName = lastName.trim(),
            displayName = displayName.trim(),
            username = username.trim(),
            location = location.trim(),
            birthDate = birthDate.toString(),
            bio = bio.trim(),
        )

        client.from("profiles").update(updates) { filter { eq("id", userId) } }
    }

    // MARK: - Photos

    suspend fun uploadProfilePhoto(imageData: ByteArray): String {
        val userId = requireUserId()
        val path = "${userId.lowercase()}/profile.jpg"

        client.storage.from(PHOTO_BUCKET).upload(path, imageData) {
            upsert = true
            contentType = io.ktor.http.ContentType.Image.JPEG
        }

        client.from("profiles")
            .update(ProfilePhotoUpdate(path)) { filter { eq("id", userId) } }

        return path
    }

    suspend fun fetchProfilePhoto(path: String): ByteArray =
        client.storage.from(PHOTO_BUCKET).downloadAuthenticated(path)

    // MARK: - Dietary Setup

    suspend fun isDietarySetupComplete(): Boolean =
        fetchDietarySetupStatus().dietarySetupCompletedAt != null

    /** Mirrors iOS `isDietaryReviewDue` — a review falls due one year on. */
    suspend fun isDietaryReviewDue(): Boolean {
        val completedAt = fetchDietarySetupStatus().dietarySetupCompletedAt ?: return false
        val reviewDate = completedAt.plus(365, DateTimeUnit.DAY, TimeZone.currentSystemDefault())
        return Clock.System.now() >= reviewDate
    }

    suspend fun fetchDietaryLastUpdated(): Instant? =
        fetchDietarySetupStatus().dietarySetupCompletedAt

    suspend fun markDietarySetupReviewed() {
        val userId = requireUserId()
        client.from("profiles")
            .update(DietarySetupReviewUpdate(Clock.System.now())) { filter { eq("id", userId) } }
    }

    private suspend fun fetchDietarySetupStatus(): DietarySetupStatus {
        val userId = requireUserId()
        return client.from("profiles")
            .select(Columns.list("dietary_setup_completed_at")) { filter { eq("id", userId) } }
            .decodeSingle()
    }

    // MARK: - Requirements

    /** Mirrors iOS `missingProfileRequirements`. */
    fun missingProfileRequirements(profile: Profile): List<ProfileRequirement> =
        buildList {
            if (profile.firstName?.trim().isNullOrEmpty()) add(ProfileRequirement.FIRST_NAME)
            if (profile.lastName?.trim().isNullOrEmpty()) add(ProfileRequirement.LAST_NAME)
            if (profile.username?.trim().isNullOrEmpty()) add(ProfileRequirement.USERNAME)
            if (profile.birthDate?.trim().isNullOrEmpty()) add(ProfileRequirement.BIRTH_DATE)
        }

    /** Mirrors iOS `date(from:)` — parses the stored `yyyy-MM-dd` birth date. */
    fun birthDate(from: String?): LocalDate? =
        from?.takeIf { it.isNotBlank() }?.let { runCatching { LocalDate.parse(it) }.getOrNull() }
}

// Update payloads. Kept private to this file, matching iOS.

/**
 * iOS declares `InitialProfileUpdate` and `ProfileUpdate` with identical
 * fields and coding keys; one type covers both here.
 */
@Serializable
private data class ProfileUpdate(
    @SerialName("first_name") val firstName: String,
    @SerialName("last_name") val lastName: String,
    @SerialName("display_name") val displayName: String,
    val username: String,
    val location: String,
    @SerialName("birth_date") val birthDate: String,
    val bio: String,
)

@Serializable
private data class ProfilePhotoUpdate(
    @SerialName("profile_photo_path") val profilePhotoPath: String,
)

@Serializable
private data class DietarySetupStatus(
    @SerialName("dietary_setup_completed_at") val dietarySetupCompletedAt: Instant? = null,
)

@Serializable
private data class DietarySetupReviewUpdate(
    @SerialName("dietary_setup_completed_at") val dietarySetupCompletedAt: Instant,
)
