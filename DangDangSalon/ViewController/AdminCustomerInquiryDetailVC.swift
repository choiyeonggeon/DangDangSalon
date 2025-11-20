//
//  AdminCustomerInquiryDetailVC.swift
//  DangSalon
//

import UIKit
import SnapKit
import FirebaseFirestore

final class AdminCustomerInquiryDetailVC: UIViewController {
    
    private let inquiry: AdminInquiry
    private let db = Firestore.firestore()
    
    // MARK: - UI 요소
    private let userLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 17)
        label.textColor = .label
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 20)
        label.numberOfLines = 0
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    private let answerField: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 15)
        tv.layer.cornerRadius = 10
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.backgroundColor = UIColor.systemGray6
        return tv
    }()
    
    private let sendButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("답변 등록", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.tintColor = .white
        btn.layer.cornerRadius = 12
        btn.titleLabel?.font = .boldSystemFont(ofSize: 17)
        btn.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return btn
    }()
    
    // MARK: - Init
    init(inquiry: AdminInquiry) {
        self.inquiry = inquiry
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "문의 상세"
        
        setupUI()
        fillData()
        dateLabel.text = formatKoreanDate(inquiry.createdAt)
    }
    
    // MARK: - UI 구성
    private func setupUI() {
        [userLabel, dateLabel, titleLabel, contentLabel, answerField, sendButton].forEach {
            view.addSubview($0)
        }
        
        userLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        dateLabel.snp.makeConstraints {
            $0.top.equalTo(userLabel.snp.bottom).offset(2)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(18)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        contentLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        answerField.snp.makeConstraints {
            $0.top.equalTo(contentLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(160)
        }
        
        sendButton.snp.makeConstraints {
            $0.top.equalTo(answerField.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        sendButton.addTarget(self, action: #selector(saveAnswer), for: .touchUpInside)
    }
    
    // MARK: - 데이터 적용
    private func fillData() {
        userLabel.text = "작성자: \(inquiry.nickname)"
        
        dateLabel.text = DateFormatter.localizedString(
            from: inquiry.createdAt,
            dateStyle: .medium,
            timeStyle: .short
        )
        
        titleLabel.text = inquiry.title
        contentLabel.text = inquiry.content
        
        answerField.text = inquiry.answer ?? ""
        
        // 이미 답변 완료된 문의는 버튼 문구 변경
        if inquiry.answer != nil {
            sendButton.setTitle("답변 수정", for: .normal)
        }
    }
    
    func formatKoreanDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")  // 한국어 강제
        formatter.dateFormat = "yyyy년 MM월 dd일 (E) HH:mm"
        return formatter.string(from: date)
    }
    
    // MARK: - Firestore 저장
    @objc private func saveAnswer() {
        let text = answerField.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if text.isEmpty {
            let alert = UIAlertController(
                title: "입력 필요",
                message: "답변 내용을 입력해주세요.",
                preferredStyle: .alert
            )
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
            
            let alert = UIAlertController(
                title: "완료",
                message: "답변이 저장되었습니다.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(alert, animated: true)
        }
    }
}
