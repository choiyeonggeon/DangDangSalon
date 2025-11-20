//
//  CustomerInquiryDetailVC.swift
//  DangSalon
//
//  Created by 최영건 on 10/31/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

final class CustomerInquiryDetailVC: UIViewController {
    
    var inquiry: CustomerInquiry?
    
    private let db = Firestore.firestore()
    
    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.font = .boldSystemFont(ofSize: 20)
        lb.numberOfLines = 0
        return lb
    }()
    
    private let dateLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 13)
        lb.textColor = .secondaryLabel
        return lb
    }()
    
    private let contentTitle: UILabel = {
        let lb = UILabel()
        lb.text = "문의 내용"
        lb.font = .systemFont(ofSize: 16)
        return lb
    }()
    
    private let contentLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 14)
        lb.numberOfLines = 0
        return lb
    }()
    
    private let answerTitle: UILabel = {
        let lb = UILabel()
        lb.text = "답변"
        lb.font = .systemFont(ofSize: 15)
        lb.textColor = .label
        return lb
    }()
    
    private let answerLabel: UILabel = {
        let lb = UILabel()
        lb.numberOfLines = 0
        lb.font = .systemFont(ofSize: 15)
        lb.textColor = .label
        return lb
    }()
    
    private let statusBadge: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 13, weight: .semibold)
        lb.textColor = .white
        lb.backgroundColor = .systemGray
        lb.textAlignment = .center
        lb.layer.cornerRadius = 6
        lb.clipsToBounds = true
        lb.setContentHuggingPriority(.required, for: .horizontal)
        lb.setContentCompressionResistancePriority(.required, for: .horizontal)
        return lb
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "문의 상세"
        
        setupLayout()
        configureUI()
        
        fetchLatestIfNeeded()
    }
    
    private func setupLayout() {
        let scroll = UIScrollView()
        let content = UIView()
        
        view.addSubview(scroll)
        scroll.addSubview(content)
        
        scroll.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        
        content.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.width.equalTo(scroll.snp.width)
        }
        
        [titleLabel, statusBadge, dateLabel,
         contentTitle, contentLabel,
         answerTitle, answerLabel].forEach { content.addSubview($0) }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.lessThanOrEqualTo(statusBadge.snp.leading).offset(-10)
        }
        
        statusBadge.snp.makeConstraints {
            $0.centerY.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(26)
            $0.width.greaterThanOrEqualTo(70)
        }
        
        dateLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.leading.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(20)
        }
        
        contentTitle.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(20)
            $0.leading.equalTo(titleLabel)
            $0.trailing.equalToSuperview().inset(20)
        }
        
        contentLabel.snp.makeConstraints {
            $0.top.equalTo(contentTitle.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        answerTitle.snp.makeConstraints {
            $0.top.equalTo(contentLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        answerLabel.snp.makeConstraints {
            $0.top.equalTo(answerTitle.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(30)
        }
        
    }
    
    private func configureUI() {
        guard let q = inquiry else { return }
        
        titleLabel.text = q.title
        contentLabel.text = q.content
        
        let df = DateFormatter()
        df.dateFormat = "yyyy.MM.dd HH:mm"
        dateLabel.text = "작성: " + df.string(from: q.createdAt)
        
        if let answer = q.answer, !answer.isEmpty {
            statusBadge.text = "답변 완료"
            statusBadge.backgroundColor = .systemBlue
            answerLabel.text = answer + (q.answeredAt != nil ? "\n\\n(df.string(from: q.answeredAt!)))" : "")
        } else {
            statusBadge.text = "대기 중"
            statusBadge.backgroundColor = .systemGray
            answerLabel.text = "아직 답변이 등록되지 않았어요."
            answerLabel.textColor = .secondaryLabel
        }
    }
    
    private func fetchLatestIfNeeded() {
        guard
            let uid = Auth.auth().currentUser?.uid,
            let inquiryId = inquiry?.id
        else { return }
        
        db.collection("users")
            .document(uid)
            .collection("customerInquiries")
            .document(inquiryId)
            .getDocument { [weak self] snap, _ in
                guard let self = self, let snap = snap,
                      let latest = CustomerInquiry(document: snap) else { return }
                self.inquiry = latest
                DispatchQueue.main.async { self.configureUI() }
            }
    }
}
