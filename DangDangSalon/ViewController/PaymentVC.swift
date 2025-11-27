//
//  PaymentVC.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/22/25.
//

import UIKit
import SnapKit
import TossPayments

class PaymentVC: UIViewController {
    
    var reservationData: [String: Any]?
    
    private lazy var scrollView = UIScrollView()
    private lazy var stackView = UIStackView()
    
    private lazy var widget: PaymentWidget = PaymentWidget(
        clientKey: "test_ck_6BYq7GWPVv4zzjqgNkyl8NE5vbo1",
        customerKey: "EPUx4U0_zvKaGMZkA7uF_"
    )
    
    private lazy var button = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "결제"
        
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .onDrag
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .fill
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -48)
        ])
        
        // ✅ 버튼 구성
        button.backgroundColor = .systemBlue
        button.setTitle("결제하기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: #selector(requestPayment), for: .touchUpInside)
        
        // ✅ Toss 위젯 Delegate 연결
        widget.delegate = self
        widget.paymentMethodWidget?.widgetStatusDelegate = self
        
        // ✅ 반드시 호출해야 위젯이 뜸
        setupWidget()
    }
    
    private func setupWidget() {
        guard let data = reservationData,
              let name = data["name"] as? String,
              let menu = data["menu"] as? String,
              let price = data["price"] as? Int else {
            print("⚠️ 예약 데이터 없음 — 기본 10000원 표시")
            let paymentMethods = widget.renderPaymentMethods(amount: PaymentMethodWidget.Amount(value: 10000))
            let agreement = widget.renderAgreement()
            stackView.addArrangedSubview(paymentMethods)
            stackView.addArrangedSubview(agreement)
            stackView.addArrangedSubview(button)
            return
        }
        
        // ✅ 예약 정보 표시 라벨
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 16)
        label.text = """
        예약자: \(name)
        서비스: \(menu)
        결제금액: \(price)원
        """
        stackView.addArrangedSubview(label)
        
        // ✅ 위젯 렌더링 (고정 높이 추가)
        let paymentMethods = widget.renderPaymentMethods(amount: PaymentMethodWidget.Amount(value: Double(price)))
        let agreement = widget.renderAgreement()
        
        paymentMethods.translatesAutoresizingMaskIntoConstraints = false
        agreement.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(paymentMethods)
        stackView.addArrangedSubview(agreement)
        stackView.addArrangedSubview(button)
        
        // ✅ Toss 위젯이 정상 표시되도록 높이 강제 지정
        paymentMethods.heightAnchor.constraint(greaterThanOrEqualToConstant: 420).isActive = true
        agreement.heightAnchor.constraint(greaterThanOrEqualToConstant: 150).isActive = true
    }
    
    @objc private func requestPayment() {
        widget.requestPayment(
            info: DefaultWidgetPaymentInfo(
                orderId: "2VAhXURbYbiKwX5ybfrLr",
                orderName: "댕살롱 서비스 결제"
            )
        )
    }
}

// MARK: - Toss Delegate
extension PaymentVC: TossPaymentsDelegate {
    func handleSuccessResult(_ success: TossPaymentsResult.Success) {
        print("✅ 결제 성공")
        print("paymentKey: \(success.paymentKey)")
        
        let alert = UIAlertController(
            title: "결제 완료 🎉",
            message: "결제가 성공적으로 완료되었습니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            let myReservationVC = MyReservationVC()
            myReservationVC.modalTransitionStyle = .coverVertical
            myReservationVC.modalPresentationStyle = .fullScreen
            self.navigationController?.pushViewController(myReservationVC, animated: true)
        })
        present(alert, animated: true)
    }
    
    func handleFailResult(_ fail: TossPaymentsResult.Fail) {
        print("❌ 결제 실패: \(fail.errorMessage)")
        let alert = UIAlertController(
            title: "결제 실패",
            message: fail.errorMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Toss Widget 상태 Delegate
extension PaymentVC: TossPaymentsWidgetStatusDelegate {
    func didReceivedLoad(_ name: String) {
        print("🎯 결제위젯 렌더링 완료: \(name)")
    }
}
