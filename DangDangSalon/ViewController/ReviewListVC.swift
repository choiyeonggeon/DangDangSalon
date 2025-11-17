//
//  ReviewListVC.swift
//  DangSalon
//
//  Created by 최영건 on 10/27/25.
//

import UIKit
import SnapKit
import FirebaseFirestore
import FirebaseAuth   // uid 비교용

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
    
    // MARK: - Firestore
    private func fetchAllReviews() {
        guard let shopId = shopId else { return }
        
        db.collection("shops")
            .document(shopId)
            .collection("reviews")
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
    
    // MARK: - 본인 리뷰 수정/삭제 메뉴
    private func showOwnerOptions(review: Review) {
        let sheet = UIAlertController(title: "리뷰 관리", message: nil, preferredStyle: .actionSheet)
        
        sheet.addAction(UIAlertAction(title: "리뷰 수정하기", style: .default) { _ in
            self.editReview(review)
        })
        sheet.addAction(UIAlertAction(title: "리뷰 삭제하기", style: .destructive) { _ in
            self.deleteReview(review)
        })
        sheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = self.view
            pop.sourceRect = CGRect(
                x: self.view.bounds.midX,
                y: self.view.bounds.midY,
                width: 0,
                height: 0
            )
            pop.permittedArrowDirections = []
        }
        
        present(sheet, animated: true)
    }
    
    // MARK: - 리뷰 수정
    private func editReview(_ review: Review) {
        guard let shopId = shopId else { return }
        
        let alert = UIAlertController(title: "리뷰 수정", message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.text = review.content
        }
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "저장", style: .default, handler: { _ in
            let newText = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !newText.isEmpty else { return }
            
            self.db.collection("shops")
                .document(shopId)
                .collection("reviews")
                .document(review.id)
                .updateData([
                    "content": newText,
                    "editedAt": Timestamp()
                ]) { error in
                    if let error = error {
                        print("리뷰 수정 실패:", error.localizedDescription)
                        return
                    }
                    self.fetchAllReviews()
                }
        }))
        
        present(alert, animated: true)
    }
    
    // MARK: - 리뷰 삭제
    private func deleteReview(_ review: Review) {
        guard let shopId = shopId else { return }
        
        let confirm = UIAlertController(
            title: "삭제 확인",
            message: "정말 이 리뷰를 삭제하시겠습니까?",
            preferredStyle: .alert
        )
        
        confirm.addAction(UIAlertAction(title: "취소", style: .cancel))
        confirm.addAction(UIAlertAction(title: "삭제", style: .destructive, handler: { _ in
            self.db.collection("shops")
                .document(shopId)
                .collection("reviews")
                .document(review.id)
                .delete { error in
                    if let error = error {
                        print("리뷰 삭제 실패:", error.localizedDescription)
                        return
                    }
                    self.fetchAllReviews()
                }
        }))
        
        present(confirm, animated: true)
    }
    
    // MARK: - 리뷰 신고 로직
    private func reportReview(_ review: Review) {
        guard let shopId = shopId else { return }
        guard let uid = Auth.auth().currentUser?.uid else {
            showAlert(title: "로그인 필요", message: "로그인 후 신고할 수 있습니다.")
            return
        }
        
        // 🔥 본인 리뷰 신고 방지
        if review.authorId == uid {
            showAlert(title: "신고 불가", message: "본인이 작성한 리뷰는 신고할 수 없습니다.")
            return
        }
        
        let reasons = [
            "부적절한 내용이에요",
            "욕설/혐오 표현이 있어요",
            "광고/스팸 같아요",
            "기타"
        ]
        
        let sheet = UIAlertController(
            title: "리뷰 신고",
            message: "신고 사유를 선택해주세요.",
            preferredStyle: .actionSheet
        )
        
        for reason in reasons {
            sheet.addAction(UIAlertAction(title: reason, style: .default) { _ in
                self.sendReport(review: review, reason: reason, reporterId: uid, shopId: shopId)
            })
        }
        
        sheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = self.view
            pop.sourceRect = CGRect(
                x: self.view.bounds.midX,
                y: self.view.bounds.midY,
                width: 0,
                height: 0
            )
            pop.permittedArrowDirections = []
        }
        
        present(sheet, animated: true)
    }
    
    private func sendReport(
        review: Review,
        reason: String,
        reporterId: String,
        shopId: String
    ) {
        let data: [String: Any] = [
            "shopId": shopId,
            "reviewId": review.id,
            "reviewContent": review.content,
            "reason": reason,
            "reporterId": reporterId,
            "authorId": review.authorId,
            "createdAt": Timestamp()
        ]
        
        db.collection("reviewReports").addDocument(data: data) { error in
            if let error = error {
                print("리뷰 신고 저장 실패:", error.localizedDescription)
                self.showAlert(title: "오류", message: "신고 저장에 실패했습니다.")
                return
            }
            
            self.showAlert(title: "신고 완료", message: "해당 리뷰가 신고되었습니다.")
        }
    }
    
    // MARK: - Alert Helper
    private func showAlert(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "확인", style: .default))
        present(ac, animated: true)
    }
}

// MARK: - TableView
extension ReviewListVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        reviews.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "ReviewCardCell",
            for: indexPath
        ) as? ReviewCardCell else {
            return UITableViewCell()
        }
        
        cell.delegate = self
        cell.configure(with: reviews[indexPath.row])
        return cell
    }
}

// MARK: - ReviewCardCellDelegate
extension ReviewListVC: ReviewCardCellDelegate {
    
    func didTapReviewImage(_ imageURLs: [String], selectedIndex: Int) {
        let vc = FullImageViewerVC(imageURLs: imageURLs, startIndex: selectedIndex)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    /// … 버튼 눌렀을 때 호출
    func didTapMoreButton(_ review: Review) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        if review.authorId == uid {
            // ⭐ 본인 리뷰 = 수정/삭제 메뉴
            showOwnerOptions(review: review)
        } else {
            // ⭐ 다른 사람 리뷰 = 신고
            reportReview(review)
        }
    }
}
