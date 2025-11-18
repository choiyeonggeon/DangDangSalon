//
//  AdminReviewReportListVC.swift
//  DangSalon
//
//  Created by 최영건 on 11/18/25.
//

import UIKit
import SnapKit
import FirebaseFirestore

final class AdminReviewReportListVC: UIViewController {
    
    private let tableView = UITableView()
    private let db = Firestore.firestore()
    
    private var reports: [ReviewReport] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        title = "리뷰 신고 관리"
        setupTableView()
        fetchReports()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ReportCell.self, forCellReuseIdentifier: "ReportCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
    }
    
    private func fetchReports() {
        db.collection("reviewReports")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snap, err in
                guard let self = self else { return }
                
                if let err = err {
                    print("리뷰 신고 가져오기 오류:", err.localizedDescription)
                    return
                }
                guard let docs = snap?.documents else { return }
                
                self.reports = docs.compactMap { ReviewReport(document: $0) }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
}

extension AdminReviewReportListVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        reports.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReportCell", for: indexPath) as! ReportCell
        
        cell.configure(with: reports[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let report = reports[indexPath.row]
        let vc = AdminReviewReportDetailVC(report: report)
        navigationController?.pushViewController(vc, animated: true)
    }
}
