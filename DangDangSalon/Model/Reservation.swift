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
    let menus: [String]         // ✅ 배열로 변경
    let totalPrice: Int         // ✅ 총 금액
    let date: Date
    let time: String
    let status: String
    let reviewWritten: Bool
    
    // Firestore → 모델 변환
    init?(data: [String: Any]) {
        guard let id = data["id"] as? String,
              let shopId = data["shopId"] as? String,
              let shopName = data["shopName"] as? String,
              let menus = data["menus"] as? [String],
              let totalPrice = data["totalPrice"] as? Int,
              let timestamp = data["date"] as? Timestamp,
              let time = data["time"] as? String,
              let status = data["status"] as? String,
              let reviewWritten = data["reviewWritten"] as? Bool else { return nil }
        
        self.id = id
        self.shopId = shopId
        self.shopName = shopName
        self.menus = menus
        self.totalPrice = totalPrice
        self.date = timestamp.dateValue()
        self.time = time
        self.status = status
        self.reviewWritten = reviewWritten
    }
    
    var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy년 M월 d일"
        return f.string(from: date)
    }
    
    var priceString: String {
        return "\(totalPrice.formatted())원"
    }
}

extension Reservation {
    init?(document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        var fullData = data
        fullData["id"] = document.documentID
        self.init(data: fullData)
    }
}
