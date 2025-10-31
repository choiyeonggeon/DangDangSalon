//
//  CustomerInquiryDetailVC.swift
//  DangSalon
//
//  Created by 최영건 on 10/31/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

final class CustomerInquiryDetailVC: UIViewController {
    
    var inquiry: CustomerInquiry?
    
    private let db = Firestore.firestore()
    
    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.font = .boldSystemFont(ofSize: 20)
        lb.numberOfLines = 0
        return lb
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}
