package com.pushtomaindev.kinkitchen.models.user

import kotlinx.datetime.Instant
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Mirrors iOS `DietaryPreference`. */
@Serializable
data class DietaryPreference(
    val id: String,
    val name: String,
    @SerialName("created_at") val createdAt: Instant,
)
