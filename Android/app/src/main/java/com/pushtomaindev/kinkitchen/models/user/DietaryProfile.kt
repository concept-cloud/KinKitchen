package com.pushtomaindev.kinkitchen.models.user

import kotlinx.datetime.Instant
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Mirrors iOS `DietaryProfile`. */
@Serializable
data class DietaryProfile(
    val id: String,
    @SerialName("user_id") val userId: String,
    val visibility: DietaryVisibility,
    val notes: String? = null,
    @SerialName("created_at") val createdAt: Instant,
    @SerialName("updated_at") val updatedAt: Instant,
)

/** Mirrors iOS `DietaryVisibility`. Serialized values match the Swift raw values. */
@Serializable
enum class DietaryVisibility {
    @SerialName("private") PRIVATE,
    @SerialName("connections") CONNECTIONS,
    @SerialName("gatherings") GATHERINGS,
    @SerialName("public") PUBLIC;
}
