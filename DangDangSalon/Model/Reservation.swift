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
    let userId: String
    let userName: String
    let shopId: String
    let shopName: String
    let ownerId: String
    let menus: [String]
    let totalPrice: Int
    let date: Date
    let time: String
    var status: String
    let createdAt: Date
    var reviewWritten: Bool
    
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let phone: String?
    
    let petId: String?
    var request: String?

    // MARK: - Firestore 문서 → 모델 변환
    init?(document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        id = document.documentID
        userId = data["userId"] as? String ?? ""
        userName = data["userName"] as? String ?? ""
        shopId = data["shopId"] as? String ?? ""
        shopName = data["shopName"] as? String ?? ""
        ownerId = data["ownerId"] as? String ?? ""
        menus = data["menus"] as? [String] ?? []
        totalPrice = data["totalPrice"] as? Int ?? 0
        date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
        time = data["time"] as? String ?? ""
        status = data["status"] as? String ?? "예약 요청"
        createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                 ?? (data["timestamp"] as? Timestamp)?.dateValue()
                 ?? Date()
        reviewWritten = data["reviewWritten"] as? Bool ?? false
        
        self.latitude = data["latitude"] as? Double
        self.longitude = data["longitude"] as? Double
        self.address = data["address"] as? String
        self.phone = data["phone"] as? String
        self.request = data["request"] as? String
        self.petId = data["petId"] as? String
    }

    // MARK: - UI용 포맷터
    var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy년 M월 d일 (E)"
        f.locale = Locale(identifier: "ko_KR")
        return f.string(from: date)
    }

    var priceString: String {
        "\(NumberFormatter.localizedString(from: NSNumber(value: totalPrice), number: .decimal))원"
    }
}
