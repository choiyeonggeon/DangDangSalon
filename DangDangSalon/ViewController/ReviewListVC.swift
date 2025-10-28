//
//  ReviewListVC.swift
//  DangSalon
//
//  Created by 최영건 on 10/27/25.
//

import UIKit
import SnapKit
import FirebaseFirestore

final class ReviewListVC: UIViewController {
    
    var shopId: String?
    private let db = Firestore.firestore()
    private var reviews: [Review] = []
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(ReviewCell.self, forCellReuseIdentifier: "ReviewCell")
        tv.separatorStyle = .none
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 60
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "전체 리뷰"
        
        tableView.dataSource = self
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        fetchAllReviews()
        
    }
    
    private func fetchAllReviews() {
        guard let shopId = shopId else { return }
        db.collection("shops").document(shopId).collection("reviews")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("리뷰 불러오기 실패:", error.localizedDescription)
                    return
                }
                self.reviews = snapshot?.documents.compactMap { Review(document: $0) } ?? []
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
}

extension ReviewListVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        reviews.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewCell", for: indexPath) as? ReviewCell else {
            return UITableViewCell()
        }
        cell.configure(with: reviews[indexPath.row])
        return cell
    }
}
