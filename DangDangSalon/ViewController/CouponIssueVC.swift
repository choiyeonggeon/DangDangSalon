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
            title: "개별 발급",
            style: .done,
            target: self,
            action: #selector(issueSelectedCoupon)
        )
        
        let issueAllButton = UIBarButtonItem(
            title: "전체 발급",
            style: .done, target: self,
            action: #selector(issueToAllUsersTapped)
        )
        
        navigationItem.rightBarButtonItems = [issueAllButton, issueButton, createButton]
    }
    
    // MARK: - Batch Issue to All Users
    @objc private func issueToAllUsersTapped() {
        // 1. 선택된 쿠폰 확인
        guard let indexPath = tableView.indexPathForSelectedRow else {
            showAlert(title: "선택 오류", message: "전체 발급할 쿠폰을 리스트에서 선택해주세요.")
            return
        }
        
        let selectedCoupon = coupons[indexPath.row]
        
        // 2. 최종 확인 알림
        let alert = UIAlertController(
            title: "전체 발급 확인",
            message: "현재 불러온 모든 유저(\(users.count)명)에게\n'\(selectedCoupon.title)' 쿠폰을 발급하시겠습니까?",
            preferredStyle: .alert
        )
        
        alert.addAction(.init(title: "취소", style: .cancel))
        alert.addAction(.init(title: "발급 시작", style: .destructive) { _ in
            self.processBatchIssue(coupon: selectedCoupon)
        })
        
        present(alert, animated: true)
    }
    
    private func processBatchIssue(coupon: Coupon) {
        let batch = db.batch()
        let now = FieldValue.serverTimestamp()
        let group = DispatchGroup() // 비동기 작업 동기화를 위한 그룹
        
        var issuedCount = 0
        var skippedCount = 0
        
        // 로딩 인디케이터 등을 표시하면 좋습니다.
        print("중복 체크 및 발급 시작...")

        for user in users {
            group.enter()
            
            // 해당 유저의 쿠폰함에 동일한 제목의 쿠폰이 있는지 확인
            // (필요에 따라 couponId 필드를 추가하여 체크하는 것이 더 정확합니다)
            db.collection("users").document(user.id).collection("coupons")
                .whereField("title", isEqualTo: coupon.title)
                .whereField("isActive", isEqualTo: true)
                .getDocuments { snapshot, error in
                    defer { group.leave() }
                    
                    if let snapshot = snapshot, snapshot.isEmpty {
                        // 중복된 쿠폰이 없을 때만 배치에 추가
                        let userCouponRef = self.db.collection("users")
                            .document(user.id)
                            .collection("coupons")
                            .document()
                        
                        let data: [String: Any] = [
                            "originCouponId": coupon.id, // 중복 체크용 원본 ID 기록
                            "title": coupon.title,
                            "discountValue": coupon.discountValue,
                            "discountType": coupon.discountType,
                            "minPrice": coupon.minPrice,
                            "expiredAt": coupon.expiredAt,
                            "shopID": coupon.shopId,
                            "isActive": true,
                            "createdAt": now
                        ]
                        batch.setData(data, forDocument: userCouponRef)
                        issuedCount += 1
                    } else {
                        // 이미 가지고 있는 경우
                        skippedCount += 1
                    }
                }
        }
        
        // 모든 유저의 중복 체크가 끝나면 배치 커밋
        group.notify(queue: .main) {
            if issuedCount == 0 {
                self.showAlert(title: "알림", message: "모든 유저가 이미 이 쿠폰을 보유하고 있습니다.")
                return
            }
            
            batch.commit { error in
                if let error = error {
                    self.showAlert(title: "실패", message: error.localizedDescription)
                } else {
                    self.showAlert(title: "발급 완료",
                                 message: "\(issuedCount)명에게 발급 완료, \(skippedCount)명 중복 제외")
                }
            }
        }
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
        let alert = UIAlertController(title: "새 쿠폰 생성", message: "상세 정보를 입력하세요", preferredStyle: .alert)
        
        alert.addTextField { $0.placeholder = "쿠폰 제목" }
        alert.addTextField { $0.placeholder = "할인 (예: 5000원 또는 10%)" }
        alert.addTextField { $0.placeholder = "최소 주문 금액 (숫자만)" }
        alert.addTextField { $0.placeholder = "만료일 (yyyy.MM.dd)" }
        alert.addTextField { $0.placeholder = "샵 ID (전체는 all)" }

        alert.addAction(.init(title: "생성", style: .destructive) { _ in
            guard let title = alert.textFields?[0].text, !title.isEmpty,
                  let discountText = alert.textFields?[1].text,
                  let minPrice = Int(alert.textFields?[2].text ?? "0"),
                  let expiredDate = self.dateFromString(alert.textFields?[3].text ?? ""),
                  let shopId = alert.textFields?[4].text,
                  let discount = self.parseDiscount(discountText) else { return }
            
            let data: [String: Any] = [
                "title": title,
                "discountValue": discount.value,
                "discountType": discount.type,
                "minPrice": minPrice,
                "expiredAt": Timestamp(date: expiredDate),
                "shopID": shopId,
                "isActive": true
            ]
            
            self.db.collection("coupons").addDocument(data: data) { _ in self.fetchCoupons() }
        })
        
        present(alert, animated: true)
    }
    
    private func dateFromString(_ str: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy.MM.dd"   // ✅ 여기만 변경
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
        // ReservationVC의 Coupon 모델 구조에 맞게 데이터 구성
        let data: [String: Any] = [
            "title": coupon.title,            // 쿠폰 이름
            "discountValue": discount.value,  // 할인 값
            "discountType": discount.type,    // 할인 타입 (amount/percent)
            "minPrice": coupon.minPrice,      // 최소 주문 금액 (기존 쿠폰 정보 활용)
            "expiredAt": coupon.expiredAt,    // 만료일 (기존 쿠폰 정보 활용)
            "shopID": coupon.shopId,          // 특정 샵 ID 또는 "all"
            "isActive": true,                 // 발급 시 바로 활성화
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // 경로 통일: "myCoupons" -> "coupons"
        db.collection("users")
            .document(user.id)
            .collection("coupons") // ReservationVC에서 읽는 컬렉션명과 동일하게 변경
            .addDocument(data: data) { error in
                if let error = error {
                    self.showAlert(title: "오류", message: error.localizedDescription)
                } else {
                    self.showAlert(
                        title: "발급 완료",
                        message: "\(coupon.title)이(가)\n\(user.name ?? "유저")에게 발급되었습니다."
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
