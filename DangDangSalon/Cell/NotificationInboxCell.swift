//
//  NotificationInboxCell.swift
//  DangSalon
//
//  Created by 최영건 on 12/23/25.
//

import UIKit
import SnapKit

// 홈 화면 알림용
final class NotificationInboxCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let dateLabel = UILabel()
    private let unreadDot = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        unreadDot.backgroundColor = .systemRed
        unreadDot.layer.cornerRadius = 4
        unreadDot.isHidden = true
        
        titleLabel.font = .boldSystemFont(ofSize: 15)
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 2
        
        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = .tertiaryLabel
        
        let textStack = UIStackView(arrangedSubviews: [titleLabel, messageLabel, dateLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        
        contentView.addSubview(unreadDot)
        contentView.addSubview(textStack)
        
        unreadDot.snp.makeConstraints {
            $0.size.equalTo(8)
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(16)
        }
        
        textStack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(16)
            $0.leading.equalTo(unreadDot.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(16)
        }
    }
    
    func configure(_ noti: AppNotification) {
        titleLabel.text = noti.title
        messageLabel.text = noti.message
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd HH:mm"
        dateLabel.text = formatter.string(from: noti.createdAt)
        
        unreadDot.isHidden = noti.isRead
    }
}
