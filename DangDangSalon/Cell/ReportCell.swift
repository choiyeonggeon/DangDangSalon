//
//  ReportCell.swift
//  DangSalon
//
//  Created by 최영건 on 11/18/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

final class ReportCell: UITableViewCell {
    
    private let reasonLabel = UILabel()
    private let infoLabel = UILabel()
    private let dateLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = .systemBackground
        
        reasonLabel.font = .boldSystemFont(ofSize: 16)
        reasonLabel.numberOfLines = 0
        
        infoLabel.font = .systemFont(ofSize: 14)
        infoLabel.textColor = .darkGray
        infoLabel.numberOfLines = 0
        
        dateLabel.font = .systemFont(ofSize: 13)
        dateLabel.textColor = .gray
        
        [reasonLabel, infoLabel, dateLabel]
            .forEach { contentView.addSubview($0) }
        
        reasonLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(12)
        }
        
        infoLabel.snp.makeConstraints {
            $0.top.equalTo(reasonLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(12)
        }
        
        dateLabel.snp.makeConstraints {
            $0.top.equalTo(infoLabel.snp.bottom).offset(4)
            $0.leading.trailing.bottom.equalToSuperview().inset(12)
        }
    }
}

// MARK: - 공통 렌더링 헬퍼
private extension ReportCell {
    func applyUI(reason: String,
                 info: String,
                 date: Date?) {
        reasonLabel.text = "사유: \(reason)"
        infoLabel.text = info
        
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy.MM.dd HH:mm"
            dateLabel.text = formatter.string(from: date)
        } else {
            dateLabel.text = "-"
        }
    }
}

// MARK: - 딕셔너리(Firestore raw)용
extension ReportCell {
    
    /// Firestore `document.data()` 그대로 넘길 때 사용
    func configure(with data: [String: Any]) {
        let reason = data["reason"] as? String ?? "-"
        
        let reservationId = data["reservationId"] as? String
        let reviewId      = data["reviewId"]      as? String
        let targetOwnerId = data["targetOwnerId"] as? String
        let targetUserId  = data["targetUserId"]  as? String
        let reporterId    = data["reporterId"]    as? String
        
        var infoText = "신고 정보 없음"
        
        if let reviewId = reviewId {
            infoText = "리뷰ID: \(reviewId) | 사장ID: \(targetOwnerId ?? "-")"
        } else if let reservationId = reservationId {
            infoText = "예약ID: \(reservationId) | 신고자: \(reporterId ?? "-")"
        } else if let targetUserId = targetUserId {
            infoText = "대상 사용자: \(targetUserId) | 신고자: \(reporterId ?? "-")"
        } else if let ownerId = targetOwnerId {
            infoText = "대상 사장님: \(ownerId) | 신고자: \(reporterId ?? "-")"
        }
        
        let ts = data["createdAt"] as? Timestamp
        let date = ts?.dateValue()
        
        applyUI(reason: reason, info: infoText, date: date)
    }
}

// MARK: - 모델 타입별 configure (기존 화면들용)
extension ReportCell {
    
    func configure(with report: ReviewReport) {
        applyUI(
            reason: report.reason,
            info: "리뷰ID: \(report.reviewId) | 샵ID: \(report.shopId)",
            date: report.createdAt
        )
    }
    
    func configure(with report: ReservationReport) {
        applyUI(
            reason: report.reason,
            info: "예약ID: \(report.reservationId) | 신고자: \(report.reporterId)",
            date: report.createdAt
        )
    }
    
    func configure(with report: UserReport) {
        applyUI(
            reason: report.reason,
            info: "대상 사용자: \(report.targetUserId) | 신고자: \(report.reporterId)",
            date: report.createdAt
        )
    }
    
    func configure(with report: OwnerReport) {
        applyUI(
            reason: report.reason,
            info: "대상 사장님: \(report.targetOwnerId) | 신고자: \(report.reporterId)",
            date: report.createdAt
        )
    }
}
