//
//  HomeVC.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/15/25.
//

import UIKit
import SnapKit
import FirebaseFirestore
import CoreLocation

enum ShopSortType {
    case distance
    case price
    case rating
    case reviewCount
}

class HomeVC: UIViewController,
              UICollectionViewDataSource,
              UICollectionViewDelegate,
              UISearchBarDelegate,
              CLLocationManagerDelegate {
    
    // MARK: - UI
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
    
    private var categoryButtons: [UIButton] = []
    
    private let categoryStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        return stack
    }()
    
    private let categoryContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        return stack
    }()
    
    private let recommendedLabel: UILabel = {
        let label = UILabel()
        label.text = "추천 미용샵"
        label.font = .boldSystemFont(ofSize: 18)
        return label
    }()
    
    private let emptyRecommendedLabel: UILabel = {
        let lb = UILabel()
        lb.text = "아직 등록된 추천 미용실이 없어요."
        lb.font = .systemFont(ofSize: 14)
        lb.textAlignment = .center
        lb.textColor = .secondaryLabel
        lb.isHidden = true
        return lb
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
    
    private let emptyNearbyLabel: UILabel = {
        let lb = UILabel()
        lb.text = "주변에 미용샵이 없습니다.\n입점 미용샵을 빠르게 늘리고 있어요!"
        lb.numberOfLines = 0
        lb.textAlignment = .center
        lb.font = .systemFont(ofSize: 14)
        lb.textColor = .secondaryLabel
        lb.isHidden = true
        return lb
    }()
    
    private let sortInlineButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("정렬 ⌄", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.layer.cornerRadius = 16
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.systemGray4.cgColor
        return btn
    }()
    
    private let nearbyTableView: UITableView = {
        let tv = UITableView()
        tv.register(ShopCell.self, forCellReuseIdentifier: "ShopCell")
        tv.separatorStyle = .none
        tv.rowHeight = 64
        return tv
    }()
    
    // MARK: - Data
    private let locationManager = CLLocationManager()
    private var userLocation: CLLocation?
    private var recommendedShops: [Shop] = []
    private var nearbyShops: [Shop] = []
    private var allShops: [Shop] = []
    private var selectedCategory: String = "전체"
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCategoryButtons()
        setupNotificationButton()
        
        sortInlineButton.addTarget(self, action: #selector(sortTapped), for: .touchUpInside)
        
        // 🔥 위치 권한 요청
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        recommendedCollectionView.dataSource = self
        recommendedCollectionView.delegate = self
        recommendedCollectionView.register(RecommendedShopCell.self, forCellWithReuseIdentifier: "RecommendedShopCell")
        
        nearbyTableView.dataSource = self
        nearbyTableView.delegate = self
        
        searchBar.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        fetchShops()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        [appNameLabel, titleLabel, searchBar, categoryContainer, recommendedLabel,
         recommendedCollectionView, emptyRecommendedLabel, nearbyLabel, emptyNearbyLabel, nearbyTableView].forEach {
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
        
        categoryContainer.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(40)
        }
        
        categoryContainer.addArrangedSubview(categoryStack)
        categoryContainer.addArrangedSubview(sortInlineButton)
        
        sortInlineButton.snp.makeConstraints {
            $0.width.equalTo(72)
        }
        
        recommendedLabel.snp.makeConstraints {
            $0.top.equalTo(categoryStack.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(20)
        }
        
        emptyRecommendedLabel.snp.makeConstraints {
            $0.top.equalTo(recommendedLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
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
        
        emptyNearbyLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(nearbyLabel.snp.bottom).offset(40)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        nearbyTableView.snp.makeConstraints {
            $0.top.equalTo(nearbyLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    private func setupNotificationButton() {
        let bellButton = UIBarButtonItem(
            image: UIImage(systemName: "bell"),
            style: .plain,
            target: self,
            action: #selector(notificationTapped)
        )
        
        bellButton.tintColor = UIColor.label
        navigationItem.rightBarButtonItem = bellButton
    }
    
    @objc private func notificationTapped() {
        let vc = NotificationInboxVC()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func sortTapped() {
        let sheet = UIAlertController(title: "정렬 기준", message: nil, preferredStyle: .actionSheet)
        
        sheet.addAction(UIAlertAction(title: "가까운 순", style: .default) { _ in
            self.sortShops(by: .distance)
        })
        
        sheet.addAction(UIAlertAction(title: "가격 낮은 순", style: .default) { _ in
            self.sortShops(by: .price)
        })
        
        sheet.addAction(UIAlertAction(title: "별점 높은 순", style: .default) { _ in
            self.sortShops(by: .rating)
        })
        
        sheet.addAction(UIAlertAction(title: "리뷰 많은 순", style: .default) { _ in
            self.sortShops(by: .reviewCount)
        })
        
        sheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        present(sheet, animated: true)
    }
    
    private func sortShops(by type: ShopSortType) {
        switch type {
            
        case .distance:
            nearbyShops.sort {
                ($0.distanceMeter ?? Int.max) < ($1.distanceMeter ?? Int.max)
            }
            
        case .price:
            nearbyShops.sort {
                ($0.minPrice ?? Int.max) < ($1.minPrice ?? Int.max)
            }
            
        case .rating:
            nearbyShops.sort {
                $0.rating > $1.rating
            }
            
        case .reviewCount:
            nearbyShops.sort {
                $0.reviewCount > $1.reviewCount
            }
        }
        
        nearbyTableView.reloadData()
    }
    
    // MARK: - 카테고리 버튼 생성
    private func setupCategoryButtons() {
        let categories = ["전체", "소형견", "중형견", "대형견"]
        
        categoryButtons = categories.map { title in
            let btn = UIButton(type: .system)
            btn.setTitle(title, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            btn.layer.cornerRadius = 16
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor.systemGray4.cgColor
            btn.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
            return btn
        }
        
        categoryButtons.forEach { categoryStack.addArrangedSubview($0) }
        updateCategoryButtonAppearance(selected: "전체")
    }
    
    @objc private func categoryTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        selectedCategory = title
        updateCategoryButtonAppearance(selected: title)
        
        if title == "전체" {
            nearbyShops = allShops
        } else {
            nearbyShops = allShops.filter { shop in
                shop.categories?.contains(title) ?? false
            }
        }
        nearbyTableView.reloadData()
    }
    
    private func updateCategoryButtonAppearance(selected: String) {
        for button in categoryButtons {
            if button.title(for: .normal) == selected {
                button.backgroundColor = .systemBlue
                button.setTitleColor(.white, for: .normal)
                button.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                button.backgroundColor = .clear
                button.setTitleColor(.label, for: .normal)
                button.layer.borderColor = UIColor.systemGray4.cgColor
            }
        }
    }
    
    // MARK: - Firestore
    private func fetchShops() {
        let db = Firestore.firestore()
        
        db.collection("shops").getDocuments(completion: { snapshot, error in
            if let error = error {
                print("Firestore 불러오기 실패:", error)
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            // Shop 변환
            self.allShops = documents.compactMap { Shop(document: $0) }
            
            // NEW 계산
            let now = Date()
            let threshold = Calendar.current.date(byAdding: .day, value: -30, to: now)!
            
            self.allShops = self.allShops.map { shop in
                var s = shop
                if let createdAt = shop.createdAt {
                    s.isNew = createdAt >= threshold
                }
                return s
            }
            
            self.recommendedShops = self.allShops.filter { $0.isRecommended }
            self.nearbyShops = self.allShops
            
            DispatchQueue.main.async {
                self.sortShopsByDistanceIfPossible()
                self.updateEmptyStates()
            }
        })
    }
    
    private func sortShopsByDistanceIfPossible() {
        guard let userLocation = userLocation else { return }
        
        // 거리 계산
        allShops = allShops.map { shop in
            var s = shop
            if let lat = shop.latitude, let lng = shop.longitude {
                let shopLocation = CLLocation(latitude: lat, longitude: lng)
                let distance = userLocation.distance(from: shopLocation) // meter
                s.distanceMeter = Int(distance)
            } else {
                s.distanceMeter = Int.max  // 좌표 없는 샵 = 가장 뒤로
            }
            return s
        }
        
        // 가까운 순 정렬 (오름차순)
        allShops.sort {
            ($0.distanceMeter ?? Int.max) < ($1.distanceMeter ?? Int.max)
        }
        
        // 섹션별로 나누기
        nearbyShops = allShops
        
        recommendedShops = allShops.filter { $0.isRecommended }
        
        // UI 갱신
        nearbyTableView.reloadData()
        recommendedCollectionView.reloadData()
    }
    
    private func updateEmptyStates() {
        emptyRecommendedLabel.isHidden = !recommendedShops.isEmpty
        recommendedCollectionView.isHidden = recommendedShops.isEmpty
        
        emptyNearbyLabel.isHidden = !nearbyShops.isEmpty
        nearbyTableView.isHidden = nearbyShops.isEmpty
    }
    
    // MARK: - 검색
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            nearbyShops = allShops
            nearbyTableView.reloadData()
            return
        }
        
        let lower = searchText.lowercased()
        nearbyShops = allShops.filter {
            $0.name.lowercased().contains(lower) ||
            ($0.address?.lowercased().contains(lower) ?? false)
        }
        nearbyTableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - CollectionView
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        recommendedShops.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecommendedShopCell", for: indexPath) as? RecommendedShopCell else {
            return UICollectionViewCell()
        }
        let shop = recommendedShops[indexPath.item]
        cell.configure(with: shop)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = ShopDetailVC()
        vc.shopId = recommendedShops[indexPath.item].id
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - TableView
extension HomeVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        nearbyShops.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShopCell", for: indexPath) as? ShopCell else {
            return UITableViewCell()
        }
        let shop = nearbyShops[indexPath.row]
        cell.configure(with: shop)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = ShopDetailVC()
        vc.shopId = nearbyShops[indexPath.row].id
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension HomeVC {
    // 위치 권한 변경됐을 때
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    // 위치 업데이트 받을 때
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        userLocation = loc
        
        // 이미 샵 목록이 있으면, 거리 기준으로 한 번 정렬해준다
        sortShopsByDistanceIfPossible()
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("위치 가져오기 실패:", error.localizedDescription)
    }
}

