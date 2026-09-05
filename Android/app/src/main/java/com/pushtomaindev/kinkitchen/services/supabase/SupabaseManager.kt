package com.pushtomaindev.kinkitchen.services.supabase

import com.pushtomaindev.kinkitchen.BuildConfig
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.storage.Storage

/**
 * Mirrors iOS `SupabaseManager`. Credentials come from `local.properties`
 * (or env vars in CI) via BuildConfig, never hardcoded.
 */
object SupabaseManager {

    val client: SupabaseClient by lazy {
        check(BuildConfig.SUPABASE_URL.isNotEmpty() && BuildConfig.SUPABASE_KEY.isNotEmpty()) {
            "Supabase configuration is missing. Set SUPABASE_URL and SUPABASE_KEY in local.properties."
        }

        createSupabaseClient(
            supabaseUrl = BuildConfig.SUPABASE_URL,
            supabaseKey = BuildConfig.SUPABASE_KEY
        ) {
            install(Auth)
            install(Postgrest)
            install(Storage)
        }
    }
}
