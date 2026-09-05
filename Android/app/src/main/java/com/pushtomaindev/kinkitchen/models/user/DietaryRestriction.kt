package com.pushtomaindev.kinkitchen.models.user

import kotlinx.datetime.Instant
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Mirrors iOS `DietaryRestriction`. */
@Serializable
data class DietaryRestriction(
    val id: String,
    val name: String,
    @SerialName("created_at") val createdAt: Instant,
)
