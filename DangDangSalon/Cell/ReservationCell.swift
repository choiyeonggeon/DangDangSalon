//
//  ReservationCell.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/27/25.
//

import UIKit
import SnapKit

final class ReservationCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let reviewButton = UIButton(type: .system)
    var writeReviewAction: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        titleLabel.font = .boldSystemFont(ofSize: 16)
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = .systemGray
        
        reviewButton.setTitleColor(.white, for: .normal)
        reviewButton.backgroundColor = .systemGray3
        reviewButton.layer.cornerRadius = 8
        reviewButton.titleLabel?.font = .boldSystemFont(ofSize: 14)
        reviewButton.addTarget(self, action: #selector(writeReviewTapped), for: .touchUpInside)
        
        [titleLabel, statusLabel, reviewButton].forEach { contentView.addSubview($0) }
        
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(12)
            $0.trailing.lessThanOrEqualTo(reviewButton.snp.leading).offset(-8)
        }
        
        statusLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.equalTo(titleLabel)
        }
        
        reviewButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(110)
            $0.height.equalTo(36)
        }
    }
    
    func configure(with reservation: Reservation) {
        // ✅ 상점 이름 + 메뉴명
        titleLabel.text = "\(reservation.shopName) · \(reservation.menu)"
        
        // ✅ 상태별 문구만 회색으로 유지
        switch reservation.status {
        case "pending":
            statusLabel.text = "예약 중"
            reviewButton.isHidden = true
            
        case "completed":
            statusLabel.text = "이용 완료"
            if reservation.reviewWritten {
                reviewButton.isHidden = true
            } else {
                reviewButton.isHidden = false
                reviewButton.setTitle("리뷰 작성하기", for: .normal)
            }
            
        case "cancelled":
            statusLabel.text = "취소됨"
            reviewButton.isHidden = true
            
        default:
            statusLabel.text = reservation.status
            reviewButton.isHidden = true
        }
    }
    
    @objc private func writeReviewTapped() {
        writeReviewAction?()
    }
}
