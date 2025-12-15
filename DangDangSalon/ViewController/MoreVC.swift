//
//  MoreVC.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/16/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

final class MoreVC: UIViewController {
    
    // MARK: - UI
    private let appNameLabel: UILabel = {
        let label = UILabel()
        label.text = "댕살롱"
        label.font = UIFont(name: "GmarketSansBold", size: 34)
        label.textColor = UIColor.systemBlue
        label.textAlignment = .left
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray6
        view.layer.cornerRadius = 16
        return view
    }()
    
    private let greetingLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 18)
        label.textColor = .label
        label.textAlignment = .left
        label.text = "로그인 후 이용해 주세요 👋"
        return label
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tv.backgroundColor = .clear
        tv.isScrollEnabled = true
        return tv
    }()
    
    private let companyInfoHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "(주) 댕살롱 사업자 정보 ▼"
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .darkGray
        label.textAlignment = .left
        label.isUserInteractionEnabled = true
        return label
    }()
    
    private let companyInfoDetailLabel: UILabel = {
        let label = UILabel()
        label.text =
        """
        상호명: (주) 댕살롱
        대표자: 최영건
        전화번호: 010-6505-3354
        사업자등록번호: 108-23-35549
        주소: 경기도 시흥시 정왕대로 233번안길 13-9 204호
        """
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .lightGray
        label.textAlignment = .left
        label.isHidden = true  // 처음엔 숨김
        return label
    }()
    
    
    // MARK: - Data
    private var menuItems: [String] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleCompanyInfo))
        companyInfoHeaderLabel.addGestureRecognizer(tap)
        
        setupUI()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        updateMenuItems()
        updateHeaderGreeting()
        setupCompanyInfoSection()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMenuItems),
            name: .AuthStateDidChange,
            object: nil
        )
    }
    
    // MARK: - Layout
    private func setupUI() {
        view.addSubview(appNameLabel)
        view.addSubview(headerView)
        headerView.addSubview(greetingLabel)
        view.addSubview(tableView)
        
        appNameLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(-10)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        headerView.snp.makeConstraints {
            $0.top.equalTo(appNameLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(70)
        }
        
        greetingLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }
    
    // MARK: - 메뉴 구성
    @objc private func updateMenuItems() {
        if Auth.auth().currentUser != nil {
            menuItems = [
                "로그아웃",
                "내 정보",
                "내 쿠폰",
                "반려견 등록",
                "결제 내역",
                "공지사항",
                "고객센터",
                "개인정보처리방침",
                "앱 버전 정보",
                "회원탈퇴"
            ]
        } else {
            menuItems = [
                "로그인",
                "내 정보",
                "결제 내역",
                "공지사항",
                "고객센터",
                "개인정보처리방침",
                "앱 버전 정보"
            ]
        }
        updateHeaderGreeting()
        tableView.reloadData()
    }
    
    // MARK: - 상단 인사문구
    private func updateHeaderGreeting() {
        if let user = Auth.auth().currentUser {
            let uid = user.uid
            let db = Firestore.firestore()
            
            db.collection("users").document(uid).getDocument { snapshot, error in
                if let data = snapshot?.data(),
                   let nickname = data["nickname"] as? String {
                    self.greetingLabel.text = "안녕하세요, \(nickname)님 👋"
                } else {
                    self.greetingLabel.text = "안녕하세요, \(user.email ?? "댕살롱 회원")님 👋"
                }
            }
        } else {
            greetingLabel.text = "로그인 후 이용해 주세요 👋"
        }
    }
    
    private func setupCompanyInfoSection() {

        let footerContainer = UIView()
        footerContainer.backgroundColor = .clear

        footerContainer.addSubview(companyInfoHeaderLabel)
        footerContainer.addSubview(companyInfoDetailLabel)

        companyInfoHeaderLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        companyInfoDetailLabel.snp.makeConstraints {
            $0.top.equalTo(companyInfoHeaderLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-12)   // footer 끝
        }

        // footer 크기 자동 계산
        footerContainer.layoutIfNeeded()
        footerContainer.frame.size.height = footerContainer.systemLayoutSizeFitting(
            CGSize(width: UIScreen.main.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        ).height

        tableView.tableFooterView = footerContainer
    }
    
    @objc private func toggleCompanyInfo() {
        let isHidden = companyInfoDetailLabel.isHidden
        
        companyInfoDetailLabel.isHidden = !isHidden
        
        UIView.animate(withDuration: 0.25) {
            if isHidden {
                self.companyInfoHeaderLabel.text = "(주) 댕살롱 사업자 정보 ▲"
            } else {
                self.companyInfoHeaderLabel.text = "(주) 댕살롱 사업자 정보 ▼"
            }
            self.view.layoutIfNeeded()
        }
    }
    
}

// MARK: - UITableViewDelegate & DataSource
extension MoreVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let title = menuItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = title
        cell.accessoryType = .disclosureIndicator
        
        // 🔥 회원탈퇴는 빨간색 + 화살표 제거
        if title == "회원탈퇴" {
            cell.textLabel?.textColor = .systemRed
            cell.accessoryType = .none
        } else {
            cell.textLabel?.textColor = .label
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedItem = menuItems[indexPath.row]
        
        switch selectedItem {
        case "로그인":
            navigationController?.pushViewController(LoginVC(), animated: true)
            
        case "로그아웃":
            do {
                try Auth.auth().signOut()
                updateMenuItems()
                showAlert(title: "로그아웃 완료", message: "성공적으로 로그아웃되었습니다.")
            } catch {
                showAlert(title: "오류", message: "로그아웃 중 문제가 발생했습니다.")
            }
            
        case "내 정보":
            navigationController?.pushViewController(MyInfoVC(), animated: true)
            
        case "내 쿠폰":
            navigationController?.pushViewController(MyCouponVC(), animated: true)
            
        case "반려견 등록":
            navigationController?.pushViewController(PetListVC(), animated: true)
            
        case "결제 내역":
            navigationController?.pushViewController(PaymentHistoryVC(), animated: true)
            
        case "공지사항":
            navigationController?.pushViewController(NoticeVC(), animated: true)
            
        case "고객센터":
            navigationController?.pushViewController(CustomerServiceVC(), animated: true)
            
        case "개인정보처리방침":
            navigationController?.pushViewController(PDFViewrVC(), animated: true)
            
        case "앱 버전 정보":
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                showAlert(title: "앱 버전", message: "현재 버전: \(version)")
            }
            
        case "회원탈퇴":
            confirmDeleteAccount()
            
        default:
            break
        }
    }
    
    // MARK: - 회원탈퇴 확인 팝업
    private func confirmDeleteAccount() {
        let alert = UIAlertController(
            title: "회원탈퇴",
            message: "정말 탈퇴하시겠습니까?\n탈퇴 시 모든 데이터가 즉시 삭제되며 복구할 수 없습니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "탈퇴하기", style: .destructive, handler: { _ in
            self.deleteAccount()
        }))
        
        present(alert, animated: true)
    }
    
    // MARK: - 회원탈퇴 실제 처리
    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        let uid = user.uid
        let db = Firestore.firestore()
        
        // 1️⃣ Firestore 유저 문서 삭제
        db.collection("users").document(uid).delete { error in
            if let error = error {
                self.showAlert(title: "오류", message: "데이터 삭제 실패: \(error.localizedDescription)")
                return
            }
            
            // 2️⃣ Firebase Auth 계정 삭제
            user.delete { error in
                if let error = error {
                    // Apple/Kakao 로그인은 재인증 필요할 수 있음
                    self.showAlert(title: "오류", message: "계정 삭제 실패: \(error.localizedDescription)")
                    return
                }
                
                // 3️⃣ 성공 처리
                let done = UIAlertController(
                    title: "탈퇴 완료",
                    message: "계정이 성공적으로 삭제되었습니다.",
                    preferredStyle: .alert
                )
                done.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                    self.updateMenuItems()
                })
                self.present(done, animated: true)
            }
        }
    }
    
    // MARK: - Alert Helper
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - AuthState Notification 확장
extension Notification.Name {
    static let AuthStateDidChange = Notification.Name("AuthStateDidChange")
}
