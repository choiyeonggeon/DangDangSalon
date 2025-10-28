//
//  SignupVC.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/23/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

class SignupVC: UIViewController {
    
    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "회원가입"
        lb.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        return lb
    }()
    
    private let nicknameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "닉네임"
        tf.borderStyle = .roundedRect
        return tf
    }()
    
    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "이메일"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .emailAddress
        return tf
    }()
    
    private let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "비밀번호 (특수문자 포함, 최소 8자)"
        tf.borderStyle = .roundedRect
        tf.isSecureTextEntry = true
        return tf
    }()
    
    private let passwordConfirmTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "비밀번호 확인"
        tf.borderStyle = .roundedRect
        tf.isSecureTextEntry = true
        return tf
    }()
    
    private let phoneNumberTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "전화번호 예) +821012345678"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .phonePad
        return tf
    }()
    
    private let verifyCodeTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "인증번호 입력"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .numberPad
        tf.isHidden = true
        return tf
    }()
    
    private let sendCodeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("인증번호 보내기", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        btn.backgroundColor = .systemGray5
        btn.layer.cornerRadius = 8
        return btn
    }()
    
    private let signupButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("회원가입", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 10
        btn.titleLabel?.font = .boldSystemFont(ofSize: 16)
        btn.backgroundColor = .systemBlue
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return btn
    }()
    
    private var verificationID: String?
    private let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        
        signupButton.addTarget(self, action: #selector(didTapSignupBtn), for: .touchUpInside)
        sendCodeButton.addTarget(self, action: #selector(didTapSendCode), for: .touchUpInside)
    }
    
    private func setupUI() {
        let phoneStack = UIStackView(arrangedSubviews: [phoneNumberTextField, sendCodeButton])
        phoneStack.axis = .horizontal
        phoneStack.spacing = 10
        phoneStack.distribution = .fillProportionally
        sendCodeButton.snp.makeConstraints { $0.width.equalTo(120) }
        
        let stackView = UIStackView(arrangedSubviews: [
            nicknameTextField,
            emailTextField,
            passwordTextField,
            passwordConfirmTextField,
            phoneStack,
            verifyCodeTextField,
            signupButton
        ])
        
        stackView.axis = .vertical
        stackView.spacing = 14
        stackView.alignment = .fill
        
        view.addSubview(titleLabel)
        view.addSubview(stackView)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(60)
            $0.centerX.equalToSuperview()
        }
        
        stackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(40)
            $0.leading.trailing.equalToSuperview().inset(40)
        }
    }
    
    // MARK: - 유효성 검사
    private func isValidPassword(_ password: String) -> Bool {
        let passwordRegex = "^(?=.*[!@#$%^&*(),.?\":{}|<>]).{8,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return predicate.evaluate(with: password)
    }
    
    // MARK: - 닉네임 중복 확인
    private func checkNicknameDuplicate(_ nickname: String, completion: @escaping (Bool) -> Void) {
        db.collection("users")
            .whereField("nickname", isEqualTo: nickname)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("닉네임 중복 확인 실패: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                completion(snapshot?.documents.isEmpty ?? true)
            }
    }
    
    // MARK: - 인증번호 전송
    @objc private func didTapSendCode() {
        guard let phone = phoneNumberTextField.text, !phone.isEmpty else {
            showAlert(title: "입력 오류", message: "전화번호를 입력해주세요.")
            return
        }
        
        PhoneAuthProvider.provider().verifyPhoneNumber(phone, uiDelegate: nil) { verificationID, error in
            if let error = error {
                self.showAlert(title: "인증 실패", message: error.localizedDescription)
                return
            }
            self.verificationID = verificationID
            self.verifyCodeTextField.isHidden = false
            self.showAlert(title: "인증번호 전송", message: "입력한 번호로 인증번호가 전송되었습니다.")
        }
    }
    
    // MARK: - 회원가입 처리
    @objc private func didTapSignupBtn() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let confirmPassword = passwordConfirmTextField.text, !confirmPassword.isEmpty,
              let phone = phoneNumberTextField.text, !phone.isEmpty,
              let nickname = nicknameTextField.text, !nickname.isEmpty else {
            showAlert(title: "입력 오류", message: "모든 필드를 입력해주세요.")
            return
        }
        
        guard password == confirmPassword else {
            showAlert(title: "비밀번호 불일치", message: "비밀번호가 일치하지 않습니다.")
            return
        }
        
        guard isValidPassword(password) else {
            showAlert(title: "비밀번호 오류", message: "비밀번호는 최소 8자 이상이며 특수문자를 포함해야 합니다.")
            return
        }
        
        // ✅ 닉네임 중복 검사
        checkNicknameDuplicate(nickname) { isAvailable in
            guard isAvailable else {
                self.showAlert(title: "닉네임 중복", message: "이미 사용 중인 닉네임입니다.")
                return
            }
            
            // ✅ 인증번호 확인 (선택적)
            if let verificationID = self.verificationID,
               let code = self.verifyCodeTextField.text, !code.isEmpty {
                
                let credential = PhoneAuthProvider.provider().credential(
                    withVerificationID: verificationID,
                    verificationCode: code
                )
                
                Auth.auth().signIn(with: credential) { _, error in
                    if let error = error {
                        self.showAlert(title: "인증 실패", message: error.localizedDescription)
                        return
                    }
                    self.createAccount(email: email, password: password, nickname: nickname, phone: phone)
                }
            } else {
                self.showAlert(title: "인증 필요", message: "휴대폰 인증을 완료해주세요.")
            }
        }
    }
    
    // MARK: - 실제 회원가입 로직
    private func createAccount(email: String, password: String, nickname: String, phone: String) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.showAlert(title: "회원가입 실패", message: error.localizedDescription)
                return
            }
            
            guard let uid = result?.user.uid else { return }
            self.db.collection("users").document(uid).setData([
                "nickname": nickname,
                "email": email,
                "phone": phone,
                "createdAt": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    self.showAlert(title: "저장 실패", message: error.localizedDescription)
                } else {
                    self.showAlert(title: "회원가입 완료", message: "정상적으로 가입되었습니다.")
                }
            }
        }
    }
    
    // MARK: - 공용 알림
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
