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
import SDWebImage

final class ReservationDetailVC: UIViewController {
    
    // MARK: - 전달 데이터
    var reservation: Reservation? {
        didSet {
            if isViewLoaded {
                configureData()
            }
        }
    }
    
    private let db = Firestore.firestore()
    private var isReviewWritten: Bool = false
    
    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let petImageView = UIImageView()
    private let petNameLabel = UILabel()
    private let petBreedLabel = UILabel()
    
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
    private lazy var request   = makeRow(title: "요청사항")
    private lazy var statusRow = makeRow(title: "상태")
    
    private let sectionHeader: UILabel = {
        let label = UILabel()
        label.text = "예약 정보"
        label.font = .boldSystemFont(ofSize: 20)
        label.textColor = .label
        return label
    }()
    
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
        lb.text = "(!) 애견 미용 특성상 이용일 기준 이틀 전 이후 취소가 어렵습니다."
        lb.font = .systemFont(ofSize: 13, weight: .regular)
        lb.textColor = .secondaryLabel
        lb.textAlignment = .center
        lb.numberOfLines = 0
        lb.isHidden = true
        lb.isUserInteractionEnabled = true
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
    
    private let petInfoStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGroupedBackground
        title = "예약 상세"
        
        isReviewWritten = reservation?.reviewWritten ?? false
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleReviewWritten),
            name: .reviewWrittenForReservation,
            object: nil
        )
        
        setupPetInfoUI()
        setupUI()
        configureData()
        setupActions()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleReviewWritten(_ notification: Notification) {
        isReviewWritten = true
        configureData()
    }
    
    // MARK: - UI Setup
    private func setupPetInfoUI() {
        petImageView.contentMode = .scaleAspectFill
        petImageView.clipsToBounds = true
        petImageView.layer.cornerRadius = 30
        petImageView.backgroundColor = .systemGray5
        
        let labelsStack = UIStackView(arrangedSubviews: [petNameLabel, petBreedLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 4
        
        petNameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        petNameLabel.textColor = .label
        
        petBreedLabel.font = .systemFont(ofSize: 14, weight: .regular)
        petBreedLabel.textColor = .secondaryLabel
        
        petInfoStack.addArrangedSubview(petImageView)
        petInfoStack.addArrangedSubview(labelsStack)
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(sectionHeader)
        contentView.addSubview(petInfoStack)
        contentView.addSubview(cardView)
        contentView.addSubview(actionsCardView)
        view.addSubview(cancelButton)
        view.addSubview(reviewButton)
        view.addSubview(guideLabel)
        
        // Action Stack
        actionIconStack.addArrangedSubview(callIconButton)
        actionIconStack.addArrangedSubview(mapIconButton)
        actionIconStack.addArrangedSubview(reportIconButton)
        actionsCardView.addSubview(actionIconStack)
        
        // Card Stack
        let infoStack = UIStackView(arrangedSubviews: [
            shopRow.container,
            menuRow.container,
            dateRow.container,
            timeRow.container,
            priceRow.container,
            request.container,
            statusRow.container
        ])
        infoStack.axis = .vertical
        infoStack.spacing = 12
        cardView.addSubview(infoStack)
        
        // MARK: - SnapKit Constraints
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(cancelButton.snp.top).offset(-12)
        }
        
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView.snp.width)
        }
        
        sectionHeader.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        petInfoStack.snp.makeConstraints {
            $0.top.equalTo(sectionHeader.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        petImageView.snp.makeConstraints { $0.width.height.equalTo(60) }
        
        cardView.snp.makeConstraints {
            $0.top.equalTo(petInfoStack.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        infoStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }
        
        actionsCardView.snp.makeConstraints {
            $0.top.equalTo(cardView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(60)
            $0.bottom.equalToSuperview().offset(-20)
        }
        
        actionIconStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(14) }
        
        cancelButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(12)
            $0.height.equalTo(52)
        }
        
        reviewButton.snp.makeConstraints {
            $0.leading.trailing.equalTo(cancelButton)
            $0.bottom.equalTo(cancelButton.snp.top).offset(-12)
            $0.height.equalTo(52)
        }
        
        guideLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(reviewButton.snp.top).offset(-6)
        }
    }
    
    private func setupActions() {
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        reviewButton.addTarget(self, action: #selector(writeReviewTapped), for: .touchUpInside)
        callIconButton.addTarget(self, action: #selector(callShop), for: .touchUpInside)
        mapIconButton.addTarget(self, action: #selector(openMap), for: .touchUpInside)
        reportIconButton.addTarget(self, action: #selector(reportTapped), for: .touchUpInside)
        
        // 🔥 추가: 안내 문구 탭 이벤트
        let tap = UITapGestureRecognizer(target: self, action: #selector(showCancelPolicyDetail))
        guideLabel.addGestureRecognizer(tap)
    }
    
    // MARK: - Data Config
    private func configureData() {
        guard let r = reservation else { return }
        
        shopRow.valueLabel.text   = r.shopName
        menuRow.valueLabel.text   = r.menus.joined(separator: ", ")
        dateRow.valueLabel.text   = r.dateString
        timeRow.valueLabel.text   = r.time
        priceRow.valueLabel.text  = "\(r.priceString)"
        request.valueLabel.text  = r.request
        statusRow.valueLabel.text = statusText(for: r.status)
        
        if let petId = r.petId {
            loadPetInfo(petId: petId)
        } else {
            petNameLabel.text = "반려견 정보 없음"
            petBreedLabel.text = ""
            petImageView.image = UIImage(systemName: "pawprint.fill")
        }
        
        let alreadyReviewed = isReviewWritten || r.reviewWritten
        
        if alreadyReviewed {
            cancelButton.isHidden = true
            reviewButton.isHidden = true
            guideLabel.isHidden = true
            return
        }
        
        switch r.status {
        case "예약 중", "예약 요청", "확정":
            cancelButton.isHidden = false
            reviewButton.isHidden = true
            guideLabel.isHidden = false
            
        case "이용 완료", "완료":
            cancelButton.isHidden = true
            reviewButton.isHidden = false
            guideLabel.isHidden = true
            
        default:
            cancelButton.isHidden = true
            reviewButton.isHidden = true
            guideLabel.isHidden = true
        }
    }
    
    private func statusText(for raw: String) -> String {
        switch raw {
        case "예약 중": return "예약 중"
        case "이용 완료": return "이용 완료"
        case "취소": return "취소됨"
        default: return raw
        }
    }
    
    // MARK: - Pet Info
    // MARK: - Pet Info
    private func loadPetInfo(petId: String) {
        guard let uid = Auth.auth().currentUser?.uid else {
            showDefaultPetInfo()
            return
        }
        
        let petRef = db.collection("users").document(uid)
            .collection("pets").document(petId)
        
        petRef.getDocument { [weak self] snap, error in
            guard let self = self else { return }
            if let error = error {
                print("Pet info load error:", error.localizedDescription)
                self.showDefaultPetInfo()
                return
            }
            
            guard let snap = snap, snap.exists, let data = snap.data() else {
                self.showDefaultPetInfo()
                return
            }
            
            let pet = Pet(id: snap.documentID, data: data)
            
            DispatchQueue.main.async {
                self.petNameLabel.text = pet.name.isEmpty ? "이름 없음" : pet.name
                self.petBreedLabel.text = pet.breed.isEmpty ? "품종 없음" : pet.breed
                if let urlStr = pet.photoURL, let url = URL(string: urlStr) {
                    self.petImageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "pawprint.fill"))
                } else {
                    self.petImageView.image = UIImage(systemName: "pawprint.fill")
                }
            }
        }
    }
    
    private func showDefaultPetInfo() {
        DispatchQueue.main.async {
            self.petNameLabel.text = "반려견 정보 없음"
            self.petBreedLabel.text = ""
            self.petImageView.image = UIImage(systemName: "pawprint.fill")
        }
    }
    
    @objc private func showCancelPolicyDetail() {
        let msg = """
    애견 미용 서비스는 사전 준비가 필요한 특성상
    이용일 기준 이틀 전 이후에는 취소가 불가합니다.
    부득이한 경우 매장으로 문의해 주세요.
    """
        
        let alert = UIAlertController(title: "취소 안내", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        guard let userId = Auth.auth().currentUser?.uid, let reservation = reservation else { return }
        
        let now = Date()
        let reservationDate = reservation.date
        let hoursUntilReservation = reservationDate.timeIntervalSince(now) / 3600.0
        
        var message = ""
        var canCancel = true
        
        if reservationDate <= now {
            message = "이미 지난 예약은 취소할 수 없습니다."
            canCancel = false
        } else if hoursUntilReservation <= 48 {
            message = "애견 미용 서비스는 사전 준비가 필요한 특성상\n이용일 기준 이틀 전 이후에는 취소가 불가합니다.\n부득이한 경우 매장으로 문의해 주세요."
            canCancel = false
        } else {
            message = "정말 예약을 취소하시겠어요?"
        }
        
        let alert = UIAlertController(title: "예약 취소", message: message, preferredStyle: .actionSheet)
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
    
    private func showCancelReasonAlert(userId: String, reservation: Reservation) {
        let alert = UIAlertController(title: "취소 사유",
                                      message: "취소하시는 이유를 입력해주세요.",
                                      preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "예: 갑작스런 일정 변경 등" }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "확인", style: .destructive) { _ in
            let reason = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            self.cancelReservation(userId: userId, reservation: reservation, reason: reason)
        })
        present(alert, animated: true)
    }
    
    private func cancelReservation(userId: String, reservation: Reservation, reason: String) {
        db.collection("reservations").document(reservation.id)
            .updateData([
                "status": "취소",
                "cancelReason": reason,
                "cancelledAt": Timestamp()
            ]) { [weak self] err in
                guard let self = self else { return }
                if let err = err {
                    self.showAlert(title: "오류", message: "예약 취소에 실패했습니다.\n\(err.localizedDescription)")
                    return
                }
                self.showAlert(title: "취소 완료", message: "예약이 취소되었습니다.") {
                    NotificationCenter.default.post(name: .reservationCancelled, object: nil)
                    self.navigationController?.popViewController(animated: true)
                }
            }
    }
    
    @objc private func writeReviewTapped() {
        guard let userId = Auth.auth().currentUser?.uid,
              let reservation = reservation else { return }
        
        let reservationRef = db.collection("users").document(userId)
            .collection("reservations").document(reservation.id)
        
        reservationRef.getDocument { snap, error in
            if let error = error { print("리뷰 상태 확인 실패:", error.localizedDescription); return }
            let already = snap?.data()?["reviewWritten"] as? Bool ?? false
            if already {
                self.showAlert(title: "리뷰 작성 완료", message: "이미 이 예약에 대한 리뷰를 작성하셨습니다.")
                return
            }
            let vc = ReviewWriteVC()
            vc.reservation = reservation
            vc.shopId = reservation.shopId
            vc.reservationPath = (userId: userId, reservationId: reservation.id)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc private func callShop() {
        guard let phone = reservation?.phone?.replacingOccurrences(of: "-", with: ""),
              !phone.isEmpty,
              let url = URL(string: "tel://\(phone)") else {
            showAlert(title: "전화번호 없음", message: "해당 샵의 전화번호가 없습니다.")
            return
        }
        UIApplication.shared.open(url)
    }
    
    @objc private func openMap() {
        guard let addr = reservation?.address, !addr.isEmpty else {
            showAlert(title: "주소 없음", message: "해당 샵의 주소 정보가 없습니다.")
            return
        }
        let encoded = addr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let appURL = URL(string: "kakaomap://search?q=\(encoded)"),
           UIApplication.shared.canOpenURL(appURL) { UIApplication.shared.open(appURL); return }
        if let webURL = URL(string: "https://map.kakao.com/?q=\(encoded)") { UIApplication.shared.open(webURL) }
    }
    
    @objc private func reportTapped() {
        guard let userId = Auth.auth().currentUser?.uid, let r = reservation else { return }
        let alert = UIAlertController(title: "예약 신고하기", message: "신고 사유를 입력해주세요.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "예: 매장이 임의로 예약을 취소했어요" }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "신고하기", style: .destructive) { _ in
            let reason = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if reason.isEmpty { self.showAlert(title: "입력 필요", message: "신고 사유를 입력해주세요."); return }
            self.submitReservationReport(userId: userId, reservation: r, reason: reason)
        })
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
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }
}

extension Notification.Name {
    static let reservationCancelled = Notification.Name("reservationCancelled")
    //    static let reviewWrittenForReservation = Notification.Name("reviewWrittenForReservation")
}
