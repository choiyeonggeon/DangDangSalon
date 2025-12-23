////
////  NotificationInboxVC.swift
////  DangSalon
////
////  Created by 최영건 on 12/23/25.
////
//
//import UIKit
//import SnapKit
//import FirebaseAuth
//import FirebaseFirestore
//
//// 홈 화면 알림용
//final class NotificationInboxVC: UIViewController {
//    
//    private let tableView = UITableView()
//    
//    private let emptyLabel: UILabel = {
//        let lb = UILabel()
//        lb.text = "도착한 알림이 없어요 🔔"
//        lb.textAlignment = .center
//        lb.textColor = .secondaryLabel
//        lb.font = .systemFont(ofSize: 15)
//        
//        return lb
//    }()
//    
//    private var notifications: [AppNotification] = []
//    private var listener: ListenerRegistration?
//    
//    private let db = Firestore.firestore()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        fetchNotifications()
//    }
//    
//    private func setupUI() {
//        view.backgroundColor = .systemBackground
//        title = "알림"
//        
//        tableView.register(NotificationInboxCell.self, forCellReuseIdentifier: "NotificationInboxCell")
//        tableView.dataSource = self
//        tableView.delegate = self
//        tableView.separatorStyle = .none
//        
//        view.addSubview(tableView)
//        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
//    }
//    
//    private func fetchNotifications() {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//        
//        listener = db.collection("users")
//            .document(uid)
//            .collection("notifications")
//            .order(by: "createdAt", descending: true)
//            .addSnapshotListener { snapshot, _ in
//                self.notifications = snapshot?.documents.compactMap {
//                    AppNotification(doc: $0)
//                } ?? []
//                
//                self.tableView.reloadData()
//                self.updateEmptyState()
//            }
//    }
//    
//    private func markAsRead(_ notification: AppNotification) {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//        
//        db.collection("users")
//            .document(uid)
//            .collection("notifications")
//            .document(notification.id)
//            .updateData(["isRead": true])
//    }
//    
//    private func updateEmptyState() {
//        tableView.backgroundView = notifications.isEmpty ? emptyLabel : nil
//    }
//    
//    deinit {
//        listener?.remove()
//    }
//}
//
//extension NotificationInboxVC: UITableViewDataSource, UITableViewDelegate {
//    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        notifications.count
//    }
//    
//    func tableView(_ tableView: UITableView,
//                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        
//        guard let cell = tableView.dequeueReusableCell(
//            withIdentifier: "NotificationInboxCell",
//            for: indexPath
//        ) as? NotificationInboxCell else {
//            return UITableViewCell()
//        }
//        cell.configure(notifications[indexPath.row])
//        return cell
//    }
//    
//    func tableView(_ tableView: UITableView,
//                   didSelectRowAt indexPath: IndexPath) {
//        
//        let noti = notifications[indexPath.row]
//        markAsRead(noti)
//        
//        switch noti.type {
//        case .reservation:
//            let vc = ReservationDetailVC(reservationId: noti.targetId)
//            navigationController?.pushViewController(vc, animated: true)
//            
//        case .coupon:
//            let vc = MyCouponVC()
//            navigationController?.pushViewController(vc, animated: true)
//            
//        case .notice:
//            let vc = NotificationDetailVC(notification: noti)
//            navigationController?.pushViewController(vc, animated: true)
//        }
//    }
//    
//    func tableView(_ tableView: UITableView,
//                   heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 90
//    }
//}
