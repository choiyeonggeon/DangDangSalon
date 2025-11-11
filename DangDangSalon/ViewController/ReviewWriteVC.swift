//
//  ReviewWriteVC.swift
//  DangSalon
//
//  Created by 최영건 on 10/27/25.
//

import UIKit
import SnapKit
import FirebaseFirestore

final class ReviewWriteVC: UIViewController {
    
    // MARK: - Properties
    var shopId: String?
    var reservation: Reservation?
    var reservationPath: (userId: String, reservationId: String)?
    
    private let db = Firestore.firestore()
    
    // MARK: - UI
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "리뷰 작성"
        label.font = .boldSystemFont(ofSize: 22)
        label.textAlignment = .center
        return label
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.text = "별점을 선택해주세요."
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var starStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        for i in 1...5 {
            let button = UIButton(type: .system)
            button.tag = i
            button.setTitle("☆", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 36)
            button.tintColor = .black
            button.addTarget(self, action: #selector(starTapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
        return stack
    }()
    
    private var selectedRating: Int = 0 {
        didSet { updateStars() }
    }
    
    private let textView: UITextView = {
        let tv = UITextView()
        tv.text = "내용을 입력해주세요."
        tv.textColor = .lightGray
        tv.font = .systemFont(ofSize: 16)
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.layer.borderWidth = 1
        tv.layer.cornerRadius = 10
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return tv
    }()
    
    private let submitButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("등록하기", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.tintColor = .white
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.layer.cornerRadius = 10
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return btn
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        textView.delegate = self
        
        if let r = reservation {
            print("리뷰 작성 대상 샵:", r.shopName)
        }
        
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func starTapped(_ sender: UIButton) {
        selectedRating = sender.tag
    }
    
    @objc private func submitTapped() {
        guard let shopId = shopId else { return }
        guard selectedRating > 0 else {
            showAlert(title: "별점 선택", message: "별점을 선택해주세요.")
            return
        }
        
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text != "내용을 입력해주세요." else {
            showAlert(title: "내용 입력", message: "리뷰 내용을 입력해주세요.")
            return
        }
        
        let data: [String: Any] = [
            "nickname": "익명",
            "content": text,
            "rating": Double(selectedRating),
            "timestamp": Timestamp(date: Date())
        ]
        
        // 1) 리뷰 저장
        db.collection("shops").document(shopId)
            .collection("reviews")
            .addDocument(data: data) { error in
                if let error = error {
                    print("❌ 리뷰 저장 실패:", error.localizedDescription)
                    self.showAlert(title: "오류", message: "리뷰 저장 중 문제가 발생했습니다.")
                    return
                }
                
                print("✅ 리뷰 등록 성공")
                
                // 2) 예약 문서에 reviewWritten = true 기록
                if let path = self.reservationPath {
                    let reservationRef = self.db
                        .collection("users").document(path.userId)
                        .collection("reservations").document(path.reservationId)
                    
                    reservationRef.updateData([
                        "reviewWritten": true
                    ]) { err in
                        if let err = err {
                            print("⚠️ 예약 reviewWritten 업데이트 실패:", err.localizedDescription)
                        } else {
                            print("✅ 예약 reviewWritten = true 저장 완료")
                        }
                        
                        // 3) 목록 갱신 신호 보내기
                        NotificationCenter.default.post(name: .reviewWrittenForReservation, object: nil)
                        NotificationCenter.default.post(name: .reviewAdded, object: nil)
                        
                        self.dismiss(animated: true)
                    }
                } else {
                    // 예약 없이 그냥 리뷰만 쓰는 경우
                    NotificationCenter.default.post(name: .reviewAdded, object: nil)
                    self.dismiss(animated: true)
                }
            }
    }
    
    // MARK: - Helpers
    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [
            titleLabel, ratingLabel, starStackView, textView, submitButton
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        
        view.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        textView.snp.makeConstraints { $0.height.equalTo(150) }
    }
    
    private func updateStars() {
        for case let button as UIButton in starStackView.arrangedSubviews {
            button.setTitle(button.tag <= selectedRating ? "★" : "☆", for: .normal)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextViewDelegate
extension ReviewWriteVC: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = "내용을 입력해주세요."
            textView.textColor = .lightGray
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let reviewAdded = Notification.Name("reviewAdded")
    static let reviewWrittenForReservation = Notification.Name("reviewWrittenForReservation")
}
