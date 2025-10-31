//
//  CustomerInquiry.swift
//  DangSalon
//
//  Created by 최영건 on 10/31/25.
//

import Foundation
import FirebaseFirestore

struct CustomerInquiry {
    let id: String
    let title: String
    let content: String
    let createdAt: Date
    let answer: String?
    let answeredAt: Date?
    
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let title = data["title"] as? String,
              let content = data["content"] as? String,
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        self.id = document.documentID
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.answer = data["answer"] as? String
        self.answeredAt = (data["answeredAt"] as? Timestamp)?.dateValue()
    }
}
