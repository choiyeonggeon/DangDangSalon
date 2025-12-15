////
////  PaymentMethodVC.swift
////  DangSalon
////
////  Created by 최영건 on 11/27/25.
////
//
//import UIKit
//import FirebaseFirestore
//
//final class PaymentMethodVC: UIViewController {
//    
//    var shopId: String?
//    var shopName: String?
//    var selectedTime: String?
//    var selectedMenus: [(name: String, price: Int)] = []
//    var selectedPet: Pet?
//    var shopPhone: String?
//    var shopAddress: String?
//    var shopLat: Double?
//    var shopLng: Double?
//    
//    private let stackView: UIStackView = {
//        let sv = UIStackView()
//        sv.axis = .vertical
//        sv.spacing = 20
//        sv.alignment = .fill
//        return sv
//    }()
//    
//    private let storePayButton: UIButton = {
//        let btn = UIButton(type: .system)
//        btn.setTitle("매장 결제", for: .normal)
//        btn.backgroundColor = .systemGray5
//        btn.layer.cornerRadius = 10
//        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
//        return btn
//    }()
//    
//    private let tossPayButton: UIButton = {
//        let btn = UIButton(type: .system)
//        btn.setTitle("토스페이 결제", for: .normal)
//        btn.backgroundColor = .systemBlue
//        btn.setTitleColor(.white, for: .normal)
//        btn.layer.cornerRadius = 10
//        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
//        return btn
//    }()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .systemBackground
//        title = "결제수단 선택"
//        
//        view.addSubview(stackView)
//        stackView.snp.makeConstraints {
//            $0.center.equalToSuperview()
//            $0.leading.trailing.equalToSuperview().inset(24)
//        }
//        
//        [storePayButton, tossPayButton].forEach { stackView.addArrangedSubview($0) }
//        
//        storePayButton.addTarget(self, action: #selector(storePayTapped), for: .touchUpInside)
//        tossPayButton.addTarget(self, action: #selector(tossPayTapped), for: .touchUpInside)
//    }
//    
//    @objc private func storePayTapped() {
//        // 바로 예약 등록 로직 실행
//        guard let shopId = shopId, let time = selectedTime, let pet = selectedPet else { return }
//        
//        let totalPrice = selectedMenus.map { $0.price }.reduce(0, +)
//        let menuNames = selectedMenus.map { $0.name }
//        let reservationId = UUID().uuidString
//        
//        let data: [String: Any] = [
//            "id": reservationId,
//            "shopId": shopId,
//            "shopName": shopName ?? "",
//            "menus": menuNames,
//            "totalPrice": totalPrice,
//            "time": time,
//            "status": "매장 결제",
//            "createdAt": Timestamp(date: Date()),
//            "petId": pet.id,
//            "petName": pet.name,
//            "petBreed": pet.breed,
//            "petWeight": pet.weight,
//            "petAge": pet.age,
//            "petPhotoURL": pet.photoURL ?? "",
//            "shopPhone": shopPhone ?? "",
//            "shopAddress": shopAddress ?? "",
//            "shopLat": shopLat ?? 0,
//            "shopLng": shopLng ?? 0
//        ]
//        
//        Firestore.firestore().collection("reservations").document(reservationId).setData(data) { err in
//            if let err = err {
//                print("예약 실패:", err.localizedDescription)
//                self.showAlert(title: "오류", message: "예약에 실패했습니다.")
//                return
//            }
//            
//            self.showAlert(title: "예약 완료", message: "매장 결제가 선택되었습니다.")
//        }
//    }
//    
//    @objc private func tossPayTapped() {
//        guard let selectedTime = selectedTime,
//              !selectedMenus.isEmpty,
//              let selectedPet = selectedPet else {
//            showAlert(title: "정보 누락", message: "시간, 메뉴, 반려견을 선택해주세요.")
//            return
//        }
//        
//        var reservationData: [String: Any] = [:]
//        reservationData["shopId"] = shopId
//        reservationData["shopName"] = shopName
//        reservationData["selectedTime"] = selectedTime
//        reservationData["selectedMenus"] = selectedMenus
//        reservationData["selectedPet"] = selectedPet
//        
//        let totalPrice = selectedMenus.map { $0.price }.reduce(0, +)
//        reservationData["price"] = totalPrice
//        reservationData["menu"] = selectedMenus.map { $0.name }.joined(separator: ", ")
//        reservationData["name"] = UserDefaults.standard.string(forKey: "userName") ?? "고객님"
//        
//        let paymentVC = PaymentVC()
//        
//        if let nav = self.navigationController {
//            nav.pushViewController(paymentVC, animated: true)
//        } else {
//            paymentVC.modalPresentationStyle = .fullScreen
//            present(paymentVC, animated: true)
//        }
//    }
//
//    private func showAlert(title: String, message: String) {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "확인", style: .default))
//        present(alert, animated: true)
//    }
//}
