//
//  Coupon.swift
//  DangSalon
//
//  Created by 최영건 on 12/15/25.
//

import Foundation
import FirebaseFirestore

struct Coupon {
    let id: String
    let title: String
    let discountType: String
    let discountValue: Int
    let minPrice: Int
    let expiredAt: Timestamp
    let shopId: String
    let isActive: Bool
    
    init?(doc: DocumentSnapshot) {
        let data = doc.data() ?? [:]
        
        guard let expiredAt = data["expiredAt"] as? Timestamp else {
            return nil
        }
        
        self.id = doc.documentID
        self.title = data["title"] as? String ?? ""
        self.discountType = data["discountType"] as? String ?? "amount"
        self.discountValue = data["discountValue"] as? Int ?? 0
        self.minPrice = data["minPrice"] as? Int ?? 0
        self.expiredAt = expiredAt
        self.shopId = data["shopID"] as? String ?? "all"
        self.isActive = data["isActive"] as? Bool ?? false
    }
}
