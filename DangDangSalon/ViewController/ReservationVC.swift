//
//  ReservationVC.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/21/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

final class ReservationVC: UIViewController {
    
    // MARK: - 전달받는 프로퍼티
    var shopId: String?
    var shopName: String?
    
    var shopLat: Double?
    var shopLng: Double?
    var shopPhone: String?
    var shopAddress: String?
    
    // 파이어스토어에서 받아오는 데이터
    private var availableTimes: [String] = []      // 이 샵이 원래 받는 시간들
    private var reservedTimes: [String] = []       // 이미 예약된 슬롯 (해당 날짜 기준)
    
    private var closedWeekdays: [String] = []
    private var closedDates: [String] = []
    
    var menus: [(name: String, price: Int)] = []
    
    // 현재 선택 상태
    private var selectedTime: String?
    private var selectedMenus: [(name: String, price: Int)] = [] {
        didSet { updateTotalPrice() }
    }
    
    private var pets: [Pet] = []
    private var selectedPet: Pet?
    
    // MARK: - Coupon Properties
    private var coupons: [Coupon] = []
    private var selectedCoupon: Coupon? {
        didSet { updateTotalPrice() }
    }
    
    // MARK: - UI
    
    private let couponSelectButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("사용 가능한 쿠폰 선택", for: .normal)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.systemBlue.cgColor
        btn.layer.cornerRadius = 8
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return btn
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "예약하기"
        label.font = .boldSystemFont(ofSize: 22)
        label.textAlignment = .center
        return label
    }()
    
    private let petSelectButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("반려견 선택", for: .normal)
        btn.setTitleColor(.darkGray, for: .normal)
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.systemGray4.cgColor
        btn.layer.cornerRadius = 8
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return btn
    }()
    
    private let nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "예약자 이름"
        tf.borderStyle = .roundedRect
        return tf
    }()
    
    private let phoneField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "전화번호"
        tf.keyboardType = .phonePad
        tf.borderStyle = .roundedRect
        return tf
    }()
    
    private let requestField: UITextView = {
        let tv = UITextView()
        tv.text = "요청사항을 입력해주세요 (선택)"
        tv.font = .systemFont(ofSize: 15)
        tv.textColor = .systemGray3
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.layer.cornerRadius = 8
        tv.isScrollEnabled = false
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        return tv
    }()
    
    private let additionalFeeLabel: UILabel = {
        let lb = UILabel()
        lb.text = "※ 필요 시 요금이 추가될 수 있습니다."
        lb.font = .systemFont(ofSize: 13)
        lb.textColor = .systemGray
        lb.numberOfLines = 0
        return lb
    }()
    
    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.minimumDate = Date()
        picker.locale = Locale(identifier: "ko_KR")
        picker.minuteInterval = 30
        picker.preferredDatePickerStyle = .inline
        return picker
    }()
    
    // ⏰ 시간 선택 헤더
    private let timeSectionLabel: UILabel = {
        let lb = UILabel()
        lb.text = "시간 선택"
        lb.font = .boldSystemFont(ofSize: 16)
        return lb
    }()
    
    // ⏰ 시간 버튼들 담는 컨테이너
    private let timeStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        return sv
    }()
    
    // 🍖 메뉴 선택 헤더
    private let menuSectionLabel: UILabel = {
        let lb = UILabel()
        lb.text = "메뉴 선택"
        lb.font = .boldSystemFont(ofSize: 16)
        return lb
    }()
    
    private let totalPriceLabel: UILabel = {
        let lb = UILabel()
        lb.text = "총 결제금액: 0원"
        lb.font = .boldSystemFont(ofSize: 17)
        lb.textColor = .systemBlue
        lb.textAlignment = .right
        return lb
    }()
    
    // 🍖 메뉴 버튼들 담는 컨테이너
    private let menuStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        return sv
    }()
    
    private let confirmButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("예약하기", for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.backgroundColor = .systemBlue
        btn.tintColor = .white
        btn.layer.cornerRadius = 10
        return btn
    }()
    
    // MARK: - Firestore
    private let db = Firestore.firestore()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupLayout()
        
        requestField.delegate = self
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        petSelectButton.addTarget(self, action: #selector(showPetSelector), for: .touchUpInside)
        couponSelectButton.addTarget(self, action: #selector(showCouponSelector), for: .touchUpInside)
        
        // 데이터 로드 호출
        fetchCoupons()
        
        // 키보드 내리기 탭 제스처
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        // 초기 데이터 불러오기
        fetchClosedDays()   // 🔥 휴무 정보 불러오기
        fetchMenus()
        fetchPets()
        fetchAvailableTimes()
        loadReservedTimes(for: datePicker.date)
    }
    
    private func fetchCoupons() {
        guard let uid = Auth.auth().currentUser?.uid, let currentShopId = shopId else { return }
        
        db.collection("users").document(uid).collection("coupons")
            .whereField("isActive", isEqualTo: true)
            .getDocuments { [weak self] snap, _ in
                guard let self = self else { return }
                
                let allFetched = snap?.documents.compactMap { Coupon(doc: $0) } ?? []
                
                let now = Timestamp(date: Date())
                self.coupons = allFetched.filter { coupon in
                    let isNotExpired = coupon.expiredAt.seconds > now.seconds
                    let isForThisShop = (coupon.shopId == "all" || coupon.shopId == currentShopId)
                    return isNotExpired && isForThisShop
                }
                
                DispatchQueue.main.async {
                    self.couponSelectButton.setTitle(self.coupons.isEmpty ? "사용 가능한 쿠폰 없음" : "쿠폰 선택 (보유: \(self.coupons.count)장)", for: .normal)
                }
            }
    }
    
    // MARK: - Firestore: 메뉴 불러오기
    private func fetchMenus() {
        guard let shopId = shopId else { return }
        db.collection("shops").document(shopId).collection("menus")
            .getDocuments { [weak self] snapshot, _ in
                guard let self = self else { return }
                self.menus = snapshot?.documents.compactMap { doc in
                    guard let name = doc["name"] as? String,
                          let price = doc["price"] as? Int else { return nil }
                    return (name, price)
                } ?? []
                if let first = self.menus.first { self.selectedMenus = [first] }
                DispatchQueue.main.async { self.buildMenuButtons() }
            }
    }
    
    private func fetchClosedDays() {
        guard let shopId = shopId else { return }
        
        db.collection("shops").document(shopId).getDocument { [weak self] snap, error in
            guard let self = self else { return }
            let data = snap?.data() ?? [:]
            
            self.closedWeekdays = data["closedWeekdays"] as? [String] ?? []
            self.closedDates = data["closedDates"] as? [String] ?? []
        }
    }
    
    // MARK: - Firestore: 이 샵의 기본 가능한 시간 슬롯들 불러오기
    private func fetchAvailableTimes() {
        guard let shopId = shopId else { return }
        
        db.collection("shops").document(shopId).getDocument { [weak self] snap, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ 시간대 불러오기 실패:", error.localizedDescription)
                self.availableTimes = self.generateDefaultTimes()
            } else if let times = snap?.data()?["availableTimes"] as? [String], !times.isEmpty {
                self.availableTimes = times
            } else {
                self.availableTimes = self.generateDefaultTimes()
            }
            
            print("📄 Firestore availableTimes:", self.availableTimes)
            
            self.selectedTime = self.availableTimes.first
            DispatchQueue.main.async {
                self.buildTimeButtons()
            }
        }
    }
    
    // 기본시간 fallback
    private func generateDefaultTimes() -> [String] {
        var result: [String] = []
        for h in 10...22 {
            result.append(String(format: "%02d:00", h))
            result.append(String(format: "%02d:30", h))
        }
        return result
    }
    
    private func fetchPets() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(uid)
            .collection("pets")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ 반려견 불러오기 실패:", error.localizedDescription)
                    return
                }
                
                self.pets = snapshot?.documents.map {
                    Pet(id: $0.documentID, data: $0.data())
                } ?? []
            }
    }
    
    private func loadReservedTimes(for date: Date) {
        guard let shopId = shopId else { return }
        let dateString = formatDate(date)
        
        db.collection("shops").document(shopId)
            .collection("reserved").document(dateString)
            .getDocument { [weak self] snap, _ in
                guard let self = self else { return }
                
                if let data = snap?.data(),
                   let times = data["times"] as? [String] {
                    self.reservedTimes = times
                } else {
                    self.reservedTimes = []
                }
                
                self.loadDisabledTimes(for: date)
            }
    }
    
    private func loadDisabledTimes(for date: Date) {
        guard let shopId = shopId else { return }
        let dateString = formatDate(date)
        
        db.collection("shops").document(shopId)
            .collection("disabled").document(dateString)
            .getDocument { [weak self] snap, _ in
                guard let self = self else { return }
                
                if let data = snap?.data() {
                    self.reservedTimes += Array(data.keys)
                }
                
                DispatchQueue.main.async {
                    self.buildTimeButtons()
                }
            }
    }
    
    // MARK: - UI 생성: 시간 버튼들
    private func buildTimeButtons() {
        timeStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // -----------------------
        // 🔥 현재 날짜가 오늘일 경우 → 지난 시간 disable
        // -----------------------
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(datePicker.date)
        
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let currentTimeString = formatter.string(from: now)
        // -----------------------
        
        let chunkSize = 3
        for i in stride(from: 0, to: availableTimes.count, by: chunkSize) {
            let rowTimes = Array(availableTimes[i..<min(i+chunkSize, availableTimes.count)])
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 8
            row.distribution = .fillEqually
            
            for time in rowTimes {
                let btn = UIButton(type: .system)
                
                // ⛔ 지난 시간 체크
                let isPastTime: Bool = {
                    if isToday {
                        return time < currentTimeString
                    }
                    return false
                }()
                
                let isReserved = reservedTimes.contains(time)
                let isSelected = time == selectedTime
                
                btn.setTitle(time, for: .normal)
                btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
                btn.layer.cornerRadius = 8
                btn.layer.borderWidth = 1
                btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
                
                if isPastTime {
                    // 지난 시간 → 선택 불가
                    btn.backgroundColor = .systemGray5
                    btn.setTitleColor(.systemGray, for: .normal)
                    btn.layer.borderColor = UIColor.systemGray4.cgColor
                    btn.isEnabled = false
                    
                } else if isReserved {
                    // 이미 예약된 시간 → 선택 불가
                    btn.backgroundColor = .systemGray5
                    btn.setTitleColor(.systemGray, for: .normal)
                    btn.layer.borderColor = UIColor.systemGray4.cgColor
                    btn.isEnabled = false
                    
                } else if isSelected {
                    // 선택된 시간
                    btn.backgroundColor = .systemBlue
                    btn.setTitleColor(.white, for: .normal)
                    btn.layer.borderColor = UIColor.systemBlue.cgColor
                    
                } else {
                    // 기본 버튼
                    btn.backgroundColor = .clear
                    btn.setTitleColor(.label, for: .normal)
                    btn.layer.borderColor = UIColor.systemGray4.cgColor
                }
                
                btn.addAction(UIAction { [weak self] _ in
                    self?.selectedTime = time
                    self?.buildTimeButtons()
                }, for: .touchUpInside)
                
                row.addArrangedSubview(btn)
            }
            timeStackView.addArrangedSubview(row)
        }
    }
    
    // MARK: - UI 생성: 메뉴 버튼들
    private func buildMenuButtons() {
        menuStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (idx, menuInfo) in menus.enumerated() {
            let isSelected = selectedMenus.contains { $0.name == menuInfo.name && $0.price == menuInfo.price }
            
            let btn = UIButton(type: .system)
            let formattedPrice = NumberFormatter.localizedString(
                from: NSNumber(value: menuInfo.price),
                number: .decimal
            )
            
            btn.setTitle("\(menuInfo.name) - \(formattedPrice)원", for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            btn.layer.cornerRadius = 8
            btn.layer.borderWidth = 1
            btn.configuration = nil
            btn.contentHorizontalAlignment = .left
            btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
            
            if isSelected {
                btn.backgroundColor = .systemBlue
                btn.setTitleColor(.white, for: .normal)
                btn.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                btn.backgroundColor = .clear
                btn.setTitleColor(.label, for: .normal)
                btn.layer.borderColor = UIColor.systemGray4.cgColor
            }
            
            btn.addAction(UIAction { [weak self] _ in
                guard let self = self else { return }
                
                if isSelected {
                    // 이미 선택되어 있으면 해제
                    self.selectedMenus.removeAll { $0.name == menuInfo.name && $0.price == menuInfo.price }
                } else {
                    // 새로 선택
                    self.selectedMenus.append(menuInfo)
                }
                
                self.buildMenuButtons()
            }, for: .touchUpInside)
            
            menuStackView.addArrangedSubview(btn)
        }
        updateTotalPrice()
    }
    
    private func setupLayout() {
        let scrollView = UIScrollView()
        let contentView = UIView()
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView.snp.width)
        }
        
        // contentView에 넣을 순서대로 추가
        [
            titleLabel,
            petSelectButton,
            nameField,
            phoneField,
            datePicker,
            timeSectionLabel,
            timeStackView,
            menuSectionLabel,
            menuStackView,
            couponSelectButton, // 1. 여기에 추가
            totalPriceLabel,
            requestField,
            confirmButton
        ].forEach { contentView.addSubview($0) }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(contentView).offset(16)
            $0.centerX.equalToSuperview()
        }
        
        petSelectButton.snp.makeConstraints {      // ← 추가됨
            $0.top.equalTo(titleLabel.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(44)
        }
        
        nameField.snp.makeConstraints {
            $0.top.equalTo(petSelectButton.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(44)
        }
        
        phoneField.snp.makeConstraints {
            $0.top.equalTo(nameField.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(44)
        }
        
        datePicker.snp.makeConstraints {
            $0.top.equalTo(phoneField.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        
        timeSectionLabel.snp.makeConstraints {
            $0.top.equalTo(datePicker.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        
        timeStackView.snp.makeConstraints {
            $0.top.equalTo(timeSectionLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        
        menuSectionLabel.snp.makeConstraints {
            $0.top.equalTo(timeStackView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        
        menuStackView.snp.makeConstraints {
            $0.top.equalTo(menuSectionLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        
        couponSelectButton.snp.makeConstraints {
            $0.top.equalTo(menuStackView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        
        totalPriceLabel.snp.makeConstraints {
            $0.top.equalTo(couponSelectButton.snp.bottom).offset(12)
            $0.trailing.equalToSuperview().inset(24)
        }
        
        requestField.snp.makeConstraints {
            $0.top.equalTo(totalPriceLabel.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(60)
        }
        
        contentView.addSubview(additionalFeeLabel)
        additionalFeeLabel.snp.makeConstraints {
            $0.top.equalTo(requestField.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        
        confirmButton.snp.makeConstraints {
            $0.top.equalTo(requestField.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(50)
            $0.bottom.equalToSuperview().inset(40)
        }
    }
    
    private func updateTotalPrice() {
        let menuTotal = selectedMenus.map { $0.price }.reduce(0, +)
        var finalTotal = menuTotal
        
        if let coupon = selectedCoupon {
            // 최소 주문 금액 미달 시 쿠폰 해제
            if menuTotal < coupon.minPrice {
                self.selectedCoupon = nil
                showAlert(title: "쿠폰 적용 불가", message: "해당 쿠폰은 \(coupon.minPrice)원 이상 결제 시 사용 가능합니다.")
                return
            }
            
            // 할인 계산
            if coupon.discountType == "percent" {
                let discount = Int(Double(menuTotal) * (Double(coupon.discountValue) / 100.0))
                finalTotal = max(0, menuTotal - discount)
            } else {
                finalTotal = max(0, menuTotal - coupon.discountValue)
            }
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let totalStr = formatter.string(from: NSNumber(value: finalTotal)) ?? "0"
        
        totalPriceLabel.text = "총 결제금액: \(totalStr)원"
        totalPriceLabel.textColor = (selectedCoupon != nil) ? .systemRed : .systemBlue
    }
    
    // MARK: - 예약 등록
    @objc private func confirmTapped() {
        
        guard let name = nameField.text, !name.isEmpty,
              let phone = phoneField.text, !phone.isEmpty,
              let shopId = shopId,
              let shopName = shopName,
              let time = selectedTime,
              !selectedMenus.isEmpty,
              let userId = Auth.auth().currentUser?.uid else {
            showAlert(title: "입력 오류", message: "모든 정보를 입력해주세요.")
            return
        }
        
        // 🔥 반려견 선택 여부 확인
        guard let pet = selectedPet else {
            showAlert(title: "반려견 선택", message: "반려견을 선택해주세요.")
            return
        }
        
        let selectedDate = datePicker.date
        let requestText = (requestField.textColor == .systemGray3) ? "" : requestField.text
        let menuNames = selectedMenus.map { $0.name }
        
        // --- 💰 가격 계산 (쿠폰 적용 로직 포함) ---
        let menuTotalPrice = selectedMenus.map { $0.price }.reduce(0, +)
        var finalTotalPrice = menuTotalPrice
        
        if let coupon = selectedCoupon {
            if coupon.discountType == "percent" {
                let discount = Int(Double(menuTotalPrice) * (Double(coupon.discountValue) / 100.0))
                finalTotalPrice = max(0, menuTotalPrice - discount)
            } else {
                finalTotalPrice = max(0, menuTotalPrice - coupon.discountValue)
            }
        }
        // ---------------------------------------
        
        let start = Calendar.current.startOfDay(for: selectedDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        
        db.collection("reservations")
            .whereField("shopId", isEqualTo: shopId)
            .whereField("status", in: ["예약 요청", "확정"])
            .whereField("time", isEqualTo: time)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField("date", isLessThan: Timestamp(date: end))
            .getDocuments { [weak self] snap, _ in
                guard let self = self else { return }
                if let snap = snap, !snap.isEmpty {
                    self.showAlert(title: "예약 불가", message: "이미 선택된 시간입니다.")
                    return
                }
                
                self.db.collection("shops").document(shopId).getDocument { shopSnap, _ in
                    let ownerId = shopSnap?.data()?["ownerId"] as? String ?? ""
                    let reservationId = UUID().uuidString
                    
                    let data: [String: Any] = [
                        "id": reservationId,
                        "userId": userId,
                        "userName": name,
                        "shopId": shopId,
                        "shopName": shopName,
                        "ownerId": ownerId,
                        "menus": menuNames,
                        "totalPrice": finalTotalPrice, // 💰 쿠폰 적용된 최종가 저장
                        "date": Timestamp(date: selectedDate),
                        "time": time,
                        "status": "예약 요청",
                        "createdAt": Timestamp(date: Date()),
                        "phone": phone,
                        "request": requestText ?? "",
                        "reviewWritten": false,
                        "address": self.shopAddress ?? "",
                        "shopPhone": self.shopPhone ?? "",
                        "shopLat": self.shopLat ?? 0,
                        "shopLng": self.shopLng ?? 0,
                        "petId": pet.id,
                        "petName": pet.name,
                        "petBreed": pet.breed,
                        "petWeight": pet.weight,
                        "petAge": pet.age,
                        "petPhotoURL": pet.photoURL ?? "",
                        // 쿠폰을 사용했다면 정보 기록 (선택 사항)
                        "usedCouponId": self.selectedCoupon?.id ?? ""
                    ]
                    
                    self.db.collection("reservations").document(reservationId).setData(data) { err in
                        if let err = err {
                            print("예약 실패:", err.localizedDescription)
                            self.showAlert(title: "오류", message: "예약에 실패했습니다.")
                            return
                        }
                        
                        // ✨ [추가] 1️⃣ 사용한 쿠폰 처리
                        if let usedCoupon = self.selectedCoupon {
                            self.db.collection("users").document(userId)
                                .collection("coupons").document(usedCoupon.id)
                                .updateData([
                                    "isActive": false,
                                    "usedAt": FieldValue.serverTimestamp()
                                ])
                        }
                        
                        // ✅ 2️⃣ 여기서 날짜 키 생성
                        let dateKey = self.formatDate(selectedDate)
                        
                        // ✅ 3️⃣ reserved 문서 레퍼런스
                        let reservedRef = self.db.collection("shops")
                            .document(shopId)
                            .collection("reserved")
                            .document(dateKey)
                        
                        // ✅ 4️⃣ 예약 시간 추가
                        reservedRef.setData([
                            "times": FieldValue.arrayUnion([time])
                        ], merge: true)
                        
                        // ✅ 5️⃣ UI 갱신
                        self.reservedTimes.append(time)
                        self.buildTimeButtons()
                        self.loadReservedTimes(for: selectedDate)
                        
                        // ✅ 6️⃣ 알림 메시지에 할인 정보 포함 (선택)
                        var successMsg = "\(name)님, \(time)에 예약이 완료되었습니다.\n반려견: \(pet.name)"
                        if self.selectedCoupon != nil {
                            successMsg += "\n(쿠폰 할인이 적용되었습니다.)"
                        }
                        
                        self.showAlert(title: "예약 완료", message: successMsg)
                    }
                }
            }
    }
    
    @objc private func showPetSelector() {
        let alert = UIAlertController(title: "반려견 선택", message: nil, preferredStyle: .actionSheet)
        
        pets.forEach { pet in
            alert.addAction(UIAlertAction(title: pet.name, style: .default, handler: { _ in
                self.selectedPet = pet
                self.petSelectButton.setTitle("선택됨: \(pet.name)", for: .normal)
                self.petSelectButton.setTitleColor(.black, for: .normal)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        // iPad 팝오버 방지
        if let popover = alert.popoverPresentationController {
            popover.sourceView = petSelectButton
            popover.sourceRect = CGRect(x: petSelectButton.bounds.midX,
                                        y: petSelectButton.bounds.midY,
                                        width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
    
    @objc private func dateChanged() {
        let selected = datePicker.date
        
        // 🔥 휴무 체크
        if isClosedDay(selected) {
            showClosedAlert()
            clearTimeSlots()   // 시간 버튼 전체 비활성화
            return
        }
        
        // 정상영업일이면 기존 로직 실행
        loadReservedTimes(for: selected)
    }
    
    private func isClosedDay(_ date: Date) -> Bool {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let dateKey = f.string(from: date)
        
        // 1) 특정 날짜 휴무 체크
        if closedDates.contains(dateKey) { return true }
        
        // 2) 요일 휴무 체크
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEE"   // Mon, Tue, Wed...
        weekdayFormatter.locale = Locale(identifier: "en_US")
        
        let weekdayKey = weekdayFormatter.string(from: date)
        if closedWeekdays.contains(weekdayKey) { return true }
        
        return false
    }
    
    private func showClosedAlert() {
        let alert = UIAlertController(
            title: "휴무일 안내",
            message: "해당 날짜는 매장의 휴무일입니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func clearTimeSlots() {
        timeStackView.arrangedSubviews.forEach { row in
            if let rowStack = row as? UIStackView {
                rowStack.arrangedSubviews.forEach { btn in
                    (btn as? UIButton)?.isEnabled = false
                    (btn as? UIButton)?.backgroundColor = .systemGray5
                }
            }
        }
    }
    
    @objc private func showCouponSelector() {
        if coupons.isEmpty { return }
        
        let alert = UIAlertController(title: "쿠폰 선택", message: "결제 시 사용할 쿠폰을 선택하세요.", preferredStyle: .actionSheet)
        
        // 쿠폰 리스트 추가
        coupons.forEach { coupon in
            let discountText = coupon.discountType == "percent" ? "\(coupon.discountValue)%" : "\(coupon.discountValue)원"
            let title = "[\(coupon.title)] \(discountText) 할인 (최소 \(coupon.minPrice)원)"
            
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                self.selectedCoupon = coupon
                self.couponSelectButton.setTitle("적용됨: \(coupon.title)", for: .normal)
            })
        }
        
        alert.addAction(UIAlertAction(title: "적용 안 함", style: .destructive) { _ in
            self.selectedCoupon = nil
            self.couponSelectButton.setTitle("쿠폰 선택", for: .normal)
        })
        
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Alert helper
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}

// MARK: - UITextView Delegate
extension ReservationVC: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .systemGray3 {
            textView.text = nil
            textView.textColor = .label
        }
    }
}

extension ReservationVC {
    /// 날짜 → "yyyy-MM-dd" 형태 문자열로 변환
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: date)
    }
}
