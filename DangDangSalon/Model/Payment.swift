//
//  Payment.swift
//  DangSalon
//
//  Created by 최영건 on 11/13/25.
//

import Foundation
import FirebaseFirestore

struct Payment {
    let id: String
    let shopName: String
    let amount: Int
    let method: String
    let createdAt: Date
    
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let shopName = data["shopName"] as? String,
              let amount = data["amount"] as? Int,
              let method = data["method"] as? String,
              let ts = data["createdAt"] as? Timestamp else {
            return nil
        }
        
        self.id = document.documentID
        self.shopName = shopName
        self.amount = amount
        self.method = method
        self.createdAt = ts.dateValue()
    }
}
