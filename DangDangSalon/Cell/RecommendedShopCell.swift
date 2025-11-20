//
//  RecommendedShopCell.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/16/25.
//

import UIKit
import SnapKit
import SDWebImage

class RecommendedShopCell: UICollectionViewCell {
    
    // MARK: - UI Components
    private let shopImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.backgroundColor = .systemGray6
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 15)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()
    
    private let ratingImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "star.fill"))
        iv.tintColor = .systemYellow
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var ratingStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [ratingImageView, ratingLabel])
        stack.axis = .horizontal
        stack.spacing = 4
        return stack
    }()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.1
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        
        [shopImageView, nameLabel, ratingStack].forEach { contentView.addSubview($0) }
        
        shopImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(80)
        }
        
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(shopImageView.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(8)
        }
        
        ratingStack.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().inset(8)
            $0.bottom.equalToSuperview().inset(8)
        }
    }
    
    // MARK: - Configure
    func configure(with shop: Shop) {
        nameLabel.text = shop.name
        ratingLabel.text = String(format: "%.1f", shop.rating)
        
        if let imageURLs = shop.imageURLs,
           let firstURL = imageURLs.first {
            shopImageView.sd_setImage(
                with: URL(string: imageURLs.first ?? ""),
                placeholderImage: UIImage(systemName: "scissors")
            )
        } else {
            shopImageView.image = UIImage(systemName: "scissors")
        }
    }
}
