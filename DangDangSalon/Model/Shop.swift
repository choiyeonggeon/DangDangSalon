//
//  Shop.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/16/25.
//

import Foundation
import FirebaseFirestore

struct Shop {
    let isAds: Bool
    var isNew: Bool
    let isRecommended: Bool
    
    let id: String
    let name: String
    let rating: Double     // ← avgRating을 담는 값
    let reviewCount: Int
    let imageURLs: [String]?
    var distanceMeter: Int?
    let sizeType: String?
    let address: String?
    let phone: String?
    let intro: String?
    let openTime: String?
    let closeTime: String?
    let category: String?
    let createdAt: Date?
    
    let latitude: Double?
    let longitude: Double?
    
    init?(document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        
        guard let name = data["name"] as? String else { return nil }
        
        self.id = document.documentID
        self.name = name
        
        // 🔥 평균 별점 읽어오기 (avgRating)
        self.rating = data["avgRating"] as? Double ?? 0.0
        
        self.imageURLs = data["imageURLs"] as? [String]
        self.distanceMeter = data["distanceMeter"] as? Int
        self.sizeType = data["sizeType"] as? String
        self.address = data["address"] as? String
        self.phone = data["phone"] as? String
        self.intro = data["intro"] as? String
        self.openTime = data["openTime"] as? String
        self.closeTime = data["closeTime"] as? String
        self.category = data["category"] as? String
        self.reviewCount = data["reviewCount"] as? Int ?? 0
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        
        // 🔥 Firestore 좌표 필드 읽기
        self.latitude = data["latitude"] as? Double
        self.longitude = data["longitude"] as? Double
        
        self.isAds = data["isAds"] as? Bool ?? false
        self.isNew = data["isNew"] as? Bool ?? false
        self.isRecommended = data["isRecommended"] as? Bool ?? false
    }
}
