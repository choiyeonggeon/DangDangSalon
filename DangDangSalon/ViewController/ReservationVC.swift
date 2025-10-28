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
    private var selectedMenu: (name: String, price: Int)?
    
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
        
        db.collection("shops")
            .document(shopId)
            .collection("menus")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("메뉴 불러오기 실패:", error.localizedDescription)
                    return
                }
                
                self.menus = snapshot?.documents.compactMap { doc in
                    guard let name = doc["name"] as? String,
                          let price = doc["price"] as? Int else { return nil }
                    return (name, price)
                } ?? []
                
                // 기본 선택값 (첫 번째)
                self.selectedMenu = self.menus.first
                
                DispatchQueue.main.async {
                    self.buildMenuButtons()
                }
            }
    }
    
    // MARK: - Firestore: 이 샵의 기본 가능한 시간 슬롯들 불러오기
    private func fetchAvailableTimes() {
        guard let shopId = shopId else { return }
        
        db.collection("shops")
            .document(shopId)
            .getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("예약 가능 시간 불러오기 실패:", error.localizedDescription)
                    return
                }
                
                if let data = snapshot?.data(),
                   let times = data["availableTimes"] as? [String] {
                    self.availableTimes = times
                } else {
                    self.availableTimes = self.generateDefaultTimes()
                }
                
                // 기본 선택값 (첫 번째 가능 시간)
                self.selectedTime = self.availableTimes.first
                
                DispatchQueue.main.async {
                    self.buildTimeButtons()
                }
            }
    }
    
    // 기본시간 fallback
    private func generateDefaultTimes() -> [String] {
        var times: [String] = []
        for hour in 10...22 {
            times.append(String(format: "%02d:00", hour))
            times.append(String(format: "%02d:30", hour))
        }
        return times
    }
    
    // MARK: - Firestore: 날짜별 이미 예약된 슬롯
    private func loadReservedTimes(for date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: date)
        
        db.collection("reservations")
            .document(dateKey)
            .getDocument { [weak self] snapshot, _ in
                guard let self = self else { return }
                
                let data = snapshot?.data() ?? [:]
                // ["10:00": {...}, "10:30": {...}]
                self.reservedTimes = Array(data.keys)
                
                DispatchQueue.main.async {
                    self.buildTimeButtons() // 다시 그려주기 (비활성화 표시 반영)
                }
            }
    }
    
    // MARK: - UI 생성: 시간 버튼들
    private func buildTimeButtons() {
        // 기존 버튼들 제거
        timeStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // availableTimes 를 2~3개씩 가로줄로 배치
        let chunkSize = 3
        for chunkStart in stride(from: 0, to: availableTimes.count, by: chunkSize) {
            let rowTimes = Array(availableTimes[chunkStart..<min(chunkStart+chunkSize, availableTimes.count)])
            
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 8
            row.distribution = .fillEqually
            
            for time in rowTimes {
                let isReserved = reservedTimes.contains(time)
                let isSelected = (time == selectedTime)
                
                let btn = UIButton(type: .system)
                btn.setTitle(time, for: .normal)
                btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
                btn.layer.cornerRadius = 8
                btn.layer.borderWidth = 1
                
                if isReserved {
                    // 이미 예약된 슬롯 -> 회색, 비활성
                    btn.backgroundColor = .systemGray5
                    btn.setTitleColor(.systemGray, for: .normal)
                    btn.layer.borderColor = UIColor.systemGray4.cgColor
                    btn.isEnabled = false
                } else if isSelected {
                    // 내가 고른 시간 -> 파란 느낌
                    btn.backgroundColor = .systemBlue
                    btn.setTitleColor(.white, for: .normal)
                    btn.layer.borderColor = UIColor.systemBlue.cgColor
                } else {
                    // 아직 안 고른 가능 시간
                    btn.backgroundColor = .clear
                    btn.setTitleColor(.label, for: .normal)
                    btn.layer.borderColor = UIColor.systemGray4.cgColor
                }
                
                btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
                btn.addAction(UIAction { [weak self] _ in
                    guard let self = self else { return }
                    self.selectedTime = time
                    self.buildTimeButtons() // 다시 그려서 선택 반영
                }, for: .touchUpInside)
                
                row.addArrangedSubview(btn)
            }
            
            timeStackView.addArrangedSubview(row)
        }
    }
    
    // MARK: - UI 생성: 메뉴 버튼들
    private func buildMenuButtons() {
        // 기존 버튼들 제거
        menuStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 메뉴도 1~2개씩 줄세우거나 그냥 세로 한 줄씩
        for (idx, menuInfo) in menus.enumerated() {
            let isSelected = (selectedMenu?.name == menuInfo.name && selectedMenu?.price == menuInfo.price)
            
            let btn = UIButton(type: .system)
            btn.setTitle("\(menuInfo.name) · \(menuInfo.price)원", for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            btn.layer.cornerRadius = 8
            btn.layer.borderWidth = 1
            
            if isSelected {
                btn.backgroundColor = .systemBlue
                btn.setTitleColor(.white, for: .normal)
                btn.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                btn.backgroundColor = .clear
                btn.setTitleColor(.label, for: .normal)
                btn.layer.borderColor = UIColor.systemGray4.cgColor
            }
            
            btn.configuration = nil
            btn.contentHorizontalAlignment = .left
            btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
            btn.addAction(UIAction { [weak self] _ in
                guard let self = self else { return }
                self.selectedMenu = self.menus[idx]
                self.buildMenuButtons() // 다시 그려서 선택 반영
            }, for: .touchUpInside)
            
            menuStackView.addArrangedSubview(btn)
        }
    }
    
    // MARK: - Layout
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
        
        requestField.snp.makeConstraints {
            $0.top.equalTo(menuStackView.snp.bottom).offset(24)
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
    
    // MARK: - Actions
    @objc private func confirmTapped() {
        guard let name = nameField.text, !name.isEmpty,
              let phone = phoneField.text, !phone.isEmpty,
              let menu = selectedMenu,
              let shopId = shopId,
              let shopName = shopName,
              let time = selectedTime else {
            showAlert(title: "입력 오류", message: "모든 정보를 입력해주세요.")
            return
        }
        
        let selectedDate = datePicker.date
        let requestText = (requestField.textColor == .systemGray3) ? "" : requestField.text
        
        // 날짜 key 포맷
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: selectedDate)
        
        // 1) 전체 예약(날짜별)에도 저장
        db.collection("reservations").document(dateKey).setData([
            time: [
                "name": name,
                "phone": phone,
                "menu": menu.name,
                "price": menu.price,
                "request": requestText ?? "",
                "timestamp": Timestamp(date: Date()),
                "shopId": shopId,
                "shopName": shopName
            ]
        ], merge: true)
        
        // 2) 유저 개인 히스토리에도 저장
        if let userId = Auth.auth().currentUser?.uid {
            let userRef = db.collection("users")
                .document(userId)
                .collection("reservations")
                .document()
            
            userRef.setData([
                "id": userRef.documentID,
                "shopId": shopId,
                "shopName": shopName,
                "menu": menu.name,
                "price": menu.price,
                "date": Timestamp(date: selectedDate),
                "time": time,
                "status": "pending",
                "reviewWritten": false,
                "createdAt": Timestamp(date: Date())
            ])
        }
        
        showAlert(title: "예약 완료", message: "\(name)님, \(time)에 예약이 완료되었습니다.")
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
