//
//  MyReservationVC.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/16/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

final class MyReservationVC: UIViewController {
    
    private let db = Firestore.firestore()
    private var reservations: [Reservation] = []
    
    // MARK: - UI
    private let headerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 20
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowOffset = CGSize(width: 0, height: 3)
        v.layer.shadowRadius = 6
        return v
    }()
    
    private let appNameLabel: UILabel = {
        let label = UILabel()
        label.text = "댕살롱"
        label.font = UIFont(name: "GmarketSansBold", size: 34)
        label.textColor = UIColor.systemBlue
        label.textAlignment = .left
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "🐾 예약 내역"
        label.font = .boldSystemFont(ofSize: 22)
        label.textColor = .label
        return label
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.register(ReservationCell.self, forCellReuseIdentifier: "ReservationCell")
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        return tv
    }()
    
    private let emptyView: UIView = {
        let v = UIView()
        v.isHidden = true
        let img = UIImageView(image: UIImage(systemName: "pawprint.circle.fill"))
        img.tintColor = .systemGray4
        let label = UILabel()
        label.text = "아직 예약이 없어요 🐶"
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [img, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        v.addSubview(stack)
        stack.snp.makeConstraints { $0.center.equalToSuperview() }
        return v
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "예약 내역"
        setupLayout()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fetchReservations),
            name: .reservationCancelled,
            object: nil
        )
        
        fetchReservations()
    }
    
    // MARK: - Firestore
    @objc private func fetchReservations() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("로그인 정보 없음")
            return
        }
        
        db.collection("users")
            .document(userId)
            .collection("reservations")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("예약 불러오기 실패:", error.localizedDescription)
                    self.showEmptyState()
                    return
                }
                guard let docs = snapshot?.documents else {
                    self.showEmptyState()
                    return
                }
                self.reservations = docs.compactMap { Reservation(document: $0) }
                DispatchQueue.main.async {
                    if self.reservations.isEmpty {
                        self.showEmptyState()
                    } else {
                        self.emptyView.isHidden = true
                        self.tableView.isHidden = false
                        self.tableView.reloadData()
                    }
                }
            }
    }
    
    private func showEmptyState() {
        DispatchQueue.main.async {
            self.emptyView.isHidden = false
            self.tableView.isHidden = true
        }
    }
    
    // MARK: - Layout
    private func setupLayout() {
        [headerView, tableView, emptyView].forEach { view.addSubview($0) }
        [appNameLabel, titleLabel].forEach { headerView.addSubview($0) }
        
        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(110)
        }
        appNameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.leading.equalToSuperview().inset(20)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(appNameLabel.snp.bottom).offset(8)
            $0.leading.equalTo(appNameLabel)
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}

// MARK: - TableView
extension MyReservationVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        reservations.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "ReservationCell",
            for: indexPath
        ) as? ReservationCell else { return UITableViewCell() }
        
        let reservation = reservations[indexPath.row]
        cell.configure(with: reservation)
        
        cell.writeReviewAction = { [weak self] in
            guard let self = self else { return }
            let vc = ReviewWriteVC()
            vc.shopId = reservation.shopId
            if let userId = Auth.auth().currentUser?.uid {
                vc.reservationPath = (userId: userId, reservationId: reservation.id)
            }
            vc.modalPresentationStyle = .pageSheet
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
            self.present(vc, animated: true)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = ReservationDetailVC()
        vc.reservation = reservations[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
}
