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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        contentView.addSubview(shopImageView)
        contentView.addSubview(nameLabel)
        
        shopImageView.image = UIImage(systemName: "scissors")
        shopImageView.tintColor = .systemBlue
        shopImageView.contentMode = .scaleAspectFit
        
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
    
    func configure(with name: String) {
        nameLabel.text = name
    }
}
