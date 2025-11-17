//
//  CustomerInquiryWriteVC.swift
//  DangSalon
//
//  Created by 최영건 on 10/31/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

extension Notification.Name {
    static let inquirySubmitted = Notification.Name("inquirySubmitted")
}

final class CustomerInquiryWriteVC: UIViewController {
        
    // MARK: - UI
    private let titleField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "제목을 입력하세요."
        tf.borderStyle = .roundedRect
        tf.font = .systemFont(ofSize: 16)
        return tf
    }()
    
    private let contentTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 15)
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.layer.borderWidth = 1
        tv.layer.cornerRadius = 8
        tv.textColor = .secondaryLabel
        tv.text = "문의 내용을 입력해주세요"
        return tv
    }()
    
    private let sendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("보내기", for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 17)
        btn.backgroundColor = .systemBlue
        btn.tintColor = .white
        btn.layer.cornerRadius = 12
        return btn
    }()
    
    private let db = Firestore.firestore()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "문의 작성"
        
        setupLayout()
        setupActions()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Layout
    private func setupLayout() {
        [titleField, contentTextView, sendButton].forEach { view.addSubview($0) }
        
        titleField.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }
        
        contentTextView.snp.makeConstraints {
            $0.top.equalTo(titleField.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(150)
        }
        
        sendButton.snp.makeConstraints {
            $0.top.equalTo(contentTextView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
        }
    }
    
    // MARK: - Actions
    private func setupActions() {
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        contentTextView.delegate = self
    }
    
    @objc private func sendTapped() {
        guard let userId = Auth.auth().currentUser?.uid else {
            showAlert(title: "로그인 필요", message: "로그인 후 문의를 작성할 수 있습니다.")
            return
        }
        
        guard let title = titleField.text, !title.isEmpty,
              let content = contentTextView.text, !content.isEmpty,
              content != "문의 내용을 입력해주세요." else {
            showAlert(title: "입력 오류", message: "제목과 내용을 모두 입력해주세요.")
            return
        }
        let inquiryData: [String: Any] = [
            "title": title,
            "content": content,
            "createdAt": Timestamp(date: Date()),
            "answer": NSNull(),
            "answeredAt": NSNull()
        ]
        
        db.collection("users")
            .document(userId)
            .collection("customerInquiries")
            .addDocument(data: inquiryData) { [weak self] error in
                if let error = error {
                    self?.showAlert(title: "오류", message: "문의 전송 실패: \(error.localizedDescription)")
                    return
                }
                
                NotificationCenter.default.post(name: .inquirySubmitted, object: nil)
                
                self?.showAlert(title: "문의 완료", message: "문의가 정상적으로 전송되었습니다.\n관리자가 24시간 내에 확인 후 답변드리겠습니다.") {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UITextViewDelegate (placeholder 구현)
extension CustomerInquiryWriteVC: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .secondaryLabel {
            textView.text = nil
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = "문의 내용을 입력해주세요."
            textView.textColor = .secondaryLabel
        }
    }
}
