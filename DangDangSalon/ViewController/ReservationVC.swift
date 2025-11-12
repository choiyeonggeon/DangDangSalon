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
    
    // 파이어스토어에서 받아오는 데이터
    private var availableTimes: [String] = []      // 이 샵이 원래 받는 시간들
    private var reservedTimes: [String] = []       // 이미 예약된 슬롯 (해당 날짜 기준)
    var menus: [(name: String, price: Int)] = []
    
    // 현재 선택 상태
    private var selectedTime: String?
    private var selectedMenus: [(name: String, price: Int)] = [] {
        didSet { updateTotalPrice() }
    }
    
    // MARK: - UI
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "예약하기"
        label.font = .boldSystemFont(ofSize: 22)
        label.textAlignment = .center
        return label
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
        
        // 키보드 내리기 탭 제스처
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        // 초기 데이터 불러오기
        fetchMenus()
        fetchAvailableTimes()
        loadReservedTimes(for: datePicker.date)
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
    
    // MARK: - Firestore: 날짜별 이미 예약된 슬롯
    private func loadReservedTimes(for date: Date) {
        guard let shopId = shopId else { return }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        db.collection("reservations")
            .whereField("shopId", isEqualTo: shopId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("date", isLessThan: Timestamp(date: endOfDay))
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ 예약 시간 불러오기 실패:", error.localizedDescription)
                    return
                }
                
                // ✅ 예약된 time만 추출해서 reservedTimes에 저장
                self.reservedTimes = snapshot?.documents.compactMap { $0["time"] as? String } ?? []
                
                DispatchQueue.main.async {
                    self.buildTimeButtons() // 버튼 다시 그림 → 예약된 시간 비활성화 반영
                }
            }
    }

    // MARK: - UI 생성: 시간 버튼들
    private func buildTimeButtons() {
        timeStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let chunkSize = 3
        for i in stride(from: 0, to: availableTimes.count, by: chunkSize) {
            let rowTimes = Array(availableTimes[i..<min(i+chunkSize, availableTimes.count)])
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 8
            row.distribution = .fillEqually
            for time in rowTimes {
                let btn = UIButton(type: .system)
                let isReserved = reservedTimes.contains(time)
                let isSelected = time == selectedTime
                btn.setTitle(time, for: .normal)
                btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
                btn.layer.cornerRadius = 8
                btn.layer.borderWidth = 1
                btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
                
                if isReserved {
                    btn.backgroundColor = .systemGray5
                    btn.setTitleColor(.systemGray, for: .normal)
                    btn.layer.borderColor = UIColor.systemGray4.cgColor
                    btn.isEnabled = false
                } else if isSelected {
                    btn.backgroundColor = .systemBlue
                    btn.setTitleColor(.white, for: .normal)
                    btn.layer.borderColor = UIColor.systemBlue.cgColor
                } else {
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
            btn.setTitle("\(menuInfo.name) · \(menuInfo.price)원", for: .normal)
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
            nameField,
            phoneField,
            datePicker,
            timeSectionLabel,
            timeStackView,
            menuSectionLabel,
            menuStackView,
            totalPriceLabel,
            requestField,
            confirmButton
        ].forEach { contentView.addSubview($0) }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(contentView).offset(16)
            $0.centerX.equalToSuperview()
        }
        nameField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(24)
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
        totalPriceLabel.snp.makeConstraints {
            $0.top.equalTo(menuStackView.snp.bottom).offset(12)
            $0.trailing.equalToSuperview().inset(24)
        }
        requestField.snp.makeConstraints {
            $0.top.equalTo(totalPriceLabel.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(60)
        }
        confirmButton.snp.makeConstraints {
            $0.top.equalTo(requestField.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(50)
            $0.bottom.equalToSuperview().inset(40)
        }
    }
    
    private func updateTotalPrice() {
        let total = selectedMenus.map { $0.price }.reduce(0, +)
        let formatted = NumberFormatter.localizedString(from: NSNumber(value: total), number: .decimal)
        totalPriceLabel.text = "총 결제금액: \(formatted)원"
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
        
        let selectedDate = datePicker.date
        let requestText = (requestField.textColor == .systemGray3) ? "" : requestField.text
        let menuNames = selectedMenus.map { $0.name }
        let totalPrice = selectedMenus.map { $0.price }.reduce(0, +)
        
        let start = Calendar.current.startOfDay(for: selectedDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        
        db.collection("reservations")
            .whereField("shopId", isEqualTo: shopId)
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
                        "totalPrice": totalPrice,
                        "date": Timestamp(date: selectedDate),
                        "time": time,
                        "status": "예약 요청",
                        "createdAt": Timestamp(date: Date()),
                        "phone": phone,
                        "request": requestText ?? "",
                        "reviewWritten": false
                    ]
                    
                    self.db.collection("reservations").document(reservationId).setData(data) { err in
                        if let err = err {
                            print("예약 실패:", err.localizedDescription)
                            self.showAlert(title: "오류", message: "예약에 실패했습니다.")
                            return
                        }
                        self.reservedTimes.append(time)
                        self.buildTimeButtons()
                        self.loadReservedTimes(for: selectedDate)
                        self.showAlert(title: "예약 완료", message: "\(name)님, \(time)에 예약이 완료되었습니다.\n선택한 메뉴: \(menuNames.joined(separator: ", "))")
                        
                    }
                }
            }
    }

    @objc private func dateChanged() {
        loadReservedTimes(for: datePicker.date)
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
