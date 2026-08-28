//
//  SupabaseManager.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import Foundation
import Supabase

enum SupabaseManager {

    static let client: SupabaseClient = {
        guard
            let urlString = Bundle.main.object(
                forInfoDictionaryKey: "SUPABASE_URL"
            ) as? String,
            let url = URL(string: urlString),
            let key = Bundle.main.object(
                forInfoDictionaryKey: "SUPABASE_KEY"
            ) as? String,
            !key.isEmpty
        else {
            fatalError("Supabase configuration is missing.")
        }

        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: key,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }()
}
