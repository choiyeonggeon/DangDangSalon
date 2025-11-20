//
//  AdminReservationReportsVC.swift
//  DangSalon
//
//  Created by 최영건 on 11/20/25.
//

import UIKit
import SnapKit
import FirebaseFirestore

final class AdminReservationReportsVC: UIViewController {
    
    private let db = Firestore.firestore()
    private var reports: [QueryDocumentSnapshot] = []
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "예약 신고 리스트"
        
        setupTableView()
        fetchReports()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        tableView.register(ReportCell.self, forCellReuseIdentifier: "ReportCell")
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 90
    }
    
    private func fetchReports() {
        db.collection("reservationReports")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("신고 목록 불러오기 실패:", error.localizedDescription)
                    return
                }
                
                self.reports = snapshot?.documents ?? []
                self.tableView.reloadData()
            }
    }
}

extension AdminReservationReportsVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        reports.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "ReportCell",
            for: indexPath
        ) as? ReportCell else { return UITableViewCell() }
        
        let data = reports[indexPath.row].data()
        cell.configure(with: data)
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let data = reports[indexPath.row].data()
        
        let vc = AdminReservationReportDetailVC()
        vc.reportData = data
        navigationController?.pushViewController(vc, animated: true)
    }
}
