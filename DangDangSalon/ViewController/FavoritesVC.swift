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
    
    // MARK: - UI
    private let headerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset = CGSize(width: 0, height: 3)
        v.layer.shadowRadius = 6
        return v
    }()
    
    private let appNameLabel: UILabel = {
        let lb = UILabel()
        lb.text = "댕살롱"
        lb.textColor = UIColor.systemBlue
        lb.font = UIFont(name: "GmarketSansBold", size: 34)
        return lb
    }()
    
    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "🐾 즐겨찾기"
        lb.textColor = .label
        lb.font = .boldSystemFont(ofSize: 22)
        return lb
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.separatorStyle = .none
        tv.backgroundColor = .clear
        tv.showsVerticalScrollIndicator = false
        tv.register(FavoriteCell.self, forCellReuseIdentifier: "FavoriteCell")
        return tv
    }()
    
    private let emptyView: UIView = {
        let v = UIView()
        v.isHidden = true
        
        let img = UIImageView(image: UIImage(systemName: "heart.circle.fill"))
        img.tintColor = .systemGray4
        img.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = "찜한 매장이 아직 없어요 💙"
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 17)
        
        let stack = UIStackView(arrangedSubviews: [img, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        v.addSubview(stack)
        stack.snp.makeConstraints { $0.center.equalToSuperview() }
        
        return v
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "즐겨찾기"
        
        tableView.dataSource = self
        tableView.delegate = self
        
        setupLayout()
        fetchFavorites()
    }
    
    // MARK: - Layout
    private func setupLayout() {
        [headerView, tableView, emptyView].forEach { view.addSubview($0) }
        [appNameLabel, titleLabel].forEach { headerView.addSubview($0) }
        
        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(110)
        }
        appNameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.leading.equalToSuperview().inset(20)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(appNameLabel.snp.bottom).offset(8)
            $0.leading.equalTo(appNameLabel)
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
        }
        emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    // MARK: - Firestore
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
                    if self.favorites.isEmpty {
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
}

// MARK: - TableView
extension FavoritesVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        favorites.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "FavoriteCell",
            for: indexPath
        ) as? FavoriteCell else {
            return UITableViewCell()
        }
        let favorite = favorites[indexPath.row]
        cell.configure(shopName: favorite.shopName)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = ShopDetailVC()
        vc.shopId = favorites[indexPath.row].shopId
        vc.shopName = favorites[indexPath.row].shopName
        navigationController?.pushViewController(vc, animated: true)
    }
}
