package com.pushtomaindev.kinkitchen.models.user

import kotlinx.datetime.Instant
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Mirrors iOS `Profile`. Row shape of the `profiles` table.
 *
 * `birthDate` is a String rather than a date type, matching iOS — the column
 * is a bare `date`, so keeping it textual avoids timezone drift on a value
 * that has no time component.
 */
@Serializable
data class Profile(
    val id: String,
    val username: String? = null,
    @SerialName("display_name") val displayName: String? = null,
    @SerialName("first_name") val firstName: String? = null,
    @SerialName("last_name") val lastName: String? = null,
    val location: String? = null,
    @SerialName("birth_date") val birthDate: String? = null,
    val bio: String? = null,
    @SerialName("profile_photo_path") val profilePhotoPath: String? = null,
    @SerialName("created_at") val createdAt: Instant,
    @SerialName("updated_at") val updatedAt: Instant,
)
