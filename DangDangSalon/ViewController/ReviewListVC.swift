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
        tv.backgroundColor = .systemGroupedBackground
        tv.register(ReviewCardCell.self, forCellReuseIdentifier: "ReviewCardCell")
        tv.separatorStyle = .none
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 100
        tv.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "전체 리뷰"
        
        tableView.dataSource = self
        tableView.delegate = self
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

extension ReviewListVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        reviews.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewCardCell", for: indexPath) as? ReviewCardCell else {
            return UITableViewCell()
        }
        cell.delegate = self   // ⭐️⭐️⭐️ 반드시 추가 ⭐️⭐️⭐️
        cell.configure(with: reviews[indexPath.row])
        return cell
    }
}

// MARK: - ReviewCardCellDelegate
extension ReviewListVC: ReviewCardCellDelegate {
    
    /// 사진 클릭 시 실행됨
    func didTapReviewImage(_ imageURLs: [String], selectedIndex: Int) {
        let viewerVC = FullImageViewerVC(imageURLs: imageURLs, startIndex: selectedIndex)
        viewerVC.modalPresentationStyle = .fullScreen
        
        present(viewerVC, animated: true)
    }
}
