//
//  CustomerServiceVC.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/23/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

final class CustomerServiceVC: UIViewController {
    
    private let db = Firestore.firestore()
    private var inquiries: [CustomerInquiry] = []
    
    private let tableView = UITableView()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "아직 문의하신 내용이 없어요. 💬"
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    private let writeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("문의하기", for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 17)
        btn.backgroundColor = .systemBlue
        btn.tintColor = .white
        btn.layer.cornerRadius = 12
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "고객센터 문의"
        
        setupLayout()
        setupTableView()
        
        writeButton.addTarget(self, action: #selector(writeTapped), for: .touchUpInside)
        fetchInquiries()
    }
    
    private func setupLayout() {
        [tableView, emptyLabel, writeButton].forEach { view.addSubview($0) }
        
        tableView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(writeButton.snp.top).offset(-12)
        }
        
        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        writeButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(52)
        }
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = 64
        tableView.separatorStyle = .singleLine
    }
    
    // MARK: - Firestore
    private func fetchInquiries() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(userId)
            .collection("customerInquiries")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("문의 내역 불러오기 실패:", error.localizedDescription)
                    self.emptyLabel.isHidden = false
                    return
                }
                
                guard let docs = snapshot?.documents else {
                    self.emptyLabel.isHidden = false
                    return
                }
                
                self.inquiries = docs.compactMap { CustomerInquiry(document: $0) }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.emptyLabel.isHidden = !self.inquiries.isEmpty
                }
            }
    }
    
    @objc private func writeTapped() {
        let vc = CustomerInquiryWriteVC()
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - TableView
extension CustomerServiceVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        inquiries.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let inquiry = inquiries[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = inquiry.title
        config.secondaryText = inquiry.answer == nil ? "답변 대기 중" : "답변 완료"
        config.secondaryTextProperties.color = inquiry.answer == nil ? .systemGray : .systemBlue
        
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = CustomerInquiryDetailVC()
        vc.inquiry = inquiries[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
}
