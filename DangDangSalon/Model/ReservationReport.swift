//  ReservationReport.swift
//  DangSalon / DangDangSalon 공용으로 써도 됨

import Foundation
import FirebaseFirestore

struct ReservationReport {
    
    let reportId: String
    let name: String
    let reservationId: String
    let reporterId: String
    let targetOwnerId: String
    let reason: String
    let status: String
    let createdAt: Date
    
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        
        self.name = data["name"] as? String ?? "(이름 없음)"   // ← 여기 변경
        self.reportId = data["reportId"] as? String ?? document.documentID
        self.reservationId = data["reservationId"] as? String ?? ""
        self.reporterId = data["reporterId"] as? String ?? ""
        self.targetOwnerId = data["targetOwnerId"] as? String ?? ""
        self.reason = data["reason"] as? String ?? ""
        self.status = data["status"] as? String ?? "pending"
        
        if let ts = data["createdAt"] as? Timestamp {
            self.createdAt = ts.dateValue()
        } else {
            self.createdAt = Date()
        }
    }
}
