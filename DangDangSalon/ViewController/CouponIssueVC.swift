//
//  CouponIssueVC.swift
//  DangSalon
//
//  Created by 최영건 on 12/19/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

final class CouponIssueVC: UIViewController {
    
    // MARK: - UI
    private let tableView = UITableView()
    private var coupons: [Coupon] = []
    private var users: [User] = []
    
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "쿠폰 발급"
        
        tableView.register(CouponCell.self, forCellReuseIdentifier: "CouponCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        setupNavigationBar()
        fetchCoupons()
        fetchUsers()
    }
    
    // MARK: - Navigation Bar
    private func setupNavigationBar() {
        let createButton = UIBarButtonItem(
            title: "새 쿠폰",
            style: .plain,
            target: self,
            action: #selector(createCouponTapped)
        )
        
        let issueButton = UIBarButtonItem(
            title: "발급",
            style: .done,
            target: self,
            action: #selector(issueSelectedCoupon)
        )
        
        navigationItem.rightBarButtonItems = [issueButton, createButton]
    }
    
    // MARK: - Fetch Coupons
    private func fetchCoupons() {
        db.collection("coupons")
            .order(by: "expiredAt", descending: false)
            .getDocuments { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                self.coupons = docs.compactMap { Coupon(doc: $0) }
                self.tableView.reloadData()
            }
    }
    
    private func fetchUsers() {
        db.collection("users")
            .getDocuments { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                self.users = docs.compactMap {
                    guard let name = $0["name"] as? String else { return nil }
                    return User(id: $0.documentID, name: name)
                }
            }
    }
    
    // MARK: - Create Coupon
    @objc private func createCouponTapped() {
        let alert = UIAlertController(
            title: "새 쿠폰 생성",
            message: "제목 / 할인 / 만료일",
            preferredStyle: .alert
        )
        
        alert.addTextField { $0.placeholder = "쿠폰 제목" }
        alert.addTextField { $0.placeholder = "예: 5000원 또는 10%" }
        alert.addTextField { $0.placeholder = "만료일 (yyyy-MM-dd)" }
        
        alert.addAction(.init(title: "취소", style: .cancel))
        alert.addAction(.init(title: "생성", style: .destructive) { _ in
            guard
                let title = alert.textFields?[0].text, !title.isEmpty,
                let discountText = alert.textFields?[1].text,
                let expiredAt = self.dateFromString(alert.textFields?[2].text ?? ""),
                let discount = self.parseDiscount(discountText)
            else { return }
            
            let data: [String: Any] = [
                "title": title,
                "discountValue": discount.value,
                "discountType": discount.type,
                "expiredAt": Timestamp(date: expiredAt)
            ]
            
            self.db.collection("coupons").addDocument(data: data) { error in
                if error == nil {
                    self.fetchCoupons()
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func dateFromString(_ str: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: str)
    }
    
    // MARK: - Coupon Issue Flow
    @objc private func issueSelectedCoupon() {
        guard let indexPath = tableView.indexPathForSelectedRow else {
            showAlert(title: "선택 오류", message: "쿠폰을 먼저 선택해주세요.")
            return
        }
        
        let coupon = coupons[indexPath.row]
        
        let alert = UIAlertController(
            title: "유저 선택",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        users.forEach { user in
            let name = user.name ?? "이름 없음"
            alert.addAction(.init(title: name, style: .default) { _ in
                self.showDiscountInput(coupon: coupon, user: user)
            })
        }
        
        alert.addAction(.init(title: "취소", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.first
        }
        
        present(alert, animated: true)
    }
    
    private func showDiscountInput(coupon: Coupon, user: User) {
        let alert = UIAlertController(
            title: "할인 입력",
            message: "예: 5000원 또는 10%",
            preferredStyle: .alert
        )
        
        alert.addTextField { $0.placeholder = "할인 입력" }
        
        alert.addAction(.init(title: "취소", style: .cancel))
        alert.addAction(.init(title: "발급", style: .default) { _ in
            let text = alert.textFields?.first?.text ?? ""
            guard let discount = self.parseDiscount(text) else {
                self.showAlert(title: "입력 오류", message: "할인을 올바르게 입력하세요.")
                return
            }
            self.issueCoupon(coupon, to: user, discount: discount)
        })
        
        present(alert, animated: true)
    }
    
    private func issueCoupon(
        _ coupon: Coupon,
        to user: User,
        discount: (value: Int, type: String)
    ) {
        let data: [String: Any] = [
            "couponId": coupon.id,
            "isUsed": false,
            "discountValue": discount.value,
            "discountType": discount.type,
            "createdAt": Timestamp()
        ]
        
        db.collection("users")
            .document(user.id)
            .collection("myCoupons")
            .addDocument(data: data) { error in
                if let error = error {
                    self.showAlert(title: "오류", message: error.localizedDescription)
                } else {
                    self.showAlert(
                        title: "발급 완료",
                        message: "\(coupon.title)\n\(user.name ?? "유저")에게 발급됨"
                    )
                }
            }
    }
    
    // MARK: - Utils
    private func parseDiscount(_ text: String) -> (value: Int, type: String)? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        let value = Int(
            trimmed
                .replacingOccurrences(of: "원", with: "")
                .replacingOccurrences(of: "%", with: "")
        ) ?? 0
        
        let type = trimmed.contains("%") ? "percent" : "amount"
        return (value, type)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TableView
extension CouponIssueVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        coupons.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "CouponCell",
            for: indexPath
        ) as! CouponCell
        
        cell.configure(coupon: coupons[indexPath.row])
        return cell
    }
    
    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        80
    }
}
