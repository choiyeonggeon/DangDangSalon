//
//  AdminReservationReportDetailVC.swift
//  DangSalon
//
//  Created by 최영건 on 11/20/25.
//

import UIKit
import SnapKit
import FirebaseFirestore

final class AdminReservationReportDetailVC: UIViewController {
    
    var reportData: [String: Any]?
    private let db = Firestore.firestore()
    
    private let shopLabel = UILabel()       // ⭐ 샵 이름
    private let reasonLabel = UILabel()
    private let ownerLabel = UILabel()
    private let userLabel = UILabel()
    
    private let statusButton = UIButton(type: .system)
    private let suspendOwnerButton = UIButton(type: .system)
    private let suspendUserButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "예약 신고 상세"
        
        setupUI()
        fillData()
    }
    
    private func setupUI() {
        
        shopLabel.font = .boldSystemFont(ofSize: 18)
        shopLabel.numberOfLines = 0
        shopLabel.textColor = .systemBlue
        
        reasonLabel.font = .systemFont(ofSize: 16, weight: .medium)
        reasonLabel.numberOfLines = 0
        
        ownerLabel.font = .systemFont(ofSize: 15)
        userLabel.font = .systemFont(ofSize: 15)
        
        statusButton.setTitle("처리 완료", for: .normal)
        statusButton.backgroundColor = .systemRed
        statusButton.setTitleColor(.white, for: .normal)
        statusButton.layer.cornerRadius = 10
        statusButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        statusButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        statusButton.addTarget(self, action: #selector(markProcessed), for: .touchUpInside)
        
        suspendOwnerButton.setTitle("🚫 신고 대상(사장) 정지", for: .normal)
        suspendOwnerButton.backgroundColor = .systemBlue
        suspendOwnerButton.setTitleColor(.white, for: .normal)
        suspendOwnerButton.layer.cornerRadius = 10
        suspendOwnerButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        suspendOwnerButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        suspendOwnerButton.addTarget(self, action: #selector(suspendOwner), for: .touchUpInside)
        
        suspendUserButton.setTitle("⛔ 신고자(사용자) 정지", for: .normal)
        suspendUserButton.backgroundColor = .systemOrange
        suspendUserButton.setTitleColor(.white, for: .normal)
        suspendUserButton.layer.cornerRadius = 10
        suspendUserButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        suspendUserButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        suspendUserButton.addTarget(self, action: #selector(suspendUser), for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [
            shopLabel,          // ⭐ 맨위에 샵 이름
            userLabel,          // 신고자
            reasonLabel,        // 사유
            ownerLabel,         // 사장
            statusButton,
            suspendOwnerButton,
            suspendUserButton
        ])
        
        stack.axis = .vertical
        stack.spacing = 20
        
        view.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.trailing.equalTo(view.safeAreaLayoutGuide).offset(-20)
        }
    }
    
    private func fillData() {
        guard let d = reportData else { return }
        
        let shopName = d["name"] as? String ?? "알 수 없음"
        let reason = d["reason"] as? String ?? "-"
        let ownerId = d["targetOwnerId"] as? String ?? "-"
        let userId = d["reporterId"] as? String ?? "-"
        
        shopLabel.text = "🏪 샵 이름: \(shopName)"
        reasonLabel.text = "🚨 신고 사유\n\(reason)"
        ownerLabel.text = "📌 신고 대상(사장): \(ownerId)"
        userLabel.text = "👤 신고자(사용자): \(userId)"
    }
    
    // MARK: - 처리 완료
    @objc private func markProcessed() {
        guard let id = reportData?["reportId"] as? String else { return }
        
        db.collection("reservationReports")
            .document(id)
            .updateData(["status": "processed"]) { err in
                if let err = err {
                    print("오류:", err.localizedDescription)
                    return
                }
                self.navigationController?.popViewController(animated: true)
            }
    }
    
    // MARK: - 사장 정지
    @objc private func suspendOwner() {
        guard let ownerId = reportData?["targetOwnerId"] as? String else { return }
        showSuspendAlert(targetId: ownerId, collection: "owners", targetName: "사장")
    }
    
    // MARK: - 사용자 정지
    @objc private func suspendUser() {
        guard let userId = reportData?["reporterId"] as? String else { return }
        showSuspendAlert(targetId: userId, collection: "users", targetName: "사용자")
    }
    
    // MARK: - 정지 공통 로직
    private func showSuspendAlert(targetId: String, collection: String, targetName: String) {
        
        let alert = UIAlertController(
            title: "\(targetName) 정지",
            message: "정지 일 수를 입력해주세요.\n예: 3, 7, 30",
            preferredStyle: .alert
        )
        
        alert.addTextField { tf in
            tf.placeholder = "정지 일 수"
            tf.keyboardType = .numberPad
        }
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "정지하기", style: .destructive, handler: { _ in
            
            let daysText = alert.textFields?.first?.text ?? ""
            guard let days = Int(daysText), days > 0 else {
                self.showAlert(title: "입력 오류", message: "유효한 숫자를 입력해주세요.")
                return
            }
            
            let until = Date().addingTimeInterval(Double(days) * 86400)
            
            self.db.collection(collection)
                .document(targetId)
                .setData(["suspendedUntil": Timestamp(date: until)], merge: true) { error in
                    
                    if let error = error {
                        self.showAlert(title: "오류", message: error.localizedDescription)
                        return
                    }
                    
                    self.showAlert(
                        title: "정지 완료",
                        message: "\(targetName)을(를) \(days)일 동안 정지했습니다."
                    )
                }
        }))
        
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "확인", style: .default))
        present(a, animated: true)
    }
}
