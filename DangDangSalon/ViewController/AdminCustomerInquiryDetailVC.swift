//
//  AdminCustomerInquiryDetailVC.swift
//  DangSalon
//
//  Created by 최영건 on 11/17/25.
//

import UIKit
import SnapKit
import FirebaseFirestore

final class AdminCustomerInquiryDetailVC: UIViewController {
    
    private let inquiry: AdminInquiry
    private let db = Firestore.firestore()
    
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()
    private let answerField = UITextView()
    private let sendButton = UIButton(type: .system)
    
    init(inquiry: AdminInquiry) {
        self.inquiry = inquiry
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        title = "문의 상세"
        
        setupUI()
        fillData()
    }
    
    private func setupUI() {
        titleLabel.font = .boldSystemFont(ofSize: 20)
        titleLabel.numberOfLines = 0
        
        contentLabel.font = .systemFont(ofSize: 16)
        contentLabel.numberOfLines = 0
        
        answerField.font = .systemFont(ofSize: 15)
        answerField.layer.cornerRadius = 10
        answerField.layer.borderWidth = 1
        answerField.layer.borderColor = UIColor.gray.cgColor
        answerField.text = inquiry.answer ?? ""
        
        sendButton.setTitle("답변하기", for: .normal)
        sendButton.layer.cornerRadius = 10
        sendButton.backgroundColor = .systemBlue
        sendButton.tintColor = .white
        sendButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        sendButton.addTarget(self, action: #selector(saveAnswer), for: .touchUpInside)
        
        view.addSubview(titleLabel)
        view.addSubview(contentLabel)
        view.addSubview(answerField)
        view.addSubview(sendButton)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        contentLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        answerField.snp.makeConstraints {
            $0.top.equalTo(contentLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(150)
        }
        
        sendButton.snp.makeConstraints {
            $0.top.equalTo(answerField.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
    }
    
    private func fillData() {
        titleLabel.text = inquiry.title
        contentLabel.text = inquiry.content
    }
    
    @objc private func saveAnswer() {
        let text = answerField.text ?? ""
        
        if text.isEmpty {
            let alert = UIAlertController(title: "입력 필요", message: "답변 내용을 입력해주세요.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }
        
        let ref = db.collection("users")
            .document(inquiry.userId)
            .collection("customerInquiries")
            .document(inquiry.id)
        
        ref.updateData([
            "answer": text,
            "answeredAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("❌ 답변 저장 실패:", error.localizedDescription)
                return
            }
            self.navigationController?.popViewController(animated: true)
        }
    }
}
