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
    private let pageControl = UIPageControl()
    private let imageScrollerView = UIScrollView()
    private let scrollerView = UIScrollView()
    private let contentView = UIView()
    
    var shopId: String?
    var shopName: String?
    
    private var shop: Shop?
    private var reviews: [Review] = []
    
    private let db = Firestore.firestore()
    private var isFavorite = false
    
    private var reviewTableHeight: Constraint?
    
    private let favoriteButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "heart"), for: .normal)
        btn.tintColor = .systemGray
        btn.contentHorizontalAlignment = .fill
        btn.contentVerticalAlignment = .fill
        return btn
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
    
    private let openStatusBadge: UILabel = {
        let lb = UILabel()
        lb.text = "영업 중"
        lb.textColor = .white
        lb.backgroundColor = .systemGreen
        lb.font = .systemFont(ofSize: 13, weight: .bold)
        lb.textAlignment = .center
        lb.layer.cornerRadius = 8
        lb.clipsToBounds = true
        lb.isHidden = true
        return lb
    }()
    
    private let callIconButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "phone.fill"), for: .normal)
        btn.tintColor = .systemGreen
        btn.contentHorizontalAlignment = .fill
        btn.contentVerticalAlignment = .fill
        return btn
    }()
    
    private let mapIconButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "map.fill"), for: .normal)
        btn.tintColor = .systemBlue
        btn.contentHorizontalAlignment = .fill
        btn.contentVerticalAlignment = .fill
        return btn
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
        
        observeShopRating()
        updateReserveButtonState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateReserveButtonState()
    }
    
    @objc private func reserveButtonTapped() {
        guard let shop = self.shop else { return }
        
        let shopId = shop.id
        
        fetchMenus(for: shopId) { menus in
            let vc = ReservationVC()
            vc.shopId = shopId
            vc.shopName = shop.name
            vc.menus = menus
            vc.shopAddress = shop.address
            
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
        contentView.addSubview(openStatusBadge)
        contentView.addSubview(callIconButton)
        contentView.addSubview(mapIconButton)
        
        // 스크롤뷰는 버튼 위까지
        scrollerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(reserveButton.snp.top).offset(-8)
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollerView.snp.width)
        }
        
        [imageScrollerView, pageControl, nameLabel, favoriteButton, ratingLabel, locationLabel,
         introTitleLabel, introLabel, infoTitleLabel, infoLabel,
         reviewTitleLabel, moreReviewButton, reviewTableView]
            .forEach { contentView.addSubview($0) }
        
        imageScrollerView.isPagingEnabled = true
        imageScrollerView.showsHorizontalScrollIndicator = false
        imageScrollerView.layer.cornerRadius = 10
        imageScrollerView.clipsToBounds = true
        
        imageScrollerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(240)
        }
        
        pageControl.snp.makeConstraints {
            $0.top.equalTo(imageScrollerView.snp.bottom).offset(6)
            $0.centerX.equalToSuperview()
        }
        
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(imageScrollerView.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalTo(favoriteButton.snp.leading).offset(-8)
        }
        
        favoriteButton.snp.makeConstraints {
            $0.centerY.equalTo(nameLabel)
            $0.trailing.equalToSuperview().inset(20)
            $0.width.height.equalTo(28)
        }
        
        callIconButton.snp.makeConstraints {
            $0.centerY.equalTo(nameLabel)
            $0.trailing.equalTo(favoriteButton.snp.leading).offset(-12)
            $0.width.height.equalTo(24)
        }
        
        mapIconButton.snp.makeConstraints {
            $0.centerY.equalTo(nameLabel)
            $0.trailing.equalTo(callIconButton.snp.leading).offset(-12)
            $0.width.height.equalTo(24)
        }
        
        ratingLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(20)
        }
        
        openStatusBadge.snp.makeConstraints {
            $0.leading.equalTo(ratingLabel.snp.trailing).offset(8)
            $0.centerY.equalTo(ratingLabel)
            $0.height.equalTo(20)
            $0.width.greaterThanOrEqualTo(50)
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
            reviewTableHeight = $0.height.equalTo(0).constraint
            $0.bottom.equalToSuperview().offset(-40)
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
        callIconButton.addTarget(self, action: #selector(callShopOwner), for: .touchUpInside)
        mapIconButton.addTarget(self, action: #selector(openKakaoMap), for: .touchUpInside)
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
        updateOpenStatus(open: shop.openTime, close: shop.closeTime)
        
        nameLabel.text = shop.name
        ratingLabel.text = "⭐️ \(String(format: "%.1f", shop.rating)) (\(shop.reviewCount) 리뷰)"
        locationLabel.text = shop.address ?? "주소 정보 없음"
        
        introLabel.text = shop.intro ?? "소개글이 없습니다."
        infoLabel.text = """
        영업시간: \(shop.openTime ?? "미정") ~ \(shop.closeTime ?? "미정")
        영업일: \(shop.workingDays ?? "정보 없음")
        
        전화번호: \(shop.phone ?? "정보 없음")
        주소: \(shop.address ?? "정보 없음")
        
        대표자명: \(shop.ownerName ?? "정보 없음")
        사업자등록번호: \(shop.businessNumber ?? "정보 없음")
        """
        
        setupImageScrollView(with: shop.imageURLs)
    }
    
    private func updateOpenStatus(open: String?, close: String?) {
        guard let o = open, let c = close else {
            openStatusBadge.isHidden = true
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let openDate = formatter.date(from: o),
              let closeDate = formatter.date(from: c) else {
            openStatusBadge.isHidden = true
            return
        }
        
        let now = Date()
        let cal = Calendar.current
        
        // 오늘 날짜로 매핑
        let todayOpen = cal.date(
            bySettingHour: cal.component(.hour, from: openDate),
            minute: cal.component(.minute, from: openDate),
            second: 0,
            of: now
        )!
        
        let todayClose = cal.date(
            bySettingHour: cal.component(.hour, from: closeDate),
            minute: cal.component(.minute, from: closeDate),
            second: 0,
            of: now
        )!
        
        if now >= todayOpen && now <= todayClose {
            openStatusBadge.text = "영업 중"
            openStatusBadge.backgroundColor = .systemGreen
        } else {
            openStatusBadge.text = "영업 종료"
            openStatusBadge.backgroundColor = .systemGray
        }
        
        openStatusBadge.isHidden = false
    }
    
    private func setupImageScrollView(with urls: [String]?) {
        imageScrollerView.subviews.forEach { $0.removeFromSuperview() }
        
        guard let urls = urls, !urls.isEmpty else {
            let iv = UIImageView(image: UIImage(named: "sampleShop"))
            iv.contentMode = .scaleAspectFill
            iv.frame = CGRect(x: 0, y: 0,
                              width: view.frame.width - 40,
                              height: 240)
            
            iv.clipsToBounds = true
            imageScrollerView.addSubview(iv)
            imageScrollerView.contentSize = iv.frame.size
            pageControl.numberOfPages = 1
            return
        }
        
        for (index, urlStr) in urls.enumerated() {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.backgroundColor = .systemGray6
            
            if let url = URL(string: urlStr) {
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url),
                       let img = UIImage(data: data) {
                        DispatchQueue.main.async {
                            iv.image = img
                        }
                    }
                }
            }
            
            let xPos = CGFloat(index) * (view.frame.width - 40)
            iv.frame = CGRect(x: xPos, y: 0, width: view.frame.width - 40, height: 240)
            imageScrollerView.addSubview(iv)
        }
        
        imageScrollerView.contentSize = CGSize(
            width: (view.frame.width - 40) * CGFloat(urls.count), height: 240
        )
        
        imageScrollerView.delegate = self
        pageControl.numberOfPages = urls.count
        pageControl.currentPage = 0
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
    
    @objc private func callShopOwner() {
        guard let phone = shop?.phone,
              !phone.isEmpty else {
            let alert = UIAlertController(
                title: "전화 불가",
                message: "등록된 전화번호가 없습니다.",
                preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }
        
        let cleaned = phone
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        if let url = URL(string: "tel://\(cleaned)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            let alert = UIAlertController(title: "호출 실패",
                                          message: "전화 앱을 열 수 없습니다.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        }
    }
    
    @objc private func openKakaoMap() {
        guard let addr = shop?.address else {
            let alert = UIAlertController(title: "주소 없음",
                                          message: "등록된 주소가 없어 길찾기가 불가능합니다.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }
        
        let encoded = addr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // 카카오맵 앱
        if let appURL = URL(string: "kakaomap://search?q=\(encoded)"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
            return
        }
        
        // 카카오맵 웹
        if let webURL = URL(string: "https://map.kakao.com/?q=\(encoded)") {
            UIApplication.shared.open(webURL)
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
            
            self.favoriteButton.configuration = nil
            self.favoriteButton.setTitle(nil, for: .normal)
            self.favoriteButton.contentHorizontalAlignment = .fill
            self.favoriteButton.contentVerticalAlignment = .fill
            
            let imageName = self.isFavorite ? "heart.fill" : "heart"
            let color: UIColor = self.isFavorite ? .systemRed : .systemGray
            
            let image = UIImage(systemName: imageName)?.withRenderingMode(.alwaysTemplate)
            self.favoriteButton.setImage(image, for: .normal)
            self.favoriteButton.tintColor = color
            
        }
    }
    
    private func observeShopRating() {
        guard let shopId = shopId else { return }
        
        db.collection("shops").document(shopId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let data = snapshot?.data() else { return }
                
                let newRating = data["rating"] as? Double ?? 0.0
                let reviewCount = data["reviewCount"] as? Int ?? self.reviews.count
                
                DispatchQueue.main.async {
                    self.ratingLabel.text = "⭐️ \(String(format: "%.1f", newRating)) (\(reviewCount) 리뷰)"
                }
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
    
    private let blindedLabel: UILabel = {
        let lb = UILabel()
        lb.text = "(!) 사장님의 요청에 따라 30일 블라인드 처리되었습니다."
        lb.font = .systemFont(ofSize: 13)
        lb.textColor = .systemGray
        lb.numberOfLines = 0
        lb.isHidden = true
        return lb
    }()
    
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
        
        [blindedLabel, topRow, contentLabel].forEach { contentView.addSubview($0) }
        
        blindedLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(8)
        }
        
        topRow.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(8)
        }
        contentLabel.snp.makeConstraints {
            $0.top.equalTo(topRow.snp.bottom).offset(4)
            $0.leading.trailing.bottom.equalToSuperview().inset(8)
        }
    }
    
    func configure(with review: Review) {
        
        if review.isBlinded,
           let until = review.blindedUntil,
           until > Date() {
            
            blindedLabel.isHidden = false
            userLabel.isHidden = false
            ratingLabel.isHidden = true
            contentLabel.isHidden = true
            return
        }
        
        // 정상 리뷰
        blindedLabel.isHidden = true
        userLabel.isHidden = false
        ratingLabel.isHidden = false
        contentLabel.isHidden = false
        
        userLabel.text = review.nickname
        ratingLabel.text = "⭐️ \(review.rating)"
        contentLabel.text = review.content
    }
}

extension ShopDetailVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x / (view.frame.width - 40))
        pageControl.currentPage = Int(pageIndex)
    }
}
