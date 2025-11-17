//
//  AdminCustomerServiceListVC.swift
//  DangSalon
//
//  Created by 최영건 on 11/17/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

struct AdminInquiry {
    let id: String
    let userId: String
    let title: String
    let content: String
    let createdAt: Date
    let answer: String?
    let answeredAt: Date?
}

final class AdminCustomerServiceListVC: UIViewController {
    
    private let tableView = UITableView()
    private var inquiries: [AdminInquiry] = []
    
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        title = "전체 문의 목록"
        
        setupTableView()
        fetchAllInquiries()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    private func fetchAllInquiries() {
        guard let user = Auth.auth().currentUser else { return }
        
        db.collection("users").document(user.uid).getDocument { snapshot, error in
            let role = snapshot?.data()?["role"] as? String ?? ""
            guard role == "admin" else {
                print("관리자 아님")
                return
            }
            
            self.db.collectionGroup("customerInquiries")
                .order(by: "createdAt", descending: true)
                .getDocuments { snap, error in
                    if let error = error {
                        print("❌ 전체 문의 가져오기 실패:", error.localizedDescription)
                        return
                    }
                    
                    self.inquiries = snap?.documents.compactMap { doc in
                        let data = doc.data()
                        
                        return AdminInquiry(
                            id: doc.documentID,
                            userId: doc.reference.parent.parent?.documentID ?? "",
                            title: data["title"] as? String ?? "",
                            content: data["content"] as? String ?? "",
                            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                            answer: data["answer"] as? String,
                            answeredAt: (data["answeredAt"] as? Timestamp)?.dateValue()
                        )
                    } ?? []
                    
                    self.tableView.reloadData()
                }
        }
    }
}

extension AdminCustomerServiceListVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inquiries.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let inquiry = inquiries[indexPath.row]
        
        let dateText = DateFormatter.localizedString(
            from: inquiry.createdAt,
            dateStyle: .short,
            timeStyle: .short)
        
        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.text = "[\(inquiry.userId)] \(inquiry.title)\n\(dateText)"
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let inquiry = inquiries[indexPath.row]
        let vc = AdminCustomerInquiryDetailVC(inquiry: inquiry)
        navigationController?.pushViewController(vc, animated: true)
    }
}
