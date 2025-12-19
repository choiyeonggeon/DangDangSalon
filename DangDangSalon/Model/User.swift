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
    let id: String       // 문서 ID
    let name: String?    // 사용자 이름
    let phone: String?
    let createdAt: Date?
    
    // 기존 DocumentSnapshot 기반 초기화
    init?(document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        guard let nickname = data["nickname"] as? String,
              let email = data["email"] as? String else {
            return nil
        }
        self.nickname = nickname
        self.email = email
        self.id = document.documentID
        self.name = data["name"] as? String
        self.phone = data["phone"] as? String
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
    }
    
    // 커스텀 이니셜라이저: id와 name만 넣고 싶을 때
    init(id: String, name: String) {
        self.id = id
        self.name = name
        self.nickname = "" // 필수 필드지만 여기서는 비워둠
        self.email = ""    // 필수 필드지만 여기서는 비워둠
        self.phone = nil
        self.createdAt = nil
    }
}
