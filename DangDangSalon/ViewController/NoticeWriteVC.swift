//
//  NoticeWriteVC.swift
//  DangSalon
//
//  Created by 최영건 on 11/13/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

final class NoticeWriteVC: UIViewController {
    
    private let db = Firestore.firestore()
    
    private let titleField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "제목을 입력해주세요."
        tf.borderStyle = .roundedRect
        tf.font = .systemFont(ofSize: 16)
        tf.autocapitalizationType = .none
        return tf
    }()
    
    private let contentTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 15)
        tv.text = "내용을 입력해주세요."
        tv.textColor = .systemGray3
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.layer.cornerRadius = 10
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        return tv
    }()
    
    private let submitButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("등록하기", for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        title = "공지사항 작성"
        setupUI()
        setupAction()
        contentTextView.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupUI() {
        [titleField, contentTextView, submitButton].forEach {
            view.addSubview($0)
        }
        
        titleField.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }
        
        contentTextView.snp.makeConstraints {
            $0.top.equalTo(titleField.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(250)
        }
        
        submitButton.snp.makeConstraints {
            $0.top.equalTo(contentTextView.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
        }
    }
    
    private func setupAction() {
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
    }
    
    @objc private func submitTapped() {
        guard let title = titleField.text, !title.isEmpty else {
            showAlert(title: "입력 오류", message: "제목을 입력해주세요.")
            return
        }
        
        let content = contentTextView.textColor == .systemGray3 ? "" : contentTextView.text
        
        guard let contentText = content, !contentText.isEmpty else {
            showAlert(title: "입력 오류", message: "내용을 입력하세요.")
            return
        }
        
        guard let adminId = Auth.auth().currentUser?.uid else {
            showAlert(title: "오류", message: "로그인 상태를 확인해주세요.")
            return
        }
        
        let noticeId = UUID().uuidString
        let data: [String: Any] = [
            "id": noticeId,
            "title": title,
            "content": contentText,
            "createdAt": Timestamp(date: Date()),
            "adminId": adminId
        ]
        
        db.collection("notices").document(noticeId).setData(data) { [weak self] err in
            if let err = err {
                self?.showAlert(title: "등록 실패", message: err.localizedDescription)
                return
            }
            
            self?.showAlert(title: "완료", message: "공지사항이 등록되었습니다.") {
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension NoticeWriteVC: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .systemGray3 {
            textView.text = ""
            textView.textColor = .label
        }
    }
}

