package com.pushtomaindev.kinkitchen.models

import com.pushtomaindev.kinkitchen.models.user.Allergen
import com.pushtomaindev.kinkitchen.models.user.DietaryProfile
import com.pushtomaindev.kinkitchen.models.user.DietaryVisibility
import com.pushtomaindev.kinkitchen.models.user.Profile
import kotlinx.serialization.json.Json
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * Decodes payloads shaped like real PostgREST responses, so the snake_case
 * mappings and timestamptz parsing are verified against the wire format
 * rather than assumed.
 */
class UserModelsSerializationTest {

    private val json = Json { ignoreUnknownKeys = true }

    @Test
    fun `decodes a fully populated profile row`() {
        val row = """
            {
              "id": "8f2a1c3e-4b5d-6e7f-8091-a2b3c4d5e6f7",
              "username": "greg",
              "display_name": "Greg H",
              "first_name": "Greg",
              "last_name": "Hudler",
              "location": "Chicago",
              "birth_date": "1990-04-12",
              "bio": "Cooks a lot.",
              "profile_photo_path": "8f2a/avatar.jpg",
              "created_at": "2026-08-26T12:34:56.789012+00:00",
              "updated_at": "2026-09-01T09:00:00+00:00"
            }
        """.trimIndent()

        val p = json.decodeFromString<Profile>(row)
        assertEquals("greg", p.username)
        assertEquals("Greg H", p.displayName)
        assertEquals("Hudler", p.lastName)
        assertEquals("1990-04-12", p.birthDate)
        assertEquals("8f2a/avatar.jpg", p.profilePhotoPath)
        // microsecond precision from Postgres must survive parsing
        assertEquals("2026-08-26T12:34:56.789012Z", p.createdAt.toString())
    }

    @Test
    fun `decodes a profile row with explicit nulls`() {
        val row = """
            {
              "id": "8f2a1c3e-4b5d-6e7f-8091-a2b3c4d5e6f7",
              "username": null,
              "display_name": null,
              "first_name": null,
              "last_name": null,
              "location": null,
              "birth_date": null,
              "bio": null,
              "profile_photo_path": null,
              "created_at": "2026-08-26T12:34:56+00:00",
              "updated_at": "2026-08-26T12:34:56+00:00"
            }
        """.trimIndent()

        val p = json.decodeFromString<Profile>(row)
        assertNull(p.username)
        assertNull(p.bio)
        assertNull(p.profilePhotoPath)
    }

    @Test
    fun `round-trips a profile without losing snake_case keys`() {
        val row = """
            {"id":"1","display_name":"D","created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}
        """.trimIndent()
        val encoded = Json.encodeToString(json.decodeFromString<Profile>(row))
        assert(encoded.contains("\"display_name\"")) { "expected snake_case key, got: $encoded" }
        assert(!encoded.contains("displayName")) { "camelCase leaked into payload: $encoded" }
    }

    @Test
    fun `decodes every dietary visibility value written by iOS`() {
        val expected = mapOf(
            "private" to DietaryVisibility.PRIVATE,
            "connections" to DietaryVisibility.CONNECTIONS,
            "gatherings" to DietaryVisibility.GATHERINGS,
            "public" to DietaryVisibility.PUBLIC,
        )
        expected.forEach { (raw, value) ->
            val row = """
                {"id":"1","user_id":"2","visibility":"$raw",
                 "created_at":"2026-01-01T00:00:00Z","updated_at":"2026-01-01T00:00:00Z"}
            """.trimIndent()
            assertEquals(value, json.decodeFromString<DietaryProfile>(row).visibility)
        }
    }

    @Test
    fun `encodes visibility back to the lowercase raw value`() {
        val p = DietaryProfile(
            id = "1",
            userId = "2",
            visibility = DietaryVisibility.CONNECTIONS,
            notes = null,
            createdAt = kotlinx.datetime.Instant.parse("2026-01-01T00:00:00Z"),
            updatedAt = kotlinx.datetime.Instant.parse("2026-01-01T00:00:00Z"),
        )
        assert(Json.encodeToString(p).contains("\"visibility\":\"connections\"")) {
            "visibility must serialize as the lowercase value iOS writes"
        }
    }

    @Test
    fun `decodes a lookup table row`() {
        val a = json.decodeFromString<Allergen>(
            """{"id":"3","name":"Peanuts","created_at":"2026-01-01T00:00:00Z"}"""
        )
        assertEquals("Peanuts", a.name)
    }
}
