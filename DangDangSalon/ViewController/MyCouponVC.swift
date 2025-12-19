//
//  MyCouponVC.swift
//  DangSalon
//
//  Created by 최영건 on 12/15/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

final class MyCouponVC: UIViewController {
    
    private let tableView = UITableView()
    private var coupons: [Coupon] = []
    private let db = Firestore.firestore()
    
    private let emptyLabel: UILabel = {
        let lb = UILabel()
        lb.text = "아직 보유한 쿠폰이 없어요. 🎟️"
        lb.textColor = .secondaryLabel
        lb.font = .systemFont(ofSize: 15)
        lb.textAlignment = .center
        lb.numberOfLines = 0
        lb.isHidden = true
        return lb
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchCoupons()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "내 쿠폰"
        
        tableView.register(CouponCell.self, forCellReuseIdentifier: "CouponCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        // ✅ 자동 높이 설정 (핵심)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(32)
        }
    }
    
    private func fetchCoupons() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(uid)
            .collection("myCoupons")
            .whereField("isUsed", isEqualTo: false)
            .getDocuments { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                
                let couponIds = docs.compactMap { $0["couponId"] as? String }
                
                if couponIds.isEmpty {
                    self.coupons = []
                    self.tableView.reloadData()
                    self.showEmptyMessage()
                    return
                }
                
                self.db.collection("coupons")
                    .whereField(FieldPath.documentID(), in: couponIds)
                    .getDocuments { snap, _ in
                        self.coupons = snap?.documents.compactMap { Coupon(doc: $0) } ?? []
                        self.tableView.reloadData()
                        
                        self.coupons.isEmpty
                        ? self.showEmptyMessage()
                        : self.hideEmptyMessage()
                    }
            }
    }
    
    private func showEmptyMessage() {
        let lb = UILabel()
        lb.text = "쿠폰이 아직 없어요. 🎟️"
        lb.textColor = .secondaryLabel
        lb.textAlignment = .center
        lb.font = .systemFont(ofSize: 15, weight: .medium)
        lb.numberOfLines = 0
        
        tableView.backgroundView = lb
    }
    
    private func hideEmptyMessage() {
        tableView.backgroundView = nil
    }
}

extension MyCouponVC: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return coupons.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "CouponCell",
            for: indexPath
        ) as? CouponCell else {
            return UITableViewCell()
        }
        
        let coupon = coupons[indexPath.row]
        cell.configure(coupon: coupon)
        return cell
    }
}

// ✅ heightForRowAt 제거
extension MyCouponVC: UITableViewDelegate {}
