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
    let weight: Int
    let age: Int
    let photoURL: String?
    let memo: String?
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.name = data["name"] as? String ?? ""
        self.breed = data["breed"] as? String ?? ""
        self.weight = data["weight"] as? Int ?? 0
        self.age = data["age"] as? Int ?? 0
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
