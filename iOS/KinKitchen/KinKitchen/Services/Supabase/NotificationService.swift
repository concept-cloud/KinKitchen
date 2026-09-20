//
//  NotificationService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/20/26.
//

import Foundation
import Supabase

enum NotificationService {

    // MARK: - Create Notification

    static func createNotification(
        recipientId: UUID,
        type: KinNotificationType,
        title: String,
        message: String? = nil,
        relatedType: String? = nil,
        relatedId: UUID? = nil
    ) async throws -> KinNotification {

        let payload =
            KinNotificationCreate(
                userId: recipientId,
                type: type,
                title: title,
                message: message,
                relatedType: relatedType,
                relatedId: relatedId
            )

        let notification: KinNotification =
            try await SupabaseManager.client
                .rpc(
                    "create_notification",
                    params: payload
                )
                .single()
                .execute()
                .value

        return notification
    }

    // MARK: - Fetch Notifications

    static func fetchNotifications()
        async throws -> [KinNotification] {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let notifications: [KinNotification] =
            try await SupabaseManager.client
                .from("notifications")
                .select()
                .eq(
                    "user_id",
                    value: user.id
                )
                .order(
                    "created_at",
                    ascending: false
                )
                .execute()
                .value

        return notifications
    }

    // MARK: - Mark Read

    static func markAsRead(
        notificationId: UUID
    ) async throws {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let payload =
            KinNotificationReadUpdate(
                isRead: true
            )

        try await SupabaseManager.client
            .from("notifications")
            .update(payload)
            .eq(
                "id",
                value: notificationId
            )
            .eq(
                "user_id",
                value: user.id
            )
            .execute()
    }

    // MARK: - Mark Unread

    static func markAsUnread(
        notificationId: UUID
    ) async throws {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let payload =
            KinNotificationReadUpdate(
                isRead: false
            )

        try await SupabaseManager.client
            .from("notifications")
            .update(payload)
            .eq(
                "id",
                value: notificationId
            )
            .eq(
                "user_id",
                value: user.id
            )
            .execute()
    }
}
