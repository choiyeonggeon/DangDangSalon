//
//  AdminCustomerServiceListVC.swift
//  DangSalon
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

struct AdminInquiry {
    let id: String
    let userId: String
    let nickname: String
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
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "문의가 아직 없습니다. 💬"
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        title = "전체 문의 목록"
        
        setupTableView()
        setupEmptyLabel()
        fetchAllInquiries()
    }
    
    private func setupEmptyLabel() {
        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = 80
    }
    
    // 🔥 한국어 날짜 포맷
    private func formatKoreanDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 MM월 dd일 (E) HH:mm"
        return f.string(from: date)
    }
    
    private func fetchAllInquiries() {
        guard let user = Auth.auth().currentUser else { return }
        
        // 🔐 관리자 여부 체크
        db.collection("users").document(user.uid).getDocument { snapshot, error in
            let role = snapshot?.data()?["role"] as? String ?? ""
            guard role == "admin" else {
                print("관리자 아님")
                return
            }
            
            // 🔥 모든 유저의 customerInquiries 가져오기
            self.db.collectionGroup("customerInquiries")
                .order(by: "createdAt", descending: true)
                .getDocuments { snap, error in
                    
                    if let error = error {
                        print("❌ 전체 문의 가져오기 실패:", error.localizedDescription)
                        return
                    }
                    
                    guard let docs = snap?.documents else { return }
                    
                    var tempList: [AdminInquiry] = []
                    let group = DispatchGroup()
                    
                    for doc in docs {
                        let data = doc.data()
                        let userId = doc.reference.parent.parent?.documentID ?? ""
                        
                        group.enter()
                        
                        self.db.collection("users")
                            .document(userId)
                            .getDocument { userSnap, _ in
                                
                                let nickname = userSnap?.data()?["nickname"] as? String ?? "알 수 없음"
                                
                                let inquiry = AdminInquiry(
                                    id: doc.documentID,
                                    userId: userId,
                                    nickname: nickname,
                                    title: data["title"] as? String ?? "",
                                    content: data["content"] as? String ?? "",
                                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                                    answer: data["answer"] as? String,
                                    answeredAt: (data["answeredAt"] as? Timestamp)?.dateValue()
                                )
                                
                                tempList.append(inquiry)
                                group.leave()
                            }
                    }
                    
                    group.notify(queue: .main) {
                        self.inquiries = tempList
                        self.emptyLabel.isHidden = !tempList.isEmpty
                        self.tableView.reloadData()
                    }
                }
        }
    }
}

extension AdminCustomerServiceListVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        inquiries.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let inquiry = inquiries[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        var config = cell.defaultContentConfiguration()
        
        // 🔹 제목 구성: 닉네임 + 제목
        config.text = "\(inquiry.nickname) · \(inquiry.title)"
        
        // 🔹 날짜 + 답변 여부
        let dateText = formatKoreanDate(inquiry.createdAt)
        let answerStatus = inquiry.answer == nil ? "답변 대기" : "답변 완료"
        
        config.secondaryText = "\(dateText)   ·   \(answerStatus)"
        
        // 스타일
        config.secondaryTextProperties.color = inquiry.answer == nil ? .systemRed : .systemBlue
        config.secondaryTextProperties.font = .systemFont(ofSize: 14)
        
        cell.contentConfiguration = config
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
