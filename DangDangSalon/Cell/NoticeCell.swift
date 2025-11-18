//
//  NoticeCell.swift
//  DangSalon
//
//  Created by 최영건 on 11/11/25.
//

import UIKit
import SnapKit

final class NoticeCell: UITableViewCell {
    
    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 14
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowOffset = CGSize(width: 0, height: 3)
        cardView.layer.shadowRadius = 5
        
        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        
        dateLabel.font = .systemFont(ofSize: 14)
        dateLabel.textColor = .systemGray
        
        contentView.addSubview(cardView)
        [titleLabel, dateLabel].forEach { cardView.addSubview($0) }
        
        cardView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(8)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(16)
        }
        
        dateLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview().inset(16)
        }
    }
    
    func configure(with notice: Notice) {
        let fullTitle = "[공지] \(notice.title)"
        let attributed = NSMutableAttributedString(string: fullTitle)
                
        attributed.addAttribute(.foregroundColor,
                                   value: UIColor.systemBlue,
                                   range: NSRange(location: 0, length: 4))
        titleLabel.attributedText = attributed
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        dateLabel.text = formatter.string(from: notice.createdAt)
        
    }
}
