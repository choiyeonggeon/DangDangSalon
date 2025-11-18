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
        reasonLabel.font = .boldSystemFont(ofSize: 16)
        reasonLabel.numberOfLines = 0
        
        infoLabel.font = .systemFont(ofSize: 14)
        infoLabel.textColor = .darkGray
        
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
    
    func configure(with report: ReviewReport) {
        reasonLabel.text = "사유: \(report.reason)"
        infoLabel.text = "리뷰ID: \(report.reviewId) | 샵ID: \(report.shopId)"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        dateLabel.text = formatter.string(from: report.createdAt)
    }
}
