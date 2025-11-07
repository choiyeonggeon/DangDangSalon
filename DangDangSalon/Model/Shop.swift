//
//  Shop.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/16/25.
//

import Foundation
import FirebaseFirestore

struct Shop {
    let id: String
    let name: String
    let rating: Double
    let imageURLs: [String]?
    let isRecommended: Bool
    var distanceMeter: Int?
    let sizeType: String?
    let address: String?
    let phone: String?
    let intro: String?
    let openTime: String?
    let closeTime: String?
    
    init?(document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        
        guard let name = data["name"] as? String,
              let rating = data["rating"] as? Double else {
            return nil
        }
        self.id = document.documentID
        self.name = name
        self.rating = data["rating"] as? Double ?? 0.0
        self.imageURLs = data["imageURLs"] as? [String]
        self.isRecommended = data["isRecommended"] as? Bool ?? false
        self.distanceMeter = data["distanceMeter"] as? Int
        self.sizeType = data["sizeType"] as? String
        self.address = data["address"] as? String
        self.phone = data["phone"] as? String
        self.intro = data["intro"] as? String
        self.openTime = data["openTime"] as? String
        self.closeTime = data["closeTime"] as? String
    }
}
