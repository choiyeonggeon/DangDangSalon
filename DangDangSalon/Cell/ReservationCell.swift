//
//  ReservationCell.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/27/25.
//

import UIKit
import SnapKit

final class ReservationCell: UITableViewCell {
    
    private let cardView = UIView()
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
        backgroundColor = .clear
        selectionStyle = .none
        
        // 카드 뷰 (배민 스타일)
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 5
        contentView.addSubview(cardView)
        [titleLabel, statusLabel, reviewButton].forEach { cardView.addSubview($0) }
        
        cardView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4))
            $0.height.greaterThanOrEqualTo(80)
        }
        
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.textColor = .label
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = .secondaryLabel
        
        reviewButton.setTitle("리뷰 작성", for: .normal)
        reviewButton.backgroundColor = .systemBlue
        reviewButton.setTitleColor(.white, for: .normal)
        reviewButton.titleLabel?.font = .boldSystemFont(ofSize: 14)
        reviewButton.layer.cornerRadius = 8
        reviewButton.addTarget(self, action: #selector(writeReviewTapped), for: .touchUpInside)
        
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(16)
            $0.trailing.lessThanOrEqualTo(reviewButton.snp.leading).offset(-8)
        }
        
        statusLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.equalTo(titleLabel)
            $0.bottom.equalToSuperview().inset(16)
        }
        
        reviewButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().inset(16)
            $0.width.equalTo(90)
            $0.height.equalTo(36)
        }
    }
    
    func configure(with reservation: Reservation) {
        titleLabel.text = "\(reservation.shopName) · \(reservation.menus)"
        switch reservation.status {
        case "pending":
            statusLabel.text = "예약 중"
            reviewButton.isHidden = true
        case "completed":
            statusLabel.text = "이용 완료"
            reviewButton.isHidden = reservation.reviewWritten
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
