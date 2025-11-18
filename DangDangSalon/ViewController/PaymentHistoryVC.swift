//
//  PaymentHistoryVC.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/23/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

final class PaymentHistoryVC: UIViewController {
    
    private let db = Firestore.firestore()
    private var payments: [Payment] = []
    
    // MARK: - UI
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.register(PaymentCell.self, forCellReuseIdentifier: "PaymentCell")
        return tv
    }()
    
    private let emptyView: UIView = {
        let v = UIView()
        v.isHidden = true
        
        let img = UIImageView(image: UIImage(systemName: "creditcard.circle.fill"))
        img.tintColor = .systemGray4
        img.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = "결제 내역이 없습니다. 💳"
        label.font = .systemFont(ofSize: 17)
        label.textColor = .systemGray
        
        let stack = UIStackView(arrangedSubviews: [img, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        v.addSubview(stack)
        
        stack.snp.makeConstraints { $0.center.equalToSuperview() }
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "결제 내역"
        
        setupLayout()
        tableView.dataSource = self
        tableView.delegate = self
        
        fetchPayments()
    }
    
    // MARK: - Firestore
    private func fetchPayments() {
        guard let userId = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                self.emptyView.isHidden = false
                self.tableView.isHidden = true
                
                if let label = self.emptyView.subviews.first?.subviews.last as? UILabel {
                    label.text = "로그인 후 결제 내역을 확인할 수 있어요 💳"
                }
            }
            return
        }
        
        db.collection("users")
            .document(userId)
            .collection("payments")
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, err in
                guard let self = self else { return }
                
                if let err = err {
                    print("❌ 결제 내역 불러오기 실패:", err.localizedDescription)
                    return
                }
                
                self.payments = snapshot?.documents.compactMap { Payment(document: $0) } ?? []
                
                DispatchQueue.main.async {
                    if self.payments.isEmpty {
                        self.emptyView.isHidden = false
                        self.tableView.isHidden = true
                    } else {
                        self.emptyView.isHidden = true
                        self.tableView.isHidden = false
                        self.tableView.reloadData()
                    }
                }
            }
    }
    
    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(emptyView)
        
        tableView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        
        emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

// MARK: - TableView
extension PaymentHistoryVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payments.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "PaymentCell",
            for: indexPath
        ) as? PaymentCell else { return UITableViewCell() }
        
        cell.configure(with: payments[indexPath.row])
        return cell
    }
}
