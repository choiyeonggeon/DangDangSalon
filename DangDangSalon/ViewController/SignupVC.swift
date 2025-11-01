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

final class SignupVC: UIViewController, UITextFieldDelegate {
    
    // MARK: - UI
    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "회원가입"
        lb.font = .boldSystemFont(ofSize: 24)
        return lb
    }()
    
    private let nicknameTextField = UITextField.makeSignupField(placeholder: "닉네임")
    private let emailTextField = UITextField.makeSignupField(placeholder: "이메일", keyboardType: .emailAddress)
    private let passwordTextField = UITextField.makeSignupField(placeholder: "비밀번호 (특수문자 포함, 최소 8자)", isSecure: true)
    private let passwordConfirmTextField = UITextField.makeSignupField(placeholder: "비밀번호 확인", isSecure: true)
    private let phoneNumberTextField = UITextField.makeSignupField(placeholder: "전화번호 예) +821012345678", keyboardType: .phonePad)
    private let verifyCodeTextField = UITextField.makeSignupField(placeholder: "인증번호 입력", keyboardType: .numberPad, hidden: true)
    
    // 에러 라벨
    private let nicknameErrorLabel = UILabel.makeErrorLabel()
    private let emailErrorLabel = UILabel.makeErrorLabel()
    private let passwordErrorLabel = UILabel.makeErrorLabel()
    private let confirmErrorLabel = UILabel.makeErrorLabel()
    private let phoneErrorLabel = UILabel.makeErrorLabel()
    private let verifyErrorLabel = UILabel.makeErrorLabel()
    
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupTextFieldTargets()
        
        signupButton.addTarget(self, action: #selector(didTapSignupBtn), for: .touchUpInside)
        sendCodeButton.addTarget(self, action: #selector(didTapSendCode), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - UI 세팅
    private func setupUI() {
        let phoneStack = UIStackView(arrangedSubviews: [phoneNumberTextField, sendCodeButton])
        phoneStack.axis = .horizontal
        phoneStack.spacing = 10
        phoneStack.distribution = .fillProportionally
        sendCodeButton.snp.makeConstraints { $0.width.equalTo(120) }
        
        let fields = [
            nicknameTextField, nicknameErrorLabel,
            emailTextField, emailErrorLabel,
            passwordTextField, passwordErrorLabel,
            passwordConfirmTextField, confirmErrorLabel,
            phoneStack, phoneErrorLabel,
            verifyCodeTextField, verifyErrorLabel,
            signupButton
        ]
        
        let stackView = UIStackView(arrangedSubviews: fields)
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .fill
        
        view.addSubview(titleLabel)
        view.addSubview(stackView)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(50)
            $0.centerX.equalToSuperview()
        }
        stackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(40)
        }
    }
    
    // MARK: - 실시간 에러 제거 설정
    private func setupTextFieldTargets() {
        [nicknameTextField, emailTextField, passwordTextField, passwordConfirmTextField, phoneNumberTextField, verifyCodeTextField].forEach {
            $0.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            $0.delegate = self
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        switch textField {
        case nicknameTextField: nicknameErrorLabel.text = ""
        case emailTextField: emailErrorLabel.text = ""
        case passwordTextField: passwordErrorLabel.text = ""
        case passwordConfirmTextField: confirmErrorLabel.text = ""
        case phoneNumberTextField: phoneErrorLabel.text = ""
        case verifyCodeTextField: verifyErrorLabel.text = ""
        default: break
        }
    }
    
    private func clearErrors() {
        [nicknameErrorLabel, emailErrorLabel, passwordErrorLabel, confirmErrorLabel, phoneErrorLabel, verifyErrorLabel].forEach { $0.text = "" }
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        let regex = "^(?=.*[!@#$%^&*(),.?\":{}|<>]).{8,}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: password)
    }
    
    private func checkNicknameDuplicate(_ nickname: String, completion: @escaping (Bool) -> Void) {
        db.collection("users")
            .whereField("nickname", isEqualTo: nickname)
            .getDocuments { snapshot, _ in
                completion(snapshot?.documents.isEmpty ?? true)
            }
    }
    
    private func checkEmailDuplicate(_ email: String, completion: @escaping (Bool) -> Void) {
        db.collection("users")
            .whereField("email", isEqualTo: email)
            .getDocuments { snapshot, _ in
                completion(snapshot?.documents.isEmpty ?? true)
            }
    }
    
    // MARK: - 인증번호 전송
    @objc private func didTapSendCode() {
        clearErrors()
        guard let phone = phoneNumberTextField.text, !phone.isEmpty else {
            phoneErrorLabel.text = "전화번호를 입력해주세요."
            return
        }
        
        PhoneAuthProvider.provider().verifyPhoneNumber(phone, uiDelegate: nil) { verificationID, error in
            if let error = error {
                self.phoneErrorLabel.text = error.localizedDescription
                return
            }
            self.verificationID = verificationID
            self.verifyCodeTextField.isHidden = false
            self.verifyErrorLabel.text = "인증번호가 전송되었습니다."
        }
    }
    
    // MARK: - 회원가입
    @objc private func didTapSignupBtn() {
        clearErrors()
        
        guard let nickname = nicknameTextField.text, !nickname.isEmpty else {
            nicknameErrorLabel.text = "닉네임을 입력해주세요."
            return
        }
        guard let email = emailTextField.text, !email.isEmpty else {
            emailErrorLabel.text = "이메일을 입력해주세요."
            return
        }
        guard let password = passwordTextField.text, !password.isEmpty else {
            passwordErrorLabel.text = "비밀번호를 입력해주세요."
            return
        }
        guard let confirm = passwordConfirmTextField.text, !confirm.isEmpty else {
            confirmErrorLabel.text = "비밀번호를 다시 입력해주세요."
            return
        }
        guard password == confirm else {
            confirmErrorLabel.text = "비밀번호가 일치하지 않습니다."
            return
        }
        guard isValidPassword(password) else {
            passwordErrorLabel.text = "비밀번호는 8자 이상, 특수문자를 포함해야 합니다."
            return
        }
        guard let phone = phoneNumberTextField.text, !phone.isEmpty else {
            phoneErrorLabel.text = "전화번호를 입력해주세요."
            return
        }
        
        checkNicknameDuplicate(nickname) { isNickOK in
            DispatchQueue.main.async {
                guard isNickOK else {
                    self.nicknameErrorLabel.text = "이미 사용 중인 닉네임입니다."
                    return
                }
                self.checkEmailDuplicate(email) { isEmailOK in
                    DispatchQueue.main.async {
                        guard isEmailOK else {
                            self.emailErrorLabel.text = "이미 가입된 이메일입니다."
                            return
                        }
                        
                        guard let verificationID = self.verificationID,
                              let code = self.verifyCodeTextField.text, !code.isEmpty else {
                            self.verifyErrorLabel.text = "휴대폰 인증을 완료해주세요."
                            return
                        }
                        
                        let credential = PhoneAuthProvider.provider().credential(
                            withVerificationID: verificationID,
                            verificationCode: code
                        )
                        
                        Auth.auth().signIn(with: credential) { _, error in
                            if let error = error {
                                self.verifyErrorLabel.text = "인증 실패: \(error.localizedDescription)"
                                return
                            }
                            self.createAccount(email: email, password: password, nickname: nickname, phone: phone)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 계정 생성
    private func createAccount(email: String, password: String, nickname: String, phone: String) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error as NSError? {
                if error.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                    self.emailErrorLabel.text = "이미 등록된 이메일입니다."
                } else {
                    self.emailErrorLabel.text = error.localizedDescription
                }
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
                    self.emailErrorLabel.text = "저장 실패: \(error.localizedDescription)"
                } else {
                    let alert = UIAlertController(title: "회원가입 완료", message: "정상적으로 가입되었습니다.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}

// MARK: - Helper Extensions
private extension UITextField {
    static func makeSignupField(placeholder: String,
                                keyboardType: UIKeyboardType = .default,
                                isSecure: Bool = false,
                                hidden: Bool = false) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.borderStyle = .roundedRect
        tf.keyboardType = keyboardType
        tf.isSecureTextEntry = isSecure
        tf.isHidden = hidden
        return tf
    }
}

private extension UILabel {
    static func makeErrorLabel() -> UILabel {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 12)
        lb.textColor = .systemRed
        lb.numberOfLines = 0
        lb.text = ""
        return lb
    }
}
