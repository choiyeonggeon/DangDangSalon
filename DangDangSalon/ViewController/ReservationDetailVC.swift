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
    
    var reservation: Reservation? {
        didSet {
            if isViewLoaded {
                configureData()
            }
        }
    }
    
    private let db = Firestore.firestore()
    
    // ✅ 로컬 플래그: 리뷰 작성 여부
    private var isReviewWritten: Bool = false
    
    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 20
        v.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        v.layer.shadowOpacity = 0.15
        v.layer.shadowRadius = 10
        v.layer.shadowOffset = CGSize(width: 0, height: 5)
        return v
    }()
    
    private func makeRow(title: String) -> (container: UIStackView, valueLabel: UILabel) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        
        let valueLabel = UILabel()
        valueLabel.text = "-"
        valueLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 0
        
        let row = UIStackView(arrangedSubviews: [titleLabel, UIView(), valueLabel])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        return (row, valueLabel)
    }
    
    private lazy var shopRow   = makeRow(title: "샵명")
    private lazy var menuRow   = makeRow(title: "이용 메뉴")
    private lazy var dateRow   = makeRow(title: "예약일")
    private lazy var timeRow   = makeRow(title: "예약 시간")
    private lazy var priceRow  = makeRow(title: "결제 금액")
    private lazy var statusRow = makeRow(title: "상태")
    
    private let sectionHeader: UILabel = {
        let label = UILabel()
        label.text = "예약 정보"
        label.font = .boldSystemFont(ofSize: 20)
        label.textColor = .label
        return label
    }()
    
    private func makeSeparator() -> UIView {
        let line = UIView()
        line.backgroundColor = .systemGray5
        line.snp.makeConstraints { $0.height.equalTo(1 / UIScreen.main.scale) }
        return line
    }
    
    private let cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("예약 취소하기", for: .normal)
        btn.backgroundColor = .systemRed
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.layer.cornerRadius = 14
        btn.layer.shadowColor = UIColor.systemRed.cgColor
        btn.layer.shadowOpacity = 0.25
        btn.layer.shadowRadius = 6
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        return btn
    }()
    
    private let reviewButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("리뷰 작성하기", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.layer.cornerRadius = 14
        btn.layer.shadowRadius = 6
        btn.layer.shadowOpacity = 0.25
        btn.layer.shadowColor = UIColor.systemBlue.cgColor
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.isHidden = true
        return btn
    }()
    
    private let guideLabel: UILabel = {
        let lb = UILabel()
        lb.text = "예약 2시간 전까지만 취소 가능하며,\n예약 요청 24시간 이후에는 10%의 수수료가 부과됩니다."
        lb.font = .systemFont(ofSize: 13, weight: .regular)
        lb.textColor = .secondaryLabel
        lb.textAlignment = .center
        lb.numberOfLines = 0
        lb.isHidden = true
        return lb
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGroupedBackground
        title = "예약 상세"
        
        // ✅ 최초 상태 동기화
        isReviewWritten = reservation?.reviewWritten ?? false
        
        // ✅ 리뷰 작성 완료 시 알림 받기
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleReviewWritten),
            name: .reviewWrittenForReservation,
            object: nil
        )
        
        setupUI()
        configureData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // ✅ 리뷰 작성 완료 알림 받았을 때
    @objc private func handleReviewWritten(_ notification: Notification) {
        isReviewWritten = true
        configureData()   // UI 다시 세팅
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(sectionHeader)
        contentView.addSubview(cardView)
        view.addSubview(cancelButton)
        view.addSubview(reviewButton)
        view.addSubview(guideLabel)
        
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(cancelButton.snp.top).offset(-16)
        }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView.snp.width)
        }
        
        sectionHeader.snp.makeConstraints {
            $0.top.equalToSuperview().offset(32)
            $0.leading.equalToSuperview().offset(24)
        }
        
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
        stack.spacing = 18
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20)
        
        cardView.addSubview(stack)
        cardView.snp.makeConstraints {
            $0.top.equalTo(sectionHeader.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        contentView.snp.makeConstraints {
            $0.bottom.equalTo(cardView.snp.bottom).offset(40)
        }
        
        cancelButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(40)
            $0.height.equalTo(54)
        }
        
        reviewButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(40)
            $0.height.equalTo(54)
        }
        
        guideLabel.snp.makeConstraints {
            $0.top.equalTo(cancelButton.snp.bottom).offset(6)
            $0.centerX.equalToSuperview()
        }
        
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        reviewButton.addTarget(self, action: #selector(writeReviewTapped), for: .touchUpInside)
    }
    
    private func configureData() {
        guard let r = reservation else { return }
        
        shopRow.valueLabel.text   = r.shopName
        menuRow.valueLabel.text   = r.menus.joined(separator: ", ")
        dateRow.valueLabel.text   = r.dateString
        timeRow.valueLabel.text   = r.time
        priceRow.valueLabel.text  = "\(r.priceString)"
        statusRow.valueLabel.text = statusText(for: r.status)
        
        // ✅ 리뷰 작성 여부 체크 (Firestore 값 + 로컬 플래그 둘 다 반영)
        let alreadyReviewed = isReviewWritten || r.reviewWritten
        
        if alreadyReviewed {
            cancelButton.isHidden = true
            reviewButton.isHidden = true
            guideLabel.isHidden = true
            return
        }
        
        // 상태별 버튼 UI 조정
        switch r.status {
        case "예약 중", "예약 요청", "확정":
            cancelButton.isHidden = false
            reviewButton.isHidden = true
            guideLabel.isHidden = false
            cancelButton.setTitle("예약 취소하기", for: .normal)
            
        case "이용 완료", "완료":
            cancelButton.isHidden = true
            reviewButton.isHidden = false
            guideLabel.isHidden = true
            
        case "취소":
            cancelButton.isHidden = true
            reviewButton.isHidden = true
            guideLabel.isHidden = true
            
        default:
            cancelButton.isHidden = true
            reviewButton.isHidden = true
            guideLabel.isHidden = true
        }
    }
    
    private func statusText(for raw: String) -> String {
        switch raw {
        case "예약 중":   return "예약 중"
        case "이용 완료": return "이용 완료"
        case "취소":     return "취소됨"
        default:          return raw
        }
    }
    
    // MARK: - 수수료 부과 취소
    private func chargeCancellationFee(userId: String, reservation: Reservation) {
        let feeRate = 0.1 // 예: 10% 수수료
        let totalPrice = reservation.totalPrice
        let feeAmount = Int(Double(totalPrice) * feeRate)
        
        let message = "예약을 취소하면 \(feeAmount)원이 수수료로 부과됩니다.\n계속 진행하시겠어요?"
        
        let alert = UIAlertController(title: "수수료 안내", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "돌아가기", style: .cancel))
        alert.addAction(UIAlertAction(title: "확인", style: .destructive) { _ in
            let doc = self.db.collection("reservations").document(reservation.id)
            doc.updateData([
                "status": "취소",
                "cancellationFee": feeAmount,
                "cancelledAt": Timestamp()
            ]) { [weak self] err in
                guard let self = self else { return }
                if let err = err {
                    print("예약 취소 실패:", err.localizedDescription)
                    self.showAlert(title: "오류", message: "예약 취소에 실패했습니다.")
                    return
                }
                
                self.showAlert(title: "취소 완료", message: "수수료 \(feeAmount)원이 부과되었습니다.") {
                    NotificationCenter.default.post(name: .reservationCancelled, object: nil)
                    self.navigationController?.popViewController(animated: true)
                }
            }
        })
        present(alert, animated: true)
    }
    
    // MARK: - 예약 취소
    @objc private func cancelTapped() {
        guard let userId = Auth.auth().currentUser?.uid,
              let reservation = reservation else { return }
        
        let now = Date()
        let reservationDate = reservation.date
        let createdAt = reservation.createdAt
        
        let hoursSinceCreation = now.timeIntervalSince(createdAt) / 3600.0
        let hoursUntilReservation = reservationDate.timeIntervalSince(now) / 3600.0
        
        let isPast = reservationDate <= now
        let withinTwoHours = hoursUntilReservation <= 2.0
        let isFreeCancellation = hoursSinceCreation <= 24.0
        
        var message: String
        var canCancel = true
        var willChargeFee = false
        
        if isPast {
            message = "이미 지난 예약은 취소할 수 없습니다."
            canCancel = false
        } else if withinTwoHours {
            message = "예약 2시간 전 이후에는 앱에서 취소할 수 없습니다.\n매장에 직접 문의해 주세요."
            canCancel = false
        } else if isFreeCancellation {
            message = "예약 요청 후 24시간 이내이므로 수수료 없이 취소할 수 있습니다.\n정말 취소하시겠어요?"
            willChargeFee = false
        } else {
            message = "예약 요청 후 24시간이 경과하여 취소 수수료 10%가 부과됩니다.\n그래도 취소하시겠어요?"
            willChargeFee = true
        }
        
        let alert = UIAlertController(title: "예약 취소", message: message, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
        
        if canCancel {
            alert.addAction(UIAlertAction(title: "취소하기", style: .destructive) { _ in
                if willChargeFee {
                    self.chargeCancellationFee(userId: userId, reservation: reservation)
                } else {
                    self.cancelReservation(userId: userId, reservation: reservation)
                }
            })
        }
        
        if let pop = alert.popoverPresentationController {
            pop.sourceView = self.view
            pop.sourceRect = CGRect(x: self.view.bounds.midX,
                                    y: self.view.bounds.midY,
                                    width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
    
    // MARK: - 리뷰 작성
    @objc private func writeReviewTapped() {
        let vc = ReviewWriteVC()
        vc.reservation = reservation
        vc.shopId = reservation?.shopId
        
        if let userId = Auth.auth().currentUser?.uid,
           let id = reservation?.id {
            vc.reservationPath = (userId: userId, reservationId: id)
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func cancelReservation(userId: String, reservation: Reservation) {
        let doc = db.collection("reservations").document(reservation.id)
        
        doc.updateData(["status": "취소"]) { [weak self] err in
            guard let self = self else { return }
            if let err = err {
                print("예약 취소 실패:", err.localizedDescription)
                self.showAlert(title: "오류", message: "예약 취소에 실패했습니다.")
                return
            }
            
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
