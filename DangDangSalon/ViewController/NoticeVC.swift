//
//  NoticeVC.swift
//  DangSalon
//
//  Created by 최영건 on 10/31/25.
//

import UIKit
import SnapKit
import FirebaseFirestore

final class NoticeVC: UIViewController {
    
    private let db = Firestore.firestore()
    private var notices: [Notice] = []
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .none
        tv.backgroundColor = .clear
        tv.showsHorizontalScrollIndicator = false
        tv.register(NoticeCell.self, forCellReuseIdentifier: "NoticeCell")
        return tv
    }()
    
    private let emptyLabel: UILabel = {
        let lb = UILabel()
        lb.text = "등록된 공지사항이 없습니다. 🐶"
        lb.textColor = .systemGray
        lb.textAlignment = .center
        lb.font = .systemFont(ofSize: 16)
        lb.isHidden = true
        return lb
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "공지사항"
        
        setupUI()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        fetchNotices()
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        
        tableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide).inset(12)
        }
        
        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    private func fetchNotices() {
        db.collection("notices")
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("공지 불러오기 실패:", error.localizedDescription)
                    return
                }
                guard let docs = snapshot?.documents else { return }
                
                var list = docs.compactMap { Notice(document: $0) }
                
                list.sort {
                    if $0.isPinned != $1.isPinned {
                        return $0.isPinned && !$1.isPinned
                    }
                    
                    let date0 = $0.createdAt ?? .distantPast
                    let date1 = $1.createdAt ?? .distantPast
                    return date0 > date1
                }
                
                self.notices = list
                
                DispatchQueue.main.async {
                    self.emptyLabel.isHidden = !self.notices.isEmpty
                    self.tableView.reloadData()
                }
            }
    }
}

// MARK: - TableView
extension NoticeVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notices.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "NoticeCell",
        for: indexPath
        ) as? NoticeCell else { return UITableViewCell() }
        
        cell.configure(with: notices[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let notice = notices[indexPath.row]
        let vc = NoticeDetailVC(notice: notice)
        navigationController?.pushViewController(vc, animated: true)
    }
}
