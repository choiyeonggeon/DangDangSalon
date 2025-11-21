//
//  User.swift
//  DangSalon
//
//  Created by 최영건 on 10/26/25.
//

import Foundation
import FirebaseFirestore

struct User {
    let nickname: String
    let email: String
    let name: String?
    let phone: String?
    let createdAt: Date?
    
    init?(document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        guard let nickname = data["nickname"] as? String,
              let email = data["email"] as? String else {
            return nil
        }
        self.nickname = nickname
        self.email = email
        self.name = data["name"] as? String
        self.phone = data["phone"] as? String
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
    }
}
