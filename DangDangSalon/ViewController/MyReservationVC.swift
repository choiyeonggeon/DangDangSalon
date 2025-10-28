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
    
    private let appNameLabel: UILabel = {
        let label = UILabel()
        label.text = "댕살롱"
        label.font = UIFont(name: "GmarketSansBold", size: 34)
        label.textColor = UIColor.systemBlue
        label.textAlignment = .left
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "예약 내역"
        label.font = .boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        return label
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "아직 예약이 없어요 🐶"
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(ReservationCell.self, forCellReuseIdentifier: "ReservationCell")
        tv.separatorStyle = .none
        tv.rowHeight = 70
        tv.isHidden = true
        return tv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
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
    
    // MARK: - Firestore 불러오기
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
                    self.emptyLabel.isHidden = false
                    self.tableView.isHidden = true
                    return
                }
                
                guard let docs = snapshot?.documents else {
                    self.emptyLabel.isHidden = false
                    self.tableView.isHidden = true
                    return
                }
                
                self.reservations = docs.compactMap { Reservation(document: $0) }
                
                DispatchQueue.main.async {
                    let hasData = !self.reservations.isEmpty
                    self.tableView.isHidden = !hasData
                    self.emptyLabel.isHidden = hasData
                    self.tableView.reloadData()
                }
            }
    }
    
    // MARK: - Layout
    private func setupLayout() {
        [appNameLabel, titleLabel, tableView, emptyLabel].forEach { view.addSubview($0) }
        
        appNameLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(-10)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(appNameLabel.snp.bottom).offset(10)
            $0.centerX.equalToSuperview()
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        
        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
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
        ) as? ReservationCell else {
            return UITableViewCell()
        }
        
        let reservation = reservations[indexPath.row]
        cell.configure(with: reservation)
        
        // 리뷰 작성 버튼 눌렀을 때
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
    
    // ✅ 셀 클릭 시 상세 보기로 이동
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = ReservationDetailVC()
        vc.reservation = reservations[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
}
