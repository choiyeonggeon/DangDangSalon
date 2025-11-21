//
//  AdminReviewReportDetailVC.swift
//  DangSalon
//
//  Created by 최영건 on 11/18/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

final class AdminReviewReportDetailVC: UIViewController {
    
    private let report: ReviewReport
    private let db = Firestore.firestore()
    
    // UI
    private let reasonLabel = UILabel()
    private let reviewContentLabel = UILabel()
    private let infoLabel = UILabel()
    
    private let deleteButton = UIButton(type: .system)
    private let blindButton = UIButton(type: .system)
    
    init(report: ReviewReport) {
        self.report = report
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        title = "신고 상세"
        setupUI()
        fetchReviewDetail()
    }
    
    // MARK: - UI 구성
    private func setupUI() {
        reasonLabel.font = .boldSystemFont(ofSize: 20)
        reasonLabel.numberOfLines = 0
        
        reviewContentLabel.font = .systemFont(ofSize: 16)
        reviewContentLabel.numberOfLines = 0
        
        infoLabel.font = .systemFont(ofSize: 14)
        infoLabel.textColor = .secondaryLabel
        infoLabel.numberOfLines = 0
        
        // 삭제 버튼
        deleteButton.setTitle("🚨 리뷰 삭제하기", for: .normal)
        deleteButton.setTitleColor(.white, for: .normal)
        deleteButton.backgroundColor = .systemRed
        deleteButton.layer.cornerRadius = 10
        deleteButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        deleteButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        deleteButton.addTarget(self, action: #selector(deleteReview), for: .touchUpInside)
        
        // 블라인드 버튼
        blindButton.setTitle("🙈 30일 블라인드 처리", for: .normal)
        blindButton.setTitleColor(.white, for: .normal)
        blindButton.backgroundColor = .systemOrange
        blindButton.layer.cornerRadius = 10
        blindButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        blindButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        blindButton.addTarget(self, action: #selector(blindReview), for: .touchUpInside)
        
        [reasonLabel, reviewContentLabel, infoLabel, blindButton, deleteButton]
            .forEach { view.addSubview($0) }
        
        reasonLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        reviewContentLabel.snp.makeConstraints {
            $0.top.equalTo(reasonLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        infoLabel.snp.makeConstraints {
            $0.top.equalTo(reviewContentLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        blindButton.snp.makeConstraints {
            $0.top.equalTo(infoLabel.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
        }
        
        deleteButton.snp.makeConstraints {
            $0.top.equalTo(blindButton.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
        }
        
        reasonLabel.text = "🚨 신고 사유\n\(report.reason)"
    }
    
    // MARK: - 리뷰 상세 불러오기
    private func fetchReviewDetail() {
        db.collection("shops")
            .document(report.shopId)
            .collection("reviews")
            .document(report.reviewId)
            .getDocument { [weak self] snap, err in
                
                guard let self = self else { return }
                
                if let err = err {
                    print("리뷰 조회 실패:", err.localizedDescription)
                    return
                }
                
                guard let data = snap?.data() else {
                    self.reviewContentLabel.text = "리뷰 데이터를 찾을 수 없습니다."
                    return
                }
                
                let content = data["content"] as? String ?? "(내용 없음)"
                let nickname = data["nickname"] as? String ?? "(익명)"
                let timestamp = (data["timestamp"] as? Timestamp)?.dateValue().description ?? "(시간 없음)"
                
                DispatchQueue.main.async {
                    self.reviewContentLabel.text = "📝 리뷰 내용\n\(content)"
                    
                    self.infoLabel.text = """
                    🔹 작성자: \(nickname)
                    🔹 작성 시간: \(timestamp)
                    🔹 Shop ID: \(self.report.shopId)
                    🔹 Review ID: \(self.report.reviewId)
                    🔹 신고자 UID: \(self.report.reporterUid)
                    """
                }
            }
    }
    
    // MARK: - 리뷰 삭제
    @objc private func deleteReview() {
        let alert = UIAlertController(
            title: "정말 삭제할까요?",
            message: "리뷰 삭제 후 복구가 불가능합니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive, handler: { _ in
            self.db.collection("shops")
                .document(self.report.shopId)
                .collection("reviews")
                .document(self.report.reviewId)
                .delete { err in
                    if let err = err {
                        print("❌ 리뷰 삭제 실패:", err.localizedDescription)
                        return
                    }
                    print("✅ 리뷰 삭제 완료")
                    
                    let done = UIAlertController(
                        title: "삭제 완료",
                        message: "리뷰가 성공적으로 삭제되었습니다.",
                        preferredStyle: .alert
                    )
                    done.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
                        self.navigationController?.popViewController(animated: true)
                    }))
                    
                    self.present(done, animated: true)
                }
        }))
        
        present(alert, animated: true)
    }
    
    
    // MARK: - ✔ 30일 블라인드 처리
    @objc private func blindReview() {
        let alert = UIAlertController(
            title: "30일 블라인드 처리",
            message: "이 리뷰는 30일 동안 소비자에게 보이지 않습니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "블라인드", style: .destructive, handler: { _ in
            
            let untilDate = Date().addingTimeInterval(60 * 60 * 24 * 30) // 30일
            
            let data: [String: Any] = [
                "isBlinded": true,
                "blindedUntil": Timestamp(date: untilDate)
            ]
            
            self.db.collection("shops")
                .document(self.report.shopId)
                .collection("reviews")
                .document(self.report.reviewId)
                .setData(data, merge: true) { err in
                    if let err = err {
                        print("❌ 블라인드 실패:", err.localizedDescription)
                        return
                    }
                    
                    print("✅ 블라인드 처리 완료")
                    
                    let done = UIAlertController(
                        title: "블라인드 완료",
                        message: "이 리뷰는 30일 동안 숨김 처리됩니다.",
                        preferredStyle: .alert
                    )
                    done.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
                        self.navigationController?.popViewController(animated: true)
                    }))
                    
                    self.present(done, animated: true)
                }
        }))
        
        present(alert, animated: true)
    }
}
