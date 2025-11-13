//
//  PaymentCell.swift
//  DangSalon
//
//  Created by 최영건 on 11/13/25.
//

import UIKit
import SnapKit

final class PaymentCell: UITableViewCell {
    
    private let cardView = UIView()
    private let shopLabel = UILabel()
    private let amountLabel = UILabel()
    private let methodLabel = UILabel()
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
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowRadius = 5
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        
        contentView.addSubview(cardView)
        [shopLabel, amountLabel, methodLabel, dateLabel].forEach { cardView.addSubview($0) }
        
        cardView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4))
        }
        
        shopLabel.font = .boldSystemFont(ofSize: 16)
        amountLabel.font = .boldSystemFont(ofSize: 15)
        amountLabel.textColor = .systemBlue
        
        methodLabel.font = .systemFont(ofSize: 14)
        methodLabel.textColor = .secondaryLabel
        
        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = .systemGray
        
        shopLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(16)
            $0.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-10)
        }
        
        amountLabel.snp.makeConstraints {
            $0.top.equalTo(shopLabel)
            $0.trailing.equalToSuperview().inset(16)
        }
        
        methodLabel.snp.makeConstraints {
            $0.top.equalTo(shopLabel.snp.bottom).offset(6)
            $0.leading.equalTo(shopLabel)
        }
        
        dateLabel.snp.makeConstraints {
            $0.top.equalTo(methodLabel.snp.bottom).offset(4)
            $0.leading.equalTo(shopLabel)
            $0.bottom.equalToSuperview().inset(14)
        }
    }
    
    func configure(with payment: Payment) {
        shopLabel.text = payment.shopName
        
        let formatted = NumberFormatter.localizedString(
            from: NSNumber(value: payment.amount),
            number: .decimal
        )
        
        amountLabel.text = "\(formatted)원"
        
        methodLabel.text = payment.method
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        dateLabel.text = formatter.string(from: payment.createdAt)
    }
}
