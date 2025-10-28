//
//  Reservation.swift
//  DangSalon
//
//  Created by 최영건 on 10/27/25.
//

import Foundation
import FirebaseFirestore

struct Reservation {
    let id: String
    let shopId: String
    let shopName: String
    let menu: String
    let price: Int
    let date: Timestamp
    let time: String
    let status: String        // "pending", "completed", "cancelled"
    let reviewWritten: Bool
    let reserverName: String // 예약자 이름 (닉네임)
    
    init?(document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        
        // 필수값들
        guard
            let shopId = data["shopId"] as? String,
            let shopName = data["shopName"] as? String,
            let menu = data["menu"] as? String,
            let price = data["price"] as? Int,
            let date = data["date"] as? Timestamp,
            let time = data["time"] as? String,
            let status = data["status"] as? String
        else {
            return nil
        }
        
        self.id = document.documentID
        self.shopId = shopId
        self.shopName = shopName
        self.menu = menu
        self.price = price
        self.date = date
        self.time = time
        self.status = status
        self.reviewWritten = data["reviewWritten"] as? Bool ?? false
        
        // 예약자 이름(고객 이름)은 따로 저장해놨다면 거기서 읽고, 없으면 빈값
        self.reserverName = data["name"] as? String ?? ""
    }
    
    // 보기 예쁘게 쓸 수 있는 computed들 (UI용)
    var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "ko_KR")
        return f.string(from: date.dateValue())
    }
    
    var statusText: String {
        switch status {
        case "pending": return "예약 중"
        case "completed": return "이용 완료"
        case "cancelled": return "취소됨"
        default: return status
        }
    }
    
    var priceString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: price)) ?? "\(price)"
        return "\(formatted)원"
    }
}
