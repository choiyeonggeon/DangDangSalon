//
//  NotificationInbox.swift
//  DangSalon
//
//  Created by 최영건 on 12/23/25.
//

import Foundation
import FirebaseFirestore

// 홈 화면 알림용 모델
enum NotificationType: String {
    case reservation
    case coupon
    case notice
}

struct AppNotification {
    
    let id: String
    let title: String
    let message: String
    let createdAt: Date
    let type: NotificationType
    let targetId: String?
    
    var isRead: Bool
    
    init?(doc: DocumentSnapshot) {
        let data = doc.data() ?? [:]
        
        guard
            let title = data["title"] as? String,
            let message = data["message"] as? String,
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
            let isRead = data["isRead"] as? Bool,
            let typeRaw = data["type"] as? String,
            let type = NotificationType(rawValue: typeRaw)
        else { return nil }
        
        self.id = doc.documentID
        self.title = title
        self.message = message
        self.createdAt = createdAt
        self.isRead = isRead
        self.type = type
        self.targetId = data["targetId"] as? String
    }
}
