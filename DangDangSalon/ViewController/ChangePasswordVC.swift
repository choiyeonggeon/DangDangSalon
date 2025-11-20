//
//  ChangePasswordVC.swift
//  DangSalon
//
//  Created by 최영건 on 11/20/25.
//

import UIKit
import SnapKit
import FirebaseAuth

final class ChangePasswordVC: UIViewController {
    
    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "비밀번호 변경"
        lb.font = .boldSystemFont(ofSize: 26)
        lb.textAlignment = .center
        return lb
    }()
    
    private let currentPasswordField = CustomSecureField(placeholder: "현재 비밀번호")
    private let newPasswordField = CustomSecureField(placeholder: "새 비밀번호 (8자 + 특수문자)")
    private let confirmPasswordField = CustomSecureField(placeholder: "비밀번호 확인")
    
    private let changeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("비밀번호 변경", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.tintColor = .white
        btn.layer.cornerRadius = 12
        btn.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupLayout()
        setupActions()
    }
    
    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(currentPasswordField)
        view.addSubview(newPasswordField)
        view.addSubview(confirmPasswordField)
        view.addSubview(changeButton)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.centerX.equalToSuperview()
        }
        
        currentPasswordField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(40)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
        }
        
        newPasswordField.snp.makeConstraints {
            $0.top.equalTo(currentPasswordField.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
        }
        
        newPasswordField.snp.makeConstraints {
            $0.top.equalTo(newPasswordField.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
        }
        
        confirmPasswordField.snp.makeConstraints {
            $0.top.equalTo(newPasswordField.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
        }
        
        changeButton.snp.makeConstraints {
            $0.top.equalTo(confirmPasswordField.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(52)
        }
    }
    
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(closeKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func closeKeyboard() { view.endEditing(true) }
    
    // MARK: - Actions
    private func setupActions() {
        changeButton.addTarget(self, action: #selector(changePasswordTapped), for: .touchUpInside)
    }
    
    private func isValidPassword(_ pwd: String) -> Bool {
        let regex = "^(?=.*[!@#$%^&*(),.?\":{}|<>]).{8,}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: pwd)
    }
    
    @objc private func changePasswordTapped() {
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "오류", message: "로그인이 필요합니다.")
            return
        }
        
        guard let currentPwd = currentPasswordField.text, !currentPwd.isEmpty,
              let newPwd = newPasswordField.text, !newPwd.isEmpty,
              let confirmPwd = confirmPasswordField.text, !confirmPwd.isEmpty else {
            showAlert(title: "오류", message: "모든 필드를 입력해주세요.")
            return
        }
        
        guard newPwd == confirmPwd else {
            showAlert(title: "오류", message: "새 비밀번호가 일치하지 않습니다.")
            return
        }
        
        guard isValidPassword(newPwd) else {
            showAlert(title: "오류", message: "비밀번호는 8자 이상이며 특수문자를 포함해야 합니다.")
            return
        }
        
        let credential = EmailAuthProvider.credential(withEmail: user.email!, password: currentPwd)
        user.reauthenticate(with: credential) { _, error in
            if let _ = error {
                self.showAlert(title: "오류", message: "현재 비밀번호가 올바르지 않습니다.")
                return
            }
            
            user.updatePassword(to: newPwd) { error in
                if let error = error {
                    self.showAlert(title: "오류", message: "비밀번호 변경 실패\n\(error.localizedDescription)")
                    return
                }
                
                self.showAlert(title: "완료", message: "비밀번호가 성공적으로 변경되었습니다.") {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in completion?() }))
        present(ac, animated: true)
    }
}

// MARK: - Custom Secure TextField Component
final class CustomSecureField: UIView {
    private let textField = UITextField()
    private let toggleButton = UIButton(type: .system)
    
    var text: String? { textField.text }
    
    init(placeholder: String) {
        super.init(frame: .zero)
        
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray4.cgColor
        
        textField.placeholder = placeholder
        textField.isSecureTextEntry = true
        textField.autocapitalizationType = .none
        
        toggleButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        toggleButton.tintColor = .systemGray
        toggleButton.addTarget(self, action: #selector(toggleSecure), for: .touchUpInside)
        
        addSubview(textField)
        addSubview(toggleButton)
        
        textField.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(toggleButton.snp.leading).offset(-8)
        }
        
        toggleButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(24)
        }
    }
    
    @objc private func toggleSecure()  {
        textField.isSecureTextEntry.toggle()
        let name = textField.isSecureTextEntry ? "eye.slash.fill" : "eye.fill"
        toggleButton.setImage(UIImage(systemName: name), for: .normal)
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
