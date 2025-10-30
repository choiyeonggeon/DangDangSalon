//
//  FavoritesVC.swift
//  DangSalon
//
//  Created by 최영건 on 10/30/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

final class FavoritesVC: UIViewController {
    private let db = Firestore.firestore()
    private var favorites: [(shopId: String, shopName: String)] = []
    
    private let tableView = UITableView() // ✅ 이름 수정
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "즐겨찾기"
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        
        fetchFavorites()
    }
    
    private func fetchFavorites() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(userId)
            .collection("favorites")
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("찜 목록 불러오기 실패:", error.localizedDescription)
                    return
                }
                self.favorites = snapshot?.documents.compactMap { doc in
                    guard let name = doc["shopName"] as? String else { return nil }
                    return (doc.documentID, name)
                } ?? []
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
}

extension FavoritesVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        favorites.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell { // ✅ indexPatch → indexPath
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let favorite = favorites[indexPath.row]
        cell.textLabel?.text = favorite.shopName
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = ShopDetailVC()
        vc.shopId = favorites[indexPath.row].shopId
        vc.shopName = favorites[indexPath.row].shopName   // ✅ 추가!
        navigationController?.pushViewController(vc, animated: true)
    }
}
