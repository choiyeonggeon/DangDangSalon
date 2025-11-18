//
//  ShopCell.swift
//  DangDangSalon
//

import UIKit
import SnapKit
import SDWebImage

class ShopCell: UITableViewCell {
    
    private let shopImageView = UIImageView()
    private let nameLabel = UILabel()
    
    private let ratingLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 13, weight: .medium)
        lb.textColor = .systemYellow
        return lb
    }()
    
    private let reviewCountLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 12)
        lb.textColor = .secondaryLabel
        return lb
    }()
    
    private let distanceLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 12)
        lb.textColor = .secondaryLabel
        return lb
    }()
    
    private lazy var infoStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [ratingLabel, reviewCountLabel, distanceLabel])
        stack.axis = .horizontal
        stack.spacing = 6
        return stack
    }()
    
    // 광고 / 추천 / NEW 배지
    private let adsBadge: UILabel = {
        let lb = UILabel()
        lb.text = "광고"
        lb.font = .systemFont(ofSize: 11, weight: .black)
        lb.textColor = .white
        lb.backgroundColor = UIColor(red: 1.0, green: 0.82, blue: 0.0, alpha: 1.0)
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
        contentView.addSubview(infoStack)
        contentView.addSubview(badgeStack)
        
        shopImageView.layer.cornerRadius = 6
        shopImageView.clipsToBounds = true
        shopImageView.contentMode = .scaleAspectFill
        shopImageView.backgroundColor = .systemGray6
        
        shopImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(48)
        }
        
        badgeStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.top.equalToSuperview().offset(8)
        }
        
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .label
        
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(shopImageView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(20)
            $0.top.equalToSuperview().offset(12)
        }
        
        infoStack.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.bottom.equalToSuperview().inset(12)
        }
    }
    
    func configure(with shop: Shop) {
        nameLabel.text = shop.name
        
        // ⭐️ 별점
        ratingLabel.text = "⭐️ \(String(format: "%.1f", shop.rating))"
        
        // 리뷰 수
        reviewCountLabel.text = "(\(shop.reviewCount))"
        
        // 거리
        if let meter = shop.distanceMeter {
            distanceLabel.text = meter >= 1000
            ? String(format: "%.1fkm", Double(meter)/1000.0)
            : "\(meter)m"
        } else {
            distanceLabel.text = ""
        }
        
        // 배지 초기화
        adsBadge.isHidden = true
        badgeLabel.isHidden = true
        newBadge.isHidden = true
        
        if shop.isAds {
            adsBadge.isHidden = false
        } else {
            if shop.isRecommended { badgeLabel.isHidden = false }
            if shop.isNew { newBadge.isHidden = false }
        }
        
        // 이미지 로드
        if let urlStr = shop.imageURLs?.first,
           let url = URL(string: urlStr) {
            shopImageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "scissors"))
        } else {
            shopImageView.image = UIImage(systemName: "scissors")
        }
    }
}
