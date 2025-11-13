//
//  FavoritesCell.swift
//  DangSalon
//
//  Created by 최영건 on 11/10/25.
//

import UIKit
import SnapKit

final class FavoriteCell: UITableViewCell {
    
    private let cardView = UIView()
    private let iconView = UIImageView(image: UIImage(systemName: "scissors.circle.fill"))
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let arrowIcon = UIImageView(image: UIImage(systemName: "chevron.right"))
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // 카드뷰 스타일 (ReservationCell 동일)
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset = CGSize(width: 0, height: 3)
        cardView.layer.shadowRadius = 5
        
        contentView.addSubview(cardView)
        [iconView, nameLabel, subtitleLabel, arrowIcon].forEach { cardView.addSubview($0) }
        
        cardView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4))
            $0.height.greaterThanOrEqualTo(80)
        }
        
        // 아이콘 더 크게 (32 → 40)
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(40)
        }
        
        // 화살표
        arrowIcon.tintColor = .systemGray3
        arrowIcon.contentMode = .scaleAspectFit
        arrowIcon.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(12)
            $0.height.equalTo(18)
        }
        
        // 텍스트 기본 설정
        nameLabel.font = .boldSystemFont(ofSize: 16)
        nameLabel.textColor = .label
        
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        
        // ⭐ 텍스트 간격 균형 맞춤
        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.leading.equalTo(iconView.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(arrowIcon.snp.leading).offset(-12)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(6)
            $0.bottom.equalToSuperview().inset(16)
        }
    }
    
    func configure(shopName: String, area: String? = nil) {
        nameLabel.text = shopName
        subtitleLabel.text = area ?? "매장 정보 보기"
    }
}
