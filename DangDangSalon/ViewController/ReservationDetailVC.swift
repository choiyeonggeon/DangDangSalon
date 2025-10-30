//
//  ReservationDetailVC.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/28/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

final class ReservationDetailVC: UIViewController {
    
    var reservation: Reservation?
    private let db = Firestore.firestore()
    
    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 16
        v.layer.masksToBounds = true
        return v
    }()
    
    // 개별 항목들 (아이콘 + 라벨 스택)
    private func makeRow(icon: String, title: String) -> (container: UIStackView, valueLabel: UILabel) {
        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = .systemFont(ofSize: 16)
        iconLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let valueLabel = UILabel()
        valueLabel.text = "-"
        valueLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        valueLabel.textColor = .label
        valueLabel.numberOfLines = 1
        valueLabel.textAlignment = .right
        
        let topRow = UIStackView(arrangedSubviews: [iconLabel, titleLabel, UIView(), valueLabel])
        topRow.axis = .horizontal
        topRow.alignment = .center
        topRow.spacing = 8
        
        return (topRow, valueLabel)
    }
    
    // row들 보관
    private lazy var shopRow = makeRow(icon: "🏪", title: "샵")
    private lazy var menuRow = makeRow(icon: "💈", title: "메뉴")
    private lazy var dateRow = makeRow(icon: "📅", title: "예약일")
    private lazy var timeRow = makeRow(icon: "⏰", title: "시간")
    private lazy var priceRow = makeRow(icon: "💰", title: "결제 금액")
    private lazy var statusRow = makeRow(icon: "📌", title: "상태")
    
    // 구분선 만드는 헬퍼
    private func makeSeparator() -> UIView {
        let line = UIView()
        line.backgroundColor = .separator
        line.snp.makeConstraints { $0.height.equalTo(1 / UIScreen.main.scale) }
        return line
    }
    
    // 취소 버튼을 화면 하단 고정
    private let cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("예약 취소하기", for: .normal)
        btn.backgroundColor = .systemRed
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 17)
        btn.layer.cornerRadius = 12
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "예약 상세"
        
        setupUI()
        configureData()
    }
    
    private func setupUI() {
        // add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(cardView)
        view.addSubview(cancelButton)
        
        // scrollView -> contentView 레이아웃
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(cancelButton.snp.top).offset(-16)
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView.snp.width)
        }
        
        // 카드 내부 스택
        let stack = UIStackView(arrangedSubviews: [
            shopRow.container,
            makeSeparator(),
            menuRow.container,
            makeSeparator(),
            dateRow.container,
            makeSeparator(),
            timeRow.container,
            makeSeparator(),
            priceRow.container,
            makeSeparator(),
            statusRow.container
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
        
        cardView.addSubview(stack)
        
        // cardView layout
        cardView.snp.makeConstraints {
            $0.top.equalTo(contentView.snp.top).offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        // contentView bottom anchor
        contentView.snp.makeConstraints {
            $0.bottom.equalTo(cardView.snp.bottom).offset(24)
        }
        
        // cancel button layout (하단 고정)
        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(52)
        }
        
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    }
    
    private func configureData() {
        guard let r = reservation else { return }
        
        shopRow.valueLabel.text   = r.shopName
        menuRow.valueLabel.text   = r.menus.joined(separator: ", ")
        dateRow.valueLabel.text   = r.dateString   // dateString은 너가 이미 extension으로 만든 거 사용
        timeRow.valueLabel.text   = r.time
        priceRow.valueLabel.text  = "\(r.priceString)"
        statusRow.valueLabel.text = statusText(for: r.status)
        
        // 예약 상태에 따라 취소 버튼 숨김/색상 조정
        switch r.status {
        case "pending":
            cancelButton.isHidden = false
            cancelButton.backgroundColor = .systemRed
            cancelButton.setTitle("예약 취소하기", for: .normal)
        case "completed":
            cancelButton.isHidden = true
        case "cancelled":
            cancelButton.isHidden = true
        default:
            cancelButton.isHidden = true
        }
    }
    
    private func statusText(for raw: String) -> String {
        switch raw {
        case "pending":   return "예약 중"
        case "completed": return "이용 완료"
        case "cancelled": return "취소됨"
        default:          return raw
        }
    }
    
    // MARK: - 예약 취소
    @objc private func cancelTapped() {
        guard let userId = Auth.auth().currentUser?.uid,
              let reservation = reservation else { return }
        
        let alert = UIAlertController(
            title: "예약 취소",
            message: "정말 예약을 취소하시겠어요?",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "아니요", style: .cancel))
        alert.addAction(UIAlertAction(title: "취소하기", style: .destructive) { _ in
            self.cancelReservation(userId: userId, reservation: reservation)
        })
        
        present(alert, animated: true)
    }
    
    private func cancelReservation(userId: String, reservation: Reservation) {
        let userRef = db.collection("users")
            .document(userId)
            .collection("reservations")
            .document(reservation.id)
        
        userRef.updateData(["status" : "cancelled"]) { error in
            if let error = error {
                print("예약 취소 실패:", error.localizedDescription)
                self.showAlert(title: "오류", message: "예약 취소에 실패했습니다.")
                return
            }
            
            print("✅ 예약 취소 완료")
            self.showAlert(title: "취소 완료", message: "예약이 취소되었습니다.") {
                NotificationCenter.default.post(name: .reservationCancelled, object: nil)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}

extension Notification.Name {
    static let reservationCancelled = Notification.Name("reservationCancelled")
}
