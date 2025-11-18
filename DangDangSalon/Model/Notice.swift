//
//  Notice.swift
//  DangSalon
//
//  Created by 최영건 on 11/11/25.
//

import Foundation
import FirebaseFirestore

struct Notice {
    let id: String
    let title: String
    let content: String
    let createdAt: Date
    let isPinned: Bool
    
    init(document: DocumentSnapshot) {
        self.id = document.documentID
        let data = document.data() ?? [:]
        self.title = data["title"] as? String ?? "제목 없음"
        self.content = data["content"] as? String ?? ""
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.isPinned = data["isPinned"] as? Bool ?? false
    }
}
