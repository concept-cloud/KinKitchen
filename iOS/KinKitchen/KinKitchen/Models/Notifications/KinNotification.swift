//
//  KinNotification.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/20/26.
//

import Foundation

// MARK: - Notification Type

enum KinNotificationType:
    String,
    Codable,
    CaseIterable,
    Hashable {

    case gatheringInvitation = "gathering_invitation"
    case invitationAccepted = "invitation_accepted"
    case invitationDeclined = "invitation_declined"
    case gatheringUpdated = "gathering_updated"
    case dishUpdated = "dish_updated"
    case recipeShared = "recipe_shared"
}

// MARK: - Kin Notification

struct KinNotification:
    Codable,
    Identifiable,
    Hashable {

    let id: UUID
    let userId: UUID
    let type: KinNotificationType
    let title: String
    let message: String?
    let relatedType: String?
    let relatedId: UUID?
    let isRead: Bool
    let createdAt: Date

    enum CodingKeys:
        String,
        CodingKey {

        case id
        case userId = "user_id"
        case type
        case title
        case message
        case relatedType = "related_type"
        case relatedId = "related_id"
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

// MARK: - Notification Creation

struct KinNotificationCreate:
    Encodable {

    let userId: UUID
    let type: KinNotificationType
    let title: String
    let message: String?
    let relatedType: String?
    let relatedId: UUID?

    enum CodingKeys:
        String,
        CodingKey {

        case userId = "p_user_id"
        case type = "p_type"
        case title = "p_title"
        case message = "p_message"
        case relatedType = "p_related_type"
        case relatedId = "p_related_id"
    }
}

// MARK: - Notification Read Update

struct KinNotificationReadUpdate:
    Encodable {

    let isRead: Bool

    enum CodingKeys:
        String,
        CodingKey {

        case isRead = "is_read"
    }
}

