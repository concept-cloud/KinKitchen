//
//  ProfileService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/27/26.
//

import Foundation
import Supabase

enum UsernameAvailability {
    case unknown
    case checking
    case available
    case taken
}

// Any additional requirements are added here and
// in the missingProfileRequirements function below.
enum ProfileRequirement: CaseIterable {
    case firstName
    case lastName
    case username
    case birthDate
}

enum ProfileService {

    static func fetchCurrentProfile() async throws -> Profile {

        let user =
            try await SupabaseManager.client.auth.session.user

        let profile: Profile =
            try await SupabaseManager.client
                .from("profiles")
                .select()
                .eq("id", value: user.id)
                .single()
                .execute()
                .value

        return profile
    }

    static func isUsernameAvailable(
        _ username: String
    ) async throws -> Bool {

        let cleanUsername =
            username.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanUsername.isEmpty else {
            return false
        }

        let existingProfiles: [Profile] =
            try await SupabaseManager.client
                .from("profiles")
                .select()
                .eq(
                    "username",
                    value: cleanUsername
                )
                .limit(1)
                .execute()
                .value

        return existingProfiles.isEmpty
    }

    static func isCurrentProfileComplete() async throws -> Bool {

        let profile =
            try await fetchCurrentProfile()

        return missingProfileRequirements(
            for: profile
        ).isEmpty
    }

    static func completeInitialProfile(
        firstName: String,
        lastName: String,
        username: String,
        location: String,
        birthDate: Date,
        bio: String
    ) async throws {

        let user =
            try await SupabaseManager.client.auth.session.user

        let cleanFirstName =
            firstName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let cleanLastName =
            lastName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let displayName =
            "\(cleanFirstName) \(cleanLastName)"

        let updates =
            InitialProfileUpdate(
                firstName: cleanFirstName,
                lastName: cleanLastName,
                displayName: displayName,
                username:
                    username.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
                location:
                    location.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
                birthDate:
                    dateString(
                        from: birthDate
                    ),
                bio:
                    bio.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
            )

        try await SupabaseManager.client
            .from("profiles")
            .update(updates)
            .eq("id", value: user.id)
            .execute()
    }

    static func updateProfile(
        firstName: String,
        lastName: String,
        displayName: String,
        username: String,
        location: String,
        birthDate: Date,
        bio: String
    ) async throws {

        let user =
            try await SupabaseManager.client.auth.session.user

        let updates =
            ProfileUpdate(
                firstName:
                    firstName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
                lastName:
                    lastName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
                displayName:
                    displayName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
                username:
                    username.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
                location:
                    location.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
                birthDate:
                    dateString(
                        from: birthDate
                    ),
                bio:
                    bio.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
            )

        try await SupabaseManager.client
            .from("profiles")
            .update(updates)
            .eq("id", value: user.id)
            .execute()
    }

    static func uploadProfilePhoto(
        _ imageData: Data
    ) async throws -> String {

        let user =
            try await SupabaseManager.client.auth.session.user

        let path =
            "\(user.id.uuidString.lowercased())/profile.jpg"

        try await SupabaseManager.client.storage
            .from("profile-photos")
            .upload(
                path,
                data: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )

        let updates =
            ProfilePhotoUpdate(
                profilePhotoPath: path
            )

        try await SupabaseManager.client
            .from("profiles")
            .update(updates)
            .eq("id", value: user.id)
            .execute()

        return path
    }

    static func fetchProfilePhoto(
        path: String
    ) async throws -> Data {

        try await SupabaseManager.client.storage
            .from("profile-photos")
            .download(
                path: path
            )
    }

    // MARK: - Dietary Setup

    static func isDietarySetupComplete() async throws -> Bool {

        let status =
            try await fetchDietarySetupStatus()

        return status.dietarySetupCompletedAt != nil
    }

    static func isDietaryReviewDue() async throws -> Bool {

        let status =
            try await fetchDietarySetupStatus()

        guard let completedAt =
            status.dietarySetupCompletedAt
        else {
            return false
        }

        let calendar =
            Calendar.current

        guard let reviewDate =
            calendar.date(
                byAdding: .year,
                value: 1,
                to: completedAt
            )
        else {
            return false
        }

        return Date() >= reviewDate
    }
    
    static func fetchDietaryLastUpdated() async throws -> Date? {

        let status =
            try await fetchDietarySetupStatus()

        return status.dietarySetupCompletedAt
    }

    static func markDietarySetupReviewed() async throws {

        let user =
            try await SupabaseManager.client.auth.session.user

        let updates =
            DietarySetupReviewUpdate(
                dietarySetupCompletedAt: Date()
            )

        try await SupabaseManager.client
            .from("profiles")
            .update(updates)
            .eq("id", value: user.id)
            .execute()
    }

    private static func fetchDietarySetupStatus() async throws
        -> DietarySetupStatus {

        let user =
            try await SupabaseManager.client.auth.session.user

        let status: DietarySetupStatus =
            try await SupabaseManager.client
                .from("profiles")
                .select("dietary_setup_completed_at")
                .eq("id", value: user.id)
                .single()
                .execute()
                .value

        return status
    }

    // MARK: - Dates

    static func date(
        from string: String?
    ) -> Date? {

        guard let string else {
            return nil
        }

        return birthDateFormatter.date(
            from: string
        )
    }

    private static func dateString(
        from date: Date
    ) -> String {

        birthDateFormatter.string(
            from: date
        )
    }

    private static let birthDateFormatter: DateFormatter = {

        let formatter =
            DateFormatter()

        formatter.calendar =
            Calendar(
                identifier: .gregorian
            )

        formatter.locale =
            Locale(
                identifier: "en_US_POSIX"
            )

        formatter.dateFormat =
            "yyyy-MM-dd"

        return formatter
    }()

    // Other requirements are added here.
    static func missingProfileRequirements(
        for profile: Profile
    ) -> [ProfileRequirement] {

        var missing:
            [ProfileRequirement] = []

        let firstName =
            profile.firstName?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                ?? ""

        let lastName =
            profile.lastName?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                ?? ""

        let username =
            profile.username?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                ?? ""

        let birthDate =
            profile.birthDate?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                ?? ""

        if firstName.isEmpty {
            missing.append(.firstName)
        }

        if lastName.isEmpty {
            missing.append(.lastName)
        }

        if username.isEmpty {
            missing.append(.username)
        }

        if birthDate.isEmpty {
            missing.append(.birthDate)
        }

        return missing
    }
}

private struct InitialProfileUpdate: Encodable {

    let firstName: String
    let lastName: String
    let displayName: String
    let username: String
    let location: String
    let birthDate: String
    let bio: String

    enum CodingKeys: String, CodingKey {

        case firstName =
            "first_name"

        case lastName =
            "last_name"

        case displayName =
            "display_name"

        case username
        case location

        case birthDate =
            "birth_date"

        case bio
    }
}

private struct ProfileUpdate: Encodable {

    let firstName: String
    let lastName: String
    let displayName: String
    let username: String
    let location: String
    let birthDate: String
    let bio: String

    enum CodingKeys: String, CodingKey {

        case firstName =
            "first_name"

        case lastName =
            "last_name"

        case displayName =
            "display_name"

        case username
        case location

        case birthDate =
            "birth_date"

        case bio
    }
}

private struct ProfilePhotoUpdate: Encodable {

    let profilePhotoPath: String

    enum CodingKeys: String, CodingKey {

        case profilePhotoPath =
            "profile_photo_path"
    }
}

private struct DietarySetupStatus: Decodable {

    let dietarySetupCompletedAt: Date?

    enum CodingKeys: String, CodingKey {

        case dietarySetupCompletedAt =
            "dietary_setup_completed_at"
    }
}

private struct DietarySetupReviewUpdate: Encodable {

    let dietarySetupCompletedAt: Date

    enum CodingKeys: String, CodingKey {

        case dietarySetupCompletedAt =
            "dietary_setup_completed_at"
    }
}
