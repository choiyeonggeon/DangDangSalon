//
//  UserReport.swift
//  DangSalon
//
//  Created by 최영건 on 11/20/25.
//

import Foundation
import FirebaseFirestore

struct UserReport {
    let reportId: String
    let reporterId: String       // 신고한 사람
    let targetUserId: String     // 신고 당한 사용자
    let reason: String
    let status: String
    let createdAt: Date
    
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        self.reportId = data["reportId"] as? String ?? document.documentID
        self.reporterId = data["reporterId"] as? String ?? ""
        self.targetUserId = data["targetUserId"] as? String ?? ""
        self.reason = data["reason"] as? String ?? ""
        self.status = data["status"] as? String ?? "pending"
        
        if let ts = data["createdAt"] as? Timestamp {
            self.createdAt = ts.dateValue()
        } else {
            self.createdAt = Date()
        }
    }
}
