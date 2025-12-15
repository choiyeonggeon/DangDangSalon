//
//  CouponCell.swift
//  DangSalon
//
//  Created by 최영건 on 12/15/25.
//

import UIKit
import SnapKit

final class CouponCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let discountLabel = UILabel()
    private let expireLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        titleLabel.font = .boldSystemFont(ofSize: 16)
        discountLabel.textColor = .systemRed
        
        expireLabel.font = .systemFont(ofSize: 12)
        expireLabel.textColor = .secondaryLabel
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, discountLabel, expireLabel])
        stack.axis = .vertical
        stack.spacing = 4
        
        contentView.addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }
    }
    
    func configure(coupon: Coupon) {
        titleLabel.text = coupon.title
        discountLabel.text = coupon.discountType == "percent"
        ? "\(coupon.discountValue)% 할인"
        : "\(coupon.discountValue)원 할인"
        
        let date = coupon.expiredAt.dateValue()
        let forrmatter = DateFormatter()
        forrmatter.dateFormat = "yyyy-MM-dd"
        expireLabel.text = "유효기간 \(forrmatter.string(from: date))"
    }
}
