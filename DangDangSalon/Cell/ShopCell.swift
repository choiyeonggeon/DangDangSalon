//
//  ShopCell.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/16/25.
//

import UIKit
import SnapKit

class ShopCell: UITableViewCell {
    private let shopImageView = UIImageView()
    private let nameLabel = UILabel()
    
    private let adsBadge: UILabel = {
        let lb = UILabel()
        lb.text = "광고"
        lb.font = .systemFont(ofSize: 11, weight: .black)
        lb.textColor = .white
        lb.backgroundColor = UIColor(red: 1.0, green: 0.82, blue: 0.0, alpha: 1.0) // 금색
        lb.textAlignment = .center
        lb.layer.cornerRadius = 6
        lb.clipsToBounds = true
        lb.isHidden = true
        return lb
    }()
    
    private let badgeLabel: UILabel = {
        let lb = UILabel()
        lb.text = "추천"
        lb.font = .systemFont(ofSize: 12, weight: .bold)
        lb.textColor = .white
        lb.backgroundColor = .systemBlue
        lb.textAlignment = .center
        lb.layer.cornerRadius = 6
        lb.clipsToBounds = true
        lb.isHidden = true
        return lb
    }()
    
    private let newBadge: UILabel = {
        let lb = UILabel()
        lb.text = "NEW"
        lb.font = .systemFont(ofSize: 11, weight: .bold)
        lb.textColor = .white
        lb.backgroundColor = .systemGreen
        lb.textAlignment = .center
        lb.layer.cornerRadius = 6
        lb.clipsToBounds = true
        lb.isHidden = true
        return lb
    }()
    
    private lazy var badgeStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [adsBadge, badgeLabel, newBadge])
        stack.axis = .horizontal
        stack.spacing = 4
        return stack
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        contentView.addSubview(shopImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(badgeStack)
        
        shopImageView.image = UIImage(systemName: "scissors")
        shopImageView.tintColor = .systemBlue
        shopImageView.contentMode = .scaleAspectFit
        
        badgeStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.equalToSuperview().offset(12)
        }
        
        shopImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(28)
        }
        
        nameLabel.font = .systemFont(ofSize: 17, weight: .medium)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.8
        nameLabel.lineBreakMode = .byTruncatingTail
        
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(shopImageView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }
    }
    
    func configure(with shop: Shop) {
        nameLabel.text = shop.name
        
        // 초기 숨김
        adsBadge.isHidden = true
        badgeLabel.isHidden = true
        newBadge.isHidden = true
        
        // 광고 → 최우선 표시
        if shop.isAds {
            adsBadge.isHidden = false
            return
        }
        
        // 추천 배지
        if shop.isRecommended {
            badgeLabel.isHidden = false
        }
        
        // NEW (가입 30일 이내)
        if shop.isNew {
            newBadge.isHidden = false
        }
    }
}
