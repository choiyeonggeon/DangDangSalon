//
//  Review.swift
//  DangSalon
//
//  Created by 최영건 on 10/24/25.
//

import Foundation
import FirebaseFirestore

struct Review {
    let id: String
    let nickname: String
    let authorId: String
    let content: String
    let rating: Double
    let timestamp: Date?
    let reply: String?
    let imageURLs: [String]
    
    let isBlinded: Bool
    let blindedUntil: Date?
    
    init?(document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        guard let nickname = data["nickname"] as? String,
              let content = data["content"] as? String else {
            return nil
        }
        self.id = document.documentID
        self.nickname = nickname
        self.authorId = data["authorId"] as? String ?? ""   // ⭐ 추가!
        self.content = content
        self.rating = (data["rating"] as? Double) ?? 5.0
        self.timestamp = (data["timestamp"] as? Timestamp)?.dateValue()
        self.reply = data["reply"] as? String
        imageURLs = data["imageURLs"] as? [String] ?? []
        
        self.isBlinded = data["isBlinded"] as? Bool ?? false
        self.blindedUntil = (data["blindedUntil"] as? Timestamp)?.dateValue()
    }
}
