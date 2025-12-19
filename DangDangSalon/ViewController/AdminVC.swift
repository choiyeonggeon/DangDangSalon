//
//  AdminVC.swift
//  DangSalon
//
//  Created by 최영건 on 11/13/25.
//

import UIKit
import SnapKit

final class AdminVC: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private let menuItems = [
        "공지사항 작성",
        "쿠폰 발급",
        "리뷰 신고 관리",
        "예약 신고 관리",
        "고객센터(관리자용)"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        title = "관리자 메뉴"
        setupTableView()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = 50
    }
}

extension AdminVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = menuItems[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = menuItems[indexPath.row]
        
        switch item {
            
        case "공지사항 작성":
            let vc = NoticeWriteVC()
            navigationController?.pushViewController(vc, animated: true)
            
        case "쿠폰 발급":
            let vc = CouponIssueVC()
            navigationController?.pushViewController(vc, animated: true)
            
        case "리뷰 신고 관리":
            let vc = AdminReviewReportListVC()
            navigationController?.pushViewController(vc, animated: true)
            
        case "예약 신고 관리":
            let vc = AdminReservationReportsVC()
            navigationController?.pushViewController(vc, animated: true)
            
        case "고객센터(관리자용)":
            let vc = AdminCustomerServiceListVC()
            navigationController?.pushViewController(vc, animated: true)
            
        default: break
        }
    }
}
