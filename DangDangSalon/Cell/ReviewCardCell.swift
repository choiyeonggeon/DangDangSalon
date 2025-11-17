//
//  ReviewCardCell.swift
//  DangSalon
//
//  Created by 최영건 on 11/14/25.
//

import UIKit
import SnapKit

// MARK: - 프로토콜은 클래스 밖에 있어야 함 ❗
protocol ReviewCardCellDelegate: AnyObject {
    func didTapReviewImage(_ imageURLs: [String], selectedIndex: Int)
}

final class ReviewCardCell: UITableViewCell {
    
    // MARK: - Properties
    weak var delegate: ReviewCardCellDelegate?
    private var currentImageURLs: [String] = []
    
    // MARK: - UI
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 14
        v.layer.shadowOpacity = 1
        v.layer.shadowRadius = 6
        v.layer.shadowOffset = CGSize(width: 0, height: 3)
        v.layer.shadowColor = UIColor.black.withAlphaComponent(0.05).cgColor
        return v
    }()
    
    private let nicknameLabel = UILabel()
    private let ratingLabel = UILabel()
    private let contentLabel = UILabel()
    private let timestampLabel = UILabel()
    private let replyTitleLabel = UILabel()
    private let replyContentLabel = UILabel()
    
    private let photoScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.isHidden = true
        return sv
    }()
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        nicknameLabel.font = .boldSystemFont(ofSize: 16)
        ratingLabel.font = .systemFont(ofSize: 14)
        contentLabel.font = .systemFont(ofSize: 15)
        contentLabel.numberOfLines = 0
        
        timestampLabel.font = .systemFont(ofSize: 13)
        timestampLabel.textColor = .secondaryLabel
        
        replyTitleLabel.text = "사장님 답글"
        replyTitleLabel.font = .boldSystemFont(ofSize: 14)
        replyTitleLabel.textColor = .systemBlue
        replyTitleLabel.isHidden = true
        
        replyContentLabel.font = .systemFont(ofSize: 14)
        replyContentLabel.numberOfLines = 0
        replyContentLabel.backgroundColor = .systemGray6
        replyContentLabel.layer.cornerRadius = 10
        replyContentLabel.clipsToBounds = true
        replyContentLabel.isHidden = true
        
        contentView.addSubview(cardView)
        cardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.bottom.equalToSuperview().offset(-10)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        let stack = UIStackView(arrangedSubviews: [
            nicknameLabel,
            ratingLabel,
            contentLabel,
            photoScrollView,
            timestampLabel,
            replyTitleLabel,
            replyContentLabel
        ])
        stack.axis = .vertical
        stack.spacing = 12
        
        cardView.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
        
        photoScrollView.snp.makeConstraints { $0.height.equalTo(90) }
    }
    
    // MARK: - Configure
    func configure(with review: Review) {
        nicknameLabel.text = review.nickname
        ratingLabel.text = "⭐️ \(review.rating)"
        contentLabel.text = review.content
        
        timestampLabel.text =
        review.timestamp != nil ? timeAgo(from: review.timestamp!) : ""
        
        // 답글
        if let reply = review.reply, !reply.isEmpty {
            replyTitleLabel.isHidden = false
            replyContentLabel.isHidden = false
            replyContentLabel.text = "  \(reply)"
        } else {
            replyTitleLabel.isHidden = true
            replyContentLabel.isHidden = true
        }
        
        updatePhotos(review.imageURLs)
    }
    
    // MARK: - Load Photos
    private func updatePhotos(_ urls: [String]) {
        currentImageURLs = urls
        
        photoScrollView.subviews.forEach { $0.removeFromSuperview() }
        
        guard urls.count > 0 else {
            photoScrollView.isHidden = true
            return
        }
        
        photoScrollView.isHidden = false
        
        let size: CGFloat = 80
        var xOffset: CGFloat = 0
        
        for (index, urlString) in urls.enumerated() {   // ✔ index 가져오기
            guard let url = URL(string: urlString) else { continue }
            
            let iv = UIImageView()
            iv.tag = index   // ✔ 클릭 시 index 전달
            iv.isUserInteractionEnabled = true
            iv.backgroundColor = .systemGray5
            iv.layer.cornerRadius = 8
            iv.clipsToBounds = true
            iv.contentMode = .scaleAspectFill
            iv.frame = CGRect(x: xOffset, y: 0, width: size, height: size)
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(photoTapped(_:)))
            iv.addGestureRecognizer(tap)
            
            photoScrollView.addSubview(iv)
            xOffset += size + 8
            
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data,
                   let img = UIImage(data: data) {
                    DispatchQueue.main.async { iv.image = img }
                }
            }.resume()
        }
        
        photoScrollView.contentSize = CGSize(width: xOffset, height: size)
    }
    
    // MARK: - Image Tap
    @objc private func photoTapped(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view else { return }
        delegate?.didTapReviewImage(currentImageURLs, selectedIndex: view.tag)
    }
    
    // MARK: - Time Format
    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "방금 전" }
        if seconds < 3600 { return "\(seconds / 60)분 전" }
        if seconds < 86400 { return "\(seconds / 3600)시간 전" }
        if seconds < 604800 { return "\(seconds / 86400)일 전" }
        return "\(seconds / 604800)주 전"
    }
}
