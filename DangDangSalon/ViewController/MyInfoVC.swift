//
//  MyInfoVC.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/23/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

class MyInfoVC: UIViewController {
    
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "person.circle.fill")
        iv.tintColor = .systemGray3
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 40
        iv.clipsToBounds = true
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 22)
        label.textAlignment = .center
        label.text = "로그인 필요"
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.text = "-"
        return label
    }()
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let actionButton = UIButton(type: .system)
    
    private var menuItems: [String] = ["예약 내역", "즐겨찾기", "고객센터", "닉네임 변경"]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "내 정보"
        
        setupLayout()
        setupTableView()
        setupActionButton()
        fetchUserInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUserInfo()
    }
    
    // MARK: - Setup
    private func setupLayout() {
        view.addSubview(profileImageView)
        view.addSubview(nameLabel)
        view.addSubview(emailLabel)
        view.addSubview(tableView)
        view.addSubview(actionButton)
        
        profileImageView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(80)
        }
        
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(profileImageView.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
        }
        
        emailLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.centerX.equalToSuperview()
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(emailLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(actionButton.snp.top).offset(-10)
        }
        
        actionButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.height.equalTo(50)
        }
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    private func setupActionButton() {
        actionButton.layer.cornerRadius = 12
        actionButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        actionButton.tintColor = .white
        updateButtonState()
    }
    
    // MARK: - User Info
    private func fetchUserInfo() {
        if let user = Auth.auth().currentUser {
            nameLabel.text = user.displayName ?? "닉네임 없음"
            emailLabel.text = user.email ?? "-"
            
            let db = Firestore.firestore()
            db.collection("users").document(user.uid).getDocument { snapshot, error in
                if let data = snapshot?.data(),
                   let nickname = data["nickname"] as? String {
                    DispatchQueue.main.async {
                        self.nameLabel.text = nickname
                    }
                }
            }
        } else {
            nameLabel.text = "로그인 필요"
            emailLabel.text = "-"
        }
        updateButtonState()
    }
    
    private func changeNickname() {
        let alert = UIAlertController(
            title: "닉네임 변경",
            message: "새로운 닉네임을 입력하세요.",
            preferredStyle: .alert
        )
        
        alert.addTextField { field in
            field.placeholder = "새 닉네임"
            field.autocapitalizationType = .none
        }
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "변경", style: .default, handler: { _ in
            guard let newName = alert.textFields?.first?.text?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  !newName.isEmpty else { return }
            
            self.checkNicknameDuplicate(newName)
        }))
        
        present(alert, animated: true)
    }
    
    private func checkNicknameDuplicate(_ newName: String) {
        let db = Firestore.firestore()
        
        // users 컬렉션에서 nickname이 동일한 문서가 있는지 검색
        db.collection("users")
            .whereField("nickname", isEqualTo: newName)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("중복 검사 실패:", error.localizedDescription)
                    self.showSimpleAlert("오류", "닉네임 중복 검사 중 오류가 발생했습니다.")
                    return
                }
                
                // 이미 같은 닉네임이 1개라도 존재하면 불가능
                if let docs = snapshot?.documents, !docs.isEmpty {
                    self.showSimpleAlert("중복된 닉네임", "이미 사용 중인 닉네임입니다.\n다른 닉네임을 선택해주세요.")
                    return
                }
                
                // 중복 아님 → Firestore 업데이트 진행
                self.updateNicknameInFirestore(newName)
            }
    }
    
    private func updateNicknameInFirestore(_ newName: String) {
        guard let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(user.uid)
            .updateData(["nickname": newName]) { error in
                
                if let error = error {
                    print("닉네임 변경 실패:", error.localizedDescription)
                    self.showSimpleAlert("오류", "닉네임 변경에 실패했습니다.")
                    return
                }
                
                DispatchQueue.main.async {
                    self.nameLabel.text = newName
                    self.showSimpleAlert("완료", "닉네임이 변경되었습니다.")
                }
            }
    }
    
    private func showSimpleAlert(_ title: String, _ message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "확인", style: .default))
        present(ac, animated: true)
    }
    
    // MARK: - Button State
    private func updateButtonState() {
        actionButton.removeTarget(nil, action: nil, for: .allEvents)
        
        if Auth.auth().currentUser == nil {
            actionButton.setTitle("로그인", for: .normal)
            actionButton.backgroundColor = .black
            actionButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        } else {
            actionButton.setTitle("로그아웃", for: .normal)
            actionButton.backgroundColor = .black
            actionButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        }
    }
    
    @objc private func loginTapped() {
        let vc = LoginVC()
        vc.modalPresentationStyle = .formSheet
        present(vc, animated: true)
    }
    
    // MARK: - Logout
    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "로그아웃", message: "정말 로그아웃하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "로그아웃", style: .destructive, handler: { _ in
            do {
                try Auth.auth().signOut()
                self.nameLabel.text = "로그인 필요"
                self.emailLabel.text = "-"
            } catch {
                print("로그아웃 실패:", error.localizedDescription)
            }
        }))
        present(alert, animated: true)
    }
}

// MARK: - TableView
extension MyInfoVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = menuItems[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 🔒 공통 로그인 체크
        func requireLogin(_ action: @escaping () -> Void) {
            if Auth.auth().currentUser == nil {
                let alert = UIAlertController(
                    title: "로그인 필요",
                    message: "이 기능은 로그인 후 이용할 수 있어요 🙂",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "로그인하기", style: .default, handler: { _ in
                    let vc = LoginVC()
                    vc.modalPresentationStyle = .formSheet
                    self.present(vc, animated: true)
                }))
                alert.addAction(UIAlertAction(title: "취소", style: .cancel))
                present(alert, animated: true)
            } else {
                action()
            }
        }
        
        switch indexPath.row {
        case 0:
            requireLogin {
                self.navigationController?.pushViewController(MyReservationVC(), animated: true)
            }
        case 1:
            requireLogin {
                self.navigationController?.pushViewController(FavoritesVC(), animated: true)
            }
        case 2:
            requireLogin {
                self.navigationController?.pushViewController(CustomerServiceVC(), animated: true)
            }
        case 3:
            requireLogin {
                self.changeNickname()
            }
        default:
            break
        }
    }
}
