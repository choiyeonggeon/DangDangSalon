//
//  AdminReviewReportDetailVC.swift
//  DangSalon
//
//  Created by 최영건 on 11/18/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

final class AdminReviewReportDetailVC: UIViewController {
    
    private let report: ReviewReport
    
    init(report: ReviewReport) {
        self.report = report
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private let reasonLabel = UILabel()
    private let detailLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        title = "신고 상세"
        
        setupUI()
    }
    
    private func setupUI() {
        reasonLabel.font = .boldSystemFont(ofSize: 18)
        reasonLabel.numberOfLines = 0
        
        detailLabel.font = .systemFont(ofSize: 14)
        detailLabel.numberOfLines = 0
        detailLabel.textColor = .darkGray
        
        [reasonLabel, detailLabel].forEach { view.addSubview($0) }
        
        reasonLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        detailLabel.snp.makeConstraints {
            $0.top.equalTo(reasonLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        reasonLabel.text = "🚨 신고 사유\n\(report.reason)"
        detailLabel.text = """
        🔹 Shop ID: \(report.shopId)
        🔹 Review ID: \(report.reviewId)
        🔹 신고자 UID: \(report.reporterUid)
        """
    }
}
