//
//  ReviewReport.swift
//  DangSalon
//
//  Created by 최영건 on 11/18/25.
//

import Foundation
import FirebaseFirestore

struct ReviewReport {
    let id: String
    let shopId: String
    let reviewId: String
    let reason: String
    let reporterUid: String
    let createdAt: Date
    
    init?(document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        
        self.id = document.documentID
        self.shopId = data["shopId"] as? String ?? ""
        self.reviewId = data["reviewId"] as? String ?? ""
        self.reason = data["reason"] as? String ?? ""
        self.reporterUid = data["reporterUid"] as? String ?? ""
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
    }
}
