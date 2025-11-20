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
    
    // 🔹 새로 추가: 액션(전화/지도/신고)용 카드
    private let actionsCardView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 20
        v.layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        v.layer.shadowOpacity = 0.18
        v.layer.shadowRadius = 8
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
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
    private lazy var request = makeRow(title: "요청사항")
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
        lb.text = "예약 2시간 전까지만 취소 가능합니다."
        lb.font = .systemFont(ofSize: 13, weight: .regular)
        lb.textColor = .secondaryLabel
        lb.textAlignment = .center
        lb.numberOfLines = 0
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
    
    private let reportIconButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "exclamationmark.triangle.fill"), for: .normal)
        btn.tintColor = .systemRed
        btn.contentHorizontalAlignment = .fill
        btn.contentVerticalAlignment = .fill
        btn.imageView?.contentMode = .scaleAspectFit
        return btn
    }()
    
    private let actionIconStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalCentering
        stack.spacing = 40
        return stack
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
        contentView.addSubview(actionsCardView)   // 🔹 액션 카드 추가
        view.addSubview(cancelButton)
        view.addSubview(reviewButton)
        view.addSubview(guideLabel)
        
        actionIconStack.addArrangedSubview(callIconButton)
        actionIconStack.addArrangedSubview(mapIconButton)
        actionIconStack.addArrangedSubview(reportIconButton)
        
        // 🔹 스택은 actionsCardView 안으로
        actionsCardView.addSubview(actionIconStack)
        
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
            
            request.container,
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
        
        // 🔹 액션 카드 레이아웃 (전화/지도/신고)
        actionsCardView.snp.makeConstraints {
            $0.top.equalTo(cardView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        actionIconStack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(14)
            $0.leading.trailing.equalToSuperview().inset(32)
            $0.height.equalTo(40)
        }
        
        // 🔹 스크롤 콘텐츠 높이 = actionsCardView 기준
        contentView.snp.makeConstraints {
            $0.bottom.equalTo(actionsCardView.snp.bottom).offset(40)
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
        mapIconButton.addTarget(self, action: #selector(openMap), for: .touchUpInside)
        callIconButton.addTarget(self, action: #selector(callShop), for: .touchUpInside)
        reportIconButton.addTarget(self, action: #selector(reportTapped), for: .touchUpInside)
    }
    
    private func configureData() {
        guard let r = reservation else { return }
        
        shopRow.valueLabel.text   = r.shopName
        menuRow.valueLabel.text   = r.menus.joined(separator: ", ")
        dateRow.valueLabel.text   = r.dateString
        timeRow.valueLabel.text   = r.time
        priceRow.valueLabel.text  = "\(r.priceString)"
        request.valueLabel.text  = r.request
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
    
    // MARK: - 예약 취소
    @objc private func cancelTapped() {
        guard let userId = Auth.auth().currentUser?.uid,
              let reservation = reservation else { return }
        
        let now = Date()
        let reservationDate = reservation.date
        
        let isPast = reservationDate <= now
        let hoursUntilReservation = reservationDate.timeIntervalSince(now) / 3600.0
        let withinTwoHours = hoursUntilReservation <= 2.0
        
        var message: String
        var canCancel = true
        
        if isPast {
            message = "이미 지난 예약은 취소할 수 없습니다."
            canCancel = false
        } else if withinTwoHours {
            message = "예약 2시간 전 이후에는 앱에서 취소할 수 없습니다.\n매장에 직접 문의해 주세요."
            canCancel = false
        } else {
            message = "정말 예약을 취소하시겠어요?"
            canCancel = true
        }
        
        let alert = UIAlertController(title: "예약 취소",
                                      message: message,
                                      preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
        
        if canCancel {
            alert.addAction(UIAlertAction(title: "취소하기", style: .destructive) { _ in
                self.showCancelReasonAlert(userId: userId, reservation: reservation)
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
    
    private func submitReservationReport(userId: String, reservation: Reservation, reason: String) {
        
        let reportId = UUID().uuidString
        
        let data: [String: Any] = [
            "reportId": reportId,
            "reservationId": reservation.id,
            "reporterId": userId,
            "targetOwnerId": reservation.ownerId,
            "reason": reason,
            "status": "pending",
            "createdAt": Timestamp()
        ]
        
        db.collection("reservationReports").document(reportId).setData(data) { err in
            if let err = err {
                self.showAlert(title: "오류", message: "신고 접수에 실패했습니다.\n\(err.localizedDescription)")
                return
            }
            
            self.showAlert(title: "신고 완료", message: "신고가 정상적으로 접수되었습니다.")
        }
    }
    
    @objc private func openMap() {
        guard let r = reservation else { return }
        
        guard let addr = r.address, !addr.isEmpty else {
            showAlert(title: "주소 없음", message: "해당 샵의 주소 정보가 없습니다.")
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
    
    @objc private func callShop() {
        guard let r = reservation else { return }
        
        guard let rawPhone = r.phone else {
            showAlert(title: "전화번호 없음", message: "해당 샵의 전화번호가 없습니다.")
            return
        }
        
        let phone = rawPhone.replacingOccurrences(of: "-", with: "")
        
        if phone.isEmpty {
            showAlert(title: "전화번호 없음", message: "해당 샵의 전화번호가 없습니다.")
            return
        }
        
        if let url = URL(string: "tel://\(phone)") {
            UIApplication.shared.open(url)
        }
    }
    
    @objc private func reportTapped() {
        guard let userId = Auth.auth().currentUser?.uid,
              let r = reservation else { return }
        
        let alert = UIAlertController(
            title: "예약 신고하기",
            message: "신고 사유를 입력해주세요.",
            preferredStyle: .alert
        )
        
        alert.addTextField { tf in
            tf.placeholder = "예: 매장이 임의로 예약을 취소했어요"
        }
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "신고하기", style: .destructive, handler: { _ in
            
            let reason = alert.textFields?.first?.text?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            if reason.isEmpty {
                self.showAlert(title: "입력 필요", message: "신고 사유를 입력해주세요.")
                return
            }
            
            self.submitReservationReport(userId: userId, reservation: r, reason: reason)
        }))
        
        present(alert, animated: true)
    }
    
    // MARK: - 리뷰 작성
    @objc private func writeReviewTapped() {
        
        guard let userId = Auth.auth().currentUser?.uid,
              let reservation = reservation else { return }
        
        let reservationRef = db
            .collection("users").document(userId)
            .collection("reservations").document(reservation.id)
        
        // 🔥 Firestore에서 reviewWritten 확인
        reservationRef.getDocument { snap, error in
            if let error = error {
                print("리뷰 상태 확인 실패:", error.localizedDescription)
                return
            }
            
            let already = snap?.data()?["reviewWritten"] as? Bool ?? false
            
            if already {
                // 🔥 이미 작성한 경우 UI 차단
                self.showAlert(
                    title: "리뷰 작성 완료",
                    message: "이미 이 예약에 대한 리뷰를 작성하셨습니다."
                )
                return
            }
            
            // 🔥 리뷰 작성 가능 → 화면 이동
            let vc = ReviewWriteVC()
            vc.reservation = reservation
            vc.shopId = reservation.shopId
            vc.reservationPath = (userId: userId, reservationId: reservation.id)
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func cancelReservation(userId: String, reservation: Reservation, reason: String) {
        let doc = db.collection("reservations").document(reservation.id)
        
        doc.updateData([
            "status": "취소",
            "cancelReason": reason,
            "cancelledAt": Timestamp()
        ]) { [weak self] err in
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
    
    private func showCancelReasonAlert(userId: String, reservation: Reservation) {
        let alert = UIAlertController(
            title: "취소 사유",
            message: "취소하시는 이유를 입력해주세요.",
            preferredStyle: .alert
        )
        
        alert.addTextField { tf in
            tf.placeholder = "예: 갑작스런 일정 변경 등"
        }
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "확인", style: .destructive, handler: { _ in
            let reason = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            self.cancelReservation(userId: userId, reservation: reservation, reason: reason)
        }))
        
        present(alert, animated: true)
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
