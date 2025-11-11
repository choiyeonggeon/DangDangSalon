//
//  NoticeDetailVC.swift
//  DangSalon
//
//  Created by 최영건 on 11/11/25.
//

import UIKit
import SnapKit

final class NoticeDetailVC: UIViewController {
    
    private let notice: Notice
    
    init(notice: Notice) {
        self.notice = notice
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let contentLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
    }
    
    private func setupLayout() {
        [titleLabel, dateLabel, contentLabel].forEach { view.addSubview($0) }
        
        titleLabel.font = .boldSystemFont(ofSize: 22)
        titleLabel.numberOfLines = 0
        titleLabel.text = notice.title
        
        dateLabel.font = .systemFont(ofSize: 14)
        dateLabel.textColor = .systemGray
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateLabel.text = df.string(from: notice.createdAt)
        
        contentLabel.font = .systemFont(ofSize: 16)
        contentLabel.textColor = .label
        contentLabel.numberOfLines = 0
        contentLabel.text = notice.content
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        dateLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalTo(titleLabel)
        }
        
        contentLabel.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalTo(titleLabel)
        }
    }
}
