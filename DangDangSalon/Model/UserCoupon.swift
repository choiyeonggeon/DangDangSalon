//
//  UserCoupon.swift
//  DangSalon
//
//  Created by 최영건 on 12/15/25.
//

import Foundation
import FirebaseFirestore

struct UserCoupon {
    let id: String
    let couponId: String
    let isUsed: Bool
    let issuedAt: Timestamp
    let usedAt: Timestamp?
    
    init?(doc: DocumentSnapshot) {
        let data = doc.data() ?? [:]
        self.id = doc.documentID
        self.couponId = data["couponID"] as? String ?? ""
        self.isUsed = data["isUsed"] as? Bool ?? false
        self.issuedAt = data["issuedAt"] as? Timestamp ?? Timestamp()
        self.usedAt = data["usedAt"] as? Timestamp
    }
}
