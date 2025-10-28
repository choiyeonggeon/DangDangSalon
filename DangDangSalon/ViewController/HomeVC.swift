//
//  HomeVC.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/15/25.
//

import UIKit
import SnapKit
import FirebaseFirestore

class HomeVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    private let appNameLabel: UILabel = {
        let label = UILabel()
        label.text = "댕살롱"
        label.font = UIFont(name: "GmarketSansBold", size: 34)
        label.textColor = UIColor.systemBlue
        label.textAlignment = .left
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "🐾 근처 미용샵 찾기"
        label.font = .boldSystemFont(ofSize: 24)
        return label
    }()
    
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "샵 이름 또는 지역 검색"
        sb.searchBarStyle = .minimal
        return sb
    }()
    
    private let categoryStack: UIStackView = {
        let titles = ["전체", "소형견", "중형견", "대형견"]
        let buttons = titles.map { title -> UIButton in
            let btn = UIButton(type: .system)
            btn.setTitle(title, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            btn.layer.cornerRadius = 16
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.systemGray4.cgColor
            return btn
        }
        
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        return stack
    }()
    
    private let recommendedLabel: UILabel = {
        let label = UILabel()
        label.text = "추천 미용샵"
        label.font = .boldSystemFont(ofSize: 18)
        return label
    }()
    
    private let recommendedCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.itemSize = CGSize(width: 160, height: 135)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        return cv
    }()
    
    private let nearbyLabel: UILabel = {
        let label = UILabel()
        label.text = "가까운 미용샵"
        label.font = .boldSystemFont(ofSize: 18)
        return label
    }()
    
    private let nearbyTableView: UITableView = {
        let tv = UITableView()
        tv.register(ShopCell.self, forCellReuseIdentifier: "ShopCell")
        tv.separatorStyle = .none
        tv.rowHeight = 64
        return tv
    }()
    
    private var recommendedShops: [Shop] = []
    private var nearbyShops: [Shop] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        recommendedCollectionView.dataSource = self
        recommendedCollectionView.delegate = self
        recommendedCollectionView.register(RecommendedShopCell.self, forCellWithReuseIdentifier: "RecommendedShopCell")
        
        nearbyTableView.dataSource = self
        nearbyTableView.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        fetchShops()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        [appNameLabel, titleLabel, searchBar, categoryStack, recommendedLabel,
         recommendedCollectionView, nearbyLabel, nearbyTableView].forEach {
            view.addSubview($0)
        }
        
        appNameLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(-10)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(appNameLabel.snp.bottom).offset(25)
            $0.leading.equalToSuperview().offset(20)
        }
        
        searchBar.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        categoryStack.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(40)
        }
        
        recommendedLabel.snp.makeConstraints {
            $0.top.equalTo(categoryStack.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(20)
        }
        
        recommendedCollectionView.snp.makeConstraints {
            $0.top.equalTo(recommendedLabel.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(140)
        }
        
        nearbyLabel.snp.makeConstraints {
            $0.top.equalTo(recommendedCollectionView.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().inset(20)
        }
        
        nearbyTableView.snp.makeConstraints {
            $0.top.equalTo(nearbyLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(0)
        }
    }
    
    private func fetchShops() {
        let db = Firestore.firestore()
        
        db.collection("shops").getDocuments { snapshot, error in
            if let error = error {
                print("Firestore 불러오기 실패:", error)
                return
            }
            
            guard let docments = snapshot?.documents else {
                print("Firestore snapshot이 비어있습니다.")
                return
            }
            
            let shops = docments.compactMap { Shop(document: $0) }
            
            self.recommendedShops = shops.filter { $0.isRecommended }
            self.nearbyShops = shops
            
            DispatchQueue.main.async {
                self.recommendedCollectionView.reloadData()
                self.nearbyTableView.reloadData()
            }
            
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - CollectionView DataSource
extension HomeVC {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recommendedShops.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecommendedShopCell", for: indexPath) as? RecommendedShopCell else {
            return UICollectionViewCell()
        }
        let shop = recommendedShops[indexPath.item]
        cell.configure(with: shop)
        return cell
    }
}

// MARK: - CollectionView Delegate
extension HomeVC {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = ShopDetailVC()
        vc.shopId = recommendedShops[indexPath.item].id
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - TableView DataSource & Delgate
extension HomeVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nearbyShops.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShopCell", for: indexPath) as? ShopCell else {
            return UITableViewCell()
        }
        let shop = nearbyShops[indexPath.row]
        cell.configure(with: shop.name)
        return cell
    }
}

// MARK: - TableView Delegate
extension HomeVC {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = ShopDetailVC()
        vc.shopId = nearbyShops[indexPath.row].id
        navigationController?.pushViewController(vc, animated: true)
    }
}

