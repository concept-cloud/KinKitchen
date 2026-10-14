//
//  StorageImageCache.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import Foundation
import Supabase

/// Keeps photos downloaded from Supabase storage in memory, so covers
/// and recipe photos show instantly when a screen comes back instead of
/// downloading again. iOS empties it under memory pressure, and it
/// starts fresh each launch.
///
/// Recipe photos and cookbook covers are replaced in place (same path),
/// so their upload code calls `remove` to drop the old copy.
nonisolated final class StorageImageCache: @unchecked Sendable {

    static let shared = StorageImageCache()

    private let cache: NSCache<NSString, NSData> = {
        let cache = NSCache<NSString, NSData>()
        cache.totalCostLimit = 80 * 1_024 * 1_024 // ~80 MB
        return cache
    }()

    private init() {}


    /// The cached photo, or downloads and caches it.
    func data(
        bucket: String,
        path: String
    ) async throws -> Data {

        let key = Self.key(bucket: bucket, path: path)

        if let cached = cache.object(forKey: key) {
            return cached as Data
        }

        let data =
            try await SupabaseManager.client.storage
                .from(bucket)
                .download(path: path)

        cache.setObject(
            data as NSData,
            forKey: key,
            cost: data.count
        )

        return data
    }

    /// The cached photo only, without downloading (for showing it
    /// on the very first frame).
    func cached(
        bucket: String,
        path: String
    ) -> Data? {
        cache.object(forKey: Self.key(bucket: bucket, path: path)) as Data?
    }

    func remove(
        bucket: String,
        path: String
    ) {
        cache.removeObject(forKey: Self.key(bucket: bucket, path: path))
    }

    /// e.g. when signing out.
    func removeAll() {
        cache.removeAllObjects()
    }

    static func key(
        bucket: String,
        path: String
    ) -> NSString {
        "\(bucket)/\(path)" as NSString
    }
}
