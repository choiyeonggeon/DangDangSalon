////
////  PaymentVC.swift
////  DangDangSalon
////
////  Created by 최영건 on 10/22/25.
////
//
//import UIKit
//import SnapKit
//import TossPayments
//
//class PaymentVC: UIViewController {
//    
//    var reservationData: [String: Any]?
//    
//    private lazy var scrollView = UIScrollView()
//    private lazy var stackView = UIStackView()
//    
//    private lazy var button: UIButton = {
//        let btn = UIButton()
//        btn.backgroundColor = .systemBlue
//        btn.setTitle("결제하기", for: .normal)
//        btn.setTitleColor(.white, for: .normal)
//        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
//        btn.layer.cornerRadius = 10
//        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
//        btn.addTarget(self, action: #selector(requestPayment), for: .touchUpInside)
//        return btn
//    }()
//    
//    private lazy var widget: PaymentWidget = {
//        let brandPayOptions = PaymentWidget.Options(
//            brandpay: PaymentWidget.BrandPay(
//                redirectURL: "dangsalon://brandpay" // ✅ URL Scheme 반드시 Info.plist와 동일
//            )
//        )
//        let widget = PaymentWidget(
//            clientKey: "test_ck_6BYq7GWPVv4zzjqgNkyl8NE5vbo1",
//            customerKey: "test_sk_GePWvyJnrKP1old6O6268gLzN97E",
//            options: brandPayOptions
//        )
//        widget.delegate = self
//        widget.paymentMethodWidget?.widgetStatusDelegate = self
//        return widget
//    }()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .systemBackground
//        title = "결제"
//        
//        setupLayout()
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        setupWidgetIfNeeded()
//    }
//    
//    private func setupLayout() {
//        view.addSubview(scrollView)
//        scrollView.addSubview(stackView)
//        
//        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        
//        scrollView.alwaysBounceVertical = true
//        scrollView.keyboardDismissMode = .onDrag
//        
//        stackView.axis = .vertical
//        stackView.spacing = 24
//        stackView.alignment = .fill
//        
//        NSLayoutConstraint.activate([
//            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
//            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
//            
//            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
//            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
//            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
//            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
//            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48)
//        ])
//        
//        stackView.addArrangedSubview(button)
//    }
//    
//    private func setupWidgetIfNeeded() {
//        // 이미 추가되어 있으면 중복 방지
//        if stackView.arrangedSubviews.contains(where: { $0 === widget.paymentMethodWidget }) { return }
//        
//        let price = reservationData?["price"] as? Int ?? 10000
//        
//        let paymentMethods = widget.renderPaymentMethods(
//            amount: PaymentMethodWidget.Amount(value: Double(price))
//        )
//        let agreement = widget.renderAgreement()
//        
//        paymentMethods.translatesAutoresizingMaskIntoConstraints = false
//        agreement.translatesAutoresizingMaskIntoConstraints = false
//        
//        stackView.insertArrangedSubview(paymentMethods, at: 0)
//        stackView.insertArrangedSubview(agreement, at: 1)
//        
//        paymentMethods.heightAnchor.constraint(greaterThanOrEqualToConstant: 420).isActive = true
//        agreement.heightAnchor.constraint(greaterThanOrEqualToConstant: 150).isActive = true
//    }
//    
//    @objc private func requestPayment() {
//        widget.requestPayment(
//            info: DefaultWidgetPaymentInfo(
//                orderId: UUID().uuidString,
//                orderName: "댕살롱 서비스 결제"
//            )
//        )
//    }
//}
//
//// MARK: - Toss Delegate
//extension PaymentVC: TossPaymentsDelegate {
//    func handleSuccessResult(_ success: TossPaymentsResult.Success) {
//        print("✅ 결제 성공: \(success.paymentKey)")
//        let alert = UIAlertController(
//            title: "결제 완료 🎉",
//            message: "결제가 성공적으로 완료되었습니다.",
//            preferredStyle: .alert
//        )
//        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
//            let myReservationVC = MyReservationVC()
//            myReservationVC.modalTransitionStyle = .coverVertical
//            myReservationVC.modalPresentationStyle = .fullScreen
//            self.navigationController?.pushViewController(myReservationVC, animated: true)
//        })
//        present(alert, animated: true)
//    }
//    
//    func handleFailResult(_ fail: TossPaymentsResult.Fail) {
//        print("❌ 결제 실패: \(fail.errorMessage)")
//        let alert = UIAlertController(
//            title: "결제 실패",
//            message: fail.errorMessage,
//            preferredStyle: .alert
//        )
//        alert.addAction(UIAlertAction(title: "확인", style: .default))
//        present(alert, animated: true)
//    }
//}
//
//// MARK: - Toss Widget 상태 Delegate
//extension PaymentVC: TossPaymentsWidgetStatusDelegate {
//    func didReceivedLoad(_ name: String) {
//        print("🎯 결제위젯 렌더링 완료: \(name)")
//    }
//}
