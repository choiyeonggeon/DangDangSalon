//
//  ShopDetailVC.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/16/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

class ShopDetailVC: UIViewController {
    
    // MARK: - UI
    private let scrollerView = UIScrollView()
    private let contentView = UIView()
    
    var shopId: String?
    var shopName: String?
    
    private var shop: Shop?
    private var reviews: [Review] = []
    
    private let db = Firestore.firestore()
    private var isFavorite = false
    
    private var reviewTableHeight: Constraint? // 🔹 테이블 동적 높이 업데이트용
    
    private let favoriteButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "heart"), for: .normal)
        btn.tintColor = .systemGray
        btn.contentHorizontalAlignment = .fill
        btn.contentVerticalAlignment = .fill
        return btn
    }()
    
    private let shopImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "sampleShop")
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 16
        iv.clipsToBounds = true
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 24)
        return label
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        return label
    }()
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 15)
        label.textColor = .darkGray
        return label
    }()
    
    private let introTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "샵 소개"
        label.font = .boldSystemFont(ofSize: 18)
        return label
    }()
    
    private let introLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 15)
        label.numberOfLines = 0
        return label
    }()
    
    private let infoTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "운영 정보"
        label.font = .boldSystemFont(ofSize: 18)
        return label
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 15)
        label.numberOfLines = 0
        return label
    }()
    
    private let reviewTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "리뷰"
        label.font = .boldSystemFont(ofSize: 18)
        return label
    }()
    
    private let moreReviewButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("리뷰 더보기", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.setTitleColor(.systemBlue, for: .normal)
        return btn
    }()
    
    private let reviewTableView: UITableView = {
        let tv = UITableView()
        tv.register(ReviewCell.self, forCellReuseIdentifier: "ReviewCell")
        tv.isScrollEnabled = false
        tv.separatorStyle = .none
        tv.rowHeight = 60
        return tv
    }()
    
    private let reserveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("예약하기", for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.backgroundColor = .systemBlue
        btn.tintColor = .white
        btn.layer.cornerRadius = 12
        return btn
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = shopName ?? "미용샵 상세"
        view.backgroundColor = .systemBackground
        setupLayout()
        
        reviewTableView.dataSource = self
        reserveButton.addTarget(self, action: #selector(reserveButtonTapped), for: .touchUpInside)
        moreReviewButton.addTarget(self, action: #selector(showAllReviews), for: .touchUpInside)
        favoriteButton.addTarget(self, action: #selector(toggleFavorite), for: .touchUpInside)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fetchReviews),
            name: .reviewAdded,
            object: nil
        )
        
        fetchShopDetail()
        checkIfFavorite()
        fetchReviews()
        
        updateReserveButtonState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateReserveButtonState()
    }
    
    @objc private func reserveButtonTapped() {
        // shop은 Optional이라 안전하게 풀어줘야 함
        guard let shop = self.shop else { return }
        
        // id는 Optional 아닐 가능성이 높으니까 그냥 바로 사용
        let shopId = shop.id  // 여기서 에러 안 남 (String이라고 가정)
        
        fetchMenus(for: shopId) { menus in
            let vc = ReservationVC()
            vc.shopId = shopId
            vc.shopName = shop.name
            vc.menus = menus
            
            vc.modalPresentationStyle = .pageSheet
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            }
            self.present(vc, animated: true)
        }
    }
    
    @objc private func writeReviewTapped() {
        let vc = ReviewWriteVC()
        vc.shopId = self.shopId
        vc.modalTransitionStyle = .partialCurl
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }
    
    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(scrollerView)
        view.addSubview(reserveButton)
        scrollerView.addSubview(contentView)
        
        // 스크롤뷰는 버튼 위까지
        scrollerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(reserveButton.snp.top).offset(-8)
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollerView.snp.width)
        }
        
        [shopImageView, nameLabel, favoriteButton, ratingLabel, locationLabel,
         introTitleLabel, introLabel, infoTitleLabel, infoLabel,
         reviewTitleLabel, moreReviewButton, reviewTableView]
            .forEach { contentView.addSubview($0) }
        
        shopImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(200)
        }
        
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(shopImageView.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalTo(favoriteButton.snp.leading).offset(-8)
        }
        
        favoriteButton.snp.makeConstraints {
            $0.centerY.equalTo(nameLabel)
            $0.trailing.equalToSuperview().inset(20)
            $0.width.height.equalTo(28)
        }
        
        ratingLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(20)
        }
        
        locationLabel.snp.makeConstraints {
            $0.top.equalTo(ratingLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        introTitleLabel.snp.makeConstraints {
            $0.top.equalTo(locationLabel.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(20)
        }
        
        introLabel.snp.makeConstraints {
            $0.top.equalTo(introTitleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        infoTitleLabel.snp.makeConstraints {
            $0.top.equalTo(introLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        infoLabel.snp.makeConstraints {
            $0.top.equalTo(infoTitleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        reviewTitleLabel.snp.makeConstraints {
            $0.top.equalTo(infoLabel.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(20)
        }
        
        moreReviewButton.snp.makeConstraints {
            $0.centerY.equalTo(reviewTitleLabel)
            $0.trailing.equalToSuperview().inset(20)
        }
        
        reviewTableView.snp.makeConstraints {
            $0.top.equalTo(reviewTitleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            reviewTableHeight = $0.height.equalTo(0).constraint // 나중에 fetchReviews에서 업데이트
            $0.bottom.equalToSuperview().offset(-40) // 마지막 여백
        }
        
        reserveButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(56)
        }
        favoriteButton.isUserInteractionEnabled = true
        scrollerView.isUserInteractionEnabled = true
        contentView.isUserInteractionEnabled = true
        contentView.bringSubviewToFront(favoriteButton)
    }
    
    // MARK: - Firestore
    private func fetchShopDetail() {
        guard let shopId = shopId else { return }
        db.collection("shops").document(shopId).getDocument { snapshot, error in
            if let error = error {
                print("샵 상세 불러오기 실패:", error.localizedDescription)
                return
            }
            guard let document = snapshot,
                  document.exists,
                  let shop = Shop(document: document) else {
                print("해당 문서없음")
                return
            }
            self.shop = shop
            self.shopName = shop.name
            
            DispatchQueue.main.async {
                self.updateUI(with: shop)
            }
        }
    }
    
    // 가게별 메뉴 목록 불러오기 (ReservationVC에 넘김)
    private func fetchMenus(for shopId: String,
                            completion: @escaping ([(name: String, price: Int)]) -> Void) {
        db.collection("shops").document(shopId).collection("menus").getDocuments { snapshot, error in
            if let error = error {
                print("메뉴 불러오기 실패:", error.localizedDescription)
                completion([])
                return
            }
            
            let menus: [(name: String, price: Int)] = snapshot?.documents.compactMap { doc in
                guard let name = doc["name"] as? String,
                      let price = doc["price"] as? Int else { return nil }
                return (name, price)
            } ?? []
            
            completion(menus)
        }
    }
    
    private func updateUI(with shop: Shop) {
        nameLabel.text = shop.name
        ratingLabel.text = "⭐️ \(String(format: "%.1f", shop.rating)) (\(reviews.count) 리뷰)"
        locationLabel.text = shop.address ?? "주소 정보 없음"
        
        introLabel.text = shop.intro ?? "소개글이 없습니다."
        
        infoLabel.text = """
        📅 영업시간: \(shop.openTime ?? "미정") ~ \(shop.closeTime ?? "미정")
        ☎️ 전화번호: \(shop.phone ?? "정보 없음")
        📍 주소: \(shop.address ?? "정보 없음")
        """
        
        if let imageURL = shop.imageURL,
           let url = URL(string: imageURL) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        self.shopImageView.image = UIImage(data: data)
                    }
                }
            }
        }
    }
    
    private func checkIfFavorite() {
        guard let userId = Auth.auth().currentUser?.uid,
              let shopId = shopId else { return }
        
        db.collection("users")
            .document(userId)
            .collection("favorites")
            .document(shopId)
            .getDocument { [weak self] snapshot, _ in
                guard let self = self else { return }
                self.isFavorite = snapshot?.exists ?? false
                DispatchQueue.main.async {
                    self.updateFavoriteButton()
                }
            }
    }
    
    @objc private func toggleFavorite() {
        guard let userId = Auth.auth().currentUser?.uid else {
            let alert = UIAlertController(
                title: "로그인 필요",
                message: "즐겨찾기 기능은 로그인 후 이용 가능합니다.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "로그인하기", style: .default, handler: { _ in
                let loginVC = LoginVC()
                loginVC.modalPresentationStyle = .fullScreen
                self.present(loginVC, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            present(alert, animated: true)
            return
        }
        guard let shopId = shopId,
              let shopName = shopName else { return }
        
        let favRef = db.collection("users")
            .document(userId)
            .collection("favorites")
            .document(shopId)
        
        if isFavorite {
            favRef.delete { [weak self] error in
                guard let self = self else { return }
                if error == nil {
                    self.isFavorite = false
                    self.updateFavoriteButton()
                    self.animateHeart()
                }
            }
        } else {
            favRef.setData([
                "shopId": shopId,
                "shopName": shopName,
                "createdAt": Timestamp(date: Date())
            ]) { [weak self] error in
                guard let self = self else { return }
                if error == nil {
                    self.isFavorite = true
                    self.updateFavoriteButton()
                    self.animateHeart()
                }
            }
        }
    }
    
    private func updateFavoriteButton() {
        DispatchQueue.main.async {
            // ⚙️ 기본 설정 초기화 (configuration 남아있으면 tintColor 안 먹힘)
            self.favoriteButton.configuration = nil
            self.favoriteButton.setTitle(nil, for: .normal)
            self.favoriteButton.contentHorizontalAlignment = .fill
            self.favoriteButton.contentVerticalAlignment = .fill
            
            let imageName = self.isFavorite ? "heart.fill" : "heart"
            let color: UIColor = self.isFavorite ? .systemRed : .systemGray
            
            let image = UIImage(systemName: imageName)?.withRenderingMode(.alwaysTemplate)
            self.favoriteButton.setImage(image, for: .normal)
            self.favoriteButton.tintColor = color
            
            print("🎨 버튼 색상 갱신 완료:", self.isFavorite ? "❤️ 빨강" : "🤍 회색")
        }
    }
    
    // MARK: - 하트 애니메이션
    private func animateHeart() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        UIView.animate(withDuration: 0.15,
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: {
            self.favoriteButton.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        }) { _ in
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 2,
                           options: [.curveEaseOut],
                           animations: {
                self.favoriteButton.transform = .identity
            })
        }
    }
    
    @objc private func fetchReviews() {
        guard let shopId = shopId else { return }
        
        db.collection("shops").document(shopId).collection("reviews").getDocuments { snapshot, error in
            if let error = error {
                print("리뷰 불러오기 실패:", error.localizedDescription)
                return
            }
            guard let documents = snapshot?.documents else { return }
            let allReviews = documents.compactMap { Review(document: $0) }
            self.reviews = Array(allReviews.prefix(4)) // 미리보기 4개
            
            DispatchQueue.main.async {
                self.reviewTableView.reloadData()
                self.reviewTableHeight?.update(offset: self.reviews.count * 60)
            }
        }
    }
    
    private func updateReserveButtonState() {
        if Auth.auth().currentUser == nil {
            reserveButton.backgroundColor = .systemGray4
            reserveButton.isEnabled = false
            reserveButton.setTitle("로그인 후 예약 가능", for: .normal)
        } else {
            reserveButton.backgroundColor = .systemBlue
            reserveButton.isEnabled = true
            reserveButton.setTitle("예약하기", for: .normal)
        }
    }
    
    @objc private func showAllReviews() {
        let vc = ReviewListVC()
        vc.shopId = self.shopId
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Review TableView
extension ShopDetailVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviews.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "ReviewCell",
            for: indexPath
        ) as? ReviewCell else {
            return UITableViewCell()
        }
        cell.configure(with: reviews[indexPath.row])
        return cell
    }
}

// MARK: - ReviewCell
final class ReviewCell: UITableViewCell {
    private let userLabel = UILabel()
    private let ratingLabel = UILabel()
    private let contentLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        userLabel.font = .boldSystemFont(ofSize: 15)
        ratingLabel.font = .systemFont(ofSize: 13)
        ratingLabel.textColor = .systemGray
        contentLabel.font = .systemFont(ofSize: 14)
        contentLabel.numberOfLines = 0
        
        let topRow = UIStackView(arrangedSubviews: [userLabel, ratingLabel])
        topRow.axis = .horizontal
        topRow.spacing = 8
        
        [topRow, contentLabel].forEach { contentView.addSubview($0) }
        
        topRow.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(8)
        }
        contentLabel.snp.makeConstraints {
            $0.top.equalTo(topRow.snp.bottom).offset(4)
            $0.leading.trailing.bottom.equalToSuperview().inset(8)
        }
    }
    
    func configure(with review: Review) {
        userLabel.text = review.nickname
        ratingLabel.text = "⭐️ \(review.rating)"
        contentLabel.text = review.content
    }
}
