//
//  Pet.swift
//  DangSalon
//
//  Created by 최영건 on 11/23/25.
//

import Foundation
import FirebaseFirestore

struct Pet {
    let id: String
    let name: String
    let breed: String
    let weight: String
    let age: String
    let photoURL: String?
    let memo: String?
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.name = data["name"] as? String ?? ""
        self.breed = data["breed"] as? String ?? ""
        // Int 값을 String으로 변환
        if let weightInt = data["weight"] as? Int {
            self.weight = "\(weightInt)"
        } else if let weightStr = data["weight"] as? String {
            self.weight = weightStr
        } else {
            self.weight = ""
        }
        self.age = data["age"] as? String ?? ""
        self.photoURL = data["photoURL"] as? String
        self.memo = data["memo"] as? String
    }
    
    func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "breed": breed,
            "weight": weight,
            "age": age,
            "memo": memo ?? "",
            "createdAt": Timestamp()
        ]
        
        if let photoURL = photoURL {
            dict["photoURL"] = photoURL
        }
        
        return dict
    }
}
