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
    private let nameLabel = UILabel()
    private let iconView = UIImageView(image: UIImage(systemName: "scissors.circle.fill"))
    private let arrowIcon = UIImageView(image: UIImage(systemName: "chevron.right"))
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        cardView.backgroundColor = .white
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowRadius = 6
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset = CGSize(width: 0, height: 3)
        contentView.addSubview(cardView)
        
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        nameLabel.font = .boldSystemFont(ofSize: 16)
        nameLabel.textColor = .label
        arrowIcon.tintColor = .systemGray3
        arrowIcon.contentMode = .scaleAspectFit
        
        [iconView, nameLabel, arrowIcon].forEach { cardView.addSubview($0) }
        
        cardView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(20)
            $0.height.equalTo(70)
        }
        
        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(32)
        }
        
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(4)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(arrowIcon.snp.leading).offset(-8)
        }
        
        arrowIcon.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(10)
        }
    }
    func configure(shopName: String) {
        nameLabel.text = shopName
    }
}
