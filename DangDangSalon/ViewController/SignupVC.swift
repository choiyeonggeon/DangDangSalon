//
//  SignupVC.swift
//  DangDangSalon
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore

final class SignupVC: UIViewController, UITextFieldDelegate {
    
    // MARK: - UI
    private let scrollView = UIScrollView()
    private let containerView = UIView()
    private let nameErrorLabel = UILabel.makeError()
    
    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "회원가입"
        lb.font = .boldSystemFont(ofSize: 28)
        lb.textAlignment = .left
        return lb
    }()
    
    // 입력 필드
    private let nicknameTextField = UITextField.makeField(icon: "person.fill", placeholder: "닉네임")
    private let fullNameTextField = UITextField.makeField(icon: "person.text.rectangle", placeholder: "이름 (실명)")
    private let emailTextField = UITextField.makeField(icon: "envelope.fill", placeholder: "이메일", keyboardType: .emailAddress)
    private let passwordTextField = UITextField.makeField(icon: "lock.fill", placeholder: "비밀번호 (8자 · 특수문자 포함)", isSecure: true)
    private let passwordConfirmTextField = UITextField.makeField(icon: "lock.rotation", placeholder: "비밀번호 확인", isSecure: true)
    
    // 전화번호 + 인증번호 전송
    private let phoneFieldContainer = UIView()
    private let phoneNumberTextField = UITextField.makeField(icon: "phone.fill", placeholder: "전화번호 (+8210...)")
    
    private let sendCodeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("전송", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.tintColor = .white
        btn.layer.cornerRadius = 8
        btn.titleLabel?.font = .boldSystemFont(ofSize: 14)
        return btn
    }()
    
    // 인증번호 입력 + 타이머
    private let verifyCodeContainer = UIView()
    private let verifyCodeTextField = UITextField.makeField(icon: "number", placeholder: "인증번호 입력", keyboardType: .numberPad, hidden: true)
    
    private let timerLabel: UILabel = {
        let lb = UILabel()
        lb.font = .systemFont(ofSize: 13)
        lb.textColor = .systemRed
        lb.text = ""
        return lb
    }()
    
    // 에러 라벨
    private let nicknameErrorLabel = UILabel.makeError()
    private let emailErrorLabel = UILabel.makeError()
    private let passwordErrorLabel = UILabel.makeError()
    private let confirmErrorLabel = UILabel.makeError()
    private let phoneErrorLabel = UILabel.makeError()
    private let verifyErrorLabel = UILabel.makeError()
    
    private let termsCheckbox: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "square"), for: .normal)
        btn.tintColor = .systemGray
        btn.contentHorizontalAlignment = .leading
        return btn
    }()
    
    private let termsLabel: UILabel = {
        let lb = UILabel()
        lb.text = "개인정보처리방침에 동의합니다."
        lb.font = .systemFont(ofSize: 14)
        lb.textColor = .label
        return lb
    }()
    
    private let openTermsButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("자세히 보기", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.setTitleColor(.systemBlue, for: .normal)
        return btn
    }()
    
    private var isTermsAgreed = false
    
    private let signupButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("회원가입 완료", for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.backgroundColor = .systemBlue
        btn.tintColor = .white
        btn.layer.cornerRadius = 12
        btn.isEnabled = false
        btn.alpha = 0.5
        btn.heightAnchor.constraint(equalToConstant: 54).isActive = true
        return btn
    }()
    
    // MARK: - Firebase
    private var verificationID: String?
    private let db = Firestore.firestore()
    
    // MARK: - Timer
    private var timer: Timer?
    private var timeLeft = 180 // 3분
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupUI()
        setupActions()
        setupKeyboardDismiss()
        
        nicknameTextField.delegate = self
        nicknameTextField.addTarget(self, action: #selector(nicknameEditingChanged(_:)), for: .editingChanged)
        termsCheckbox.addTarget(self, action: #selector(toggleTerms), for: .touchUpInside)
        openTermsButton.addTarget(self, action: #selector(openTerms), for: .touchUpInside)
        
    }
    
    // MARK: - UI 구성
    private func setupUI() {
        
        view.addSubview(scrollView)
        scrollView.addSubview(containerView)
        
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView.snp.width)
        }
        
        containerView.addSubview(titleLabel)
        
        // 전화번호 + 전송버튼
        phoneFieldContainer.addSubview(phoneNumberTextField)
        phoneFieldContainer.addSubview(sendCodeButton)
        
        phoneNumberTextField.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
        }
        sendCodeButton.snp.makeConstraints {
            $0.leading.equalTo(phoneNumberTextField.snp.trailing).offset(10)
            $0.trailing.centerY.equalToSuperview()
            $0.width.equalTo(70)
            $0.height.equalTo(40)
        }
        
        // 인증번호 + 타이머
        verifyCodeContainer.addSubview(verifyCodeTextField)
        verifyCodeContainer.addSubview(timerLabel)
        
        verifyCodeTextField.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }
        
        timerLabel.snp.makeConstraints {
            $0.top.equalTo(verifyCodeTextField.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(4)
            $0.bottom.equalToSuperview()
        }
        
        let termsStack = UIStackView(arrangedSubviews: [termsCheckbox, termsLabel, openTermsButton])
        termsStack.axis = .horizontal
        termsStack.spacing = 8
        termsStack.alignment = .center
        
        // Stack
        let stack = UIStackView(arrangedSubviews: [
            fullNameTextField, nameErrorLabel,
            nicknameTextField, nicknameErrorLabel,
            emailTextField, emailErrorLabel,
            passwordTextField, passwordErrorLabel,
            passwordConfirmTextField, confirmErrorLabel,
            phoneFieldContainer, phoneErrorLabel,
            verifyCodeContainer, verifyErrorLabel,
            termsStack, signupButton
        ])
        stack.axis = .vertical
        stack.spacing = 14
        
        containerView.addSubview(stack)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(30)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        stack.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().offset(-50)
        }
    }
    
    private func setupActions() {
        sendCodeButton.addTarget(self, action: #selector(sendCode), for: .touchUpInside)
        signupButton.addTarget(self, action: #selector(signup), for: .touchUpInside)
    }
    
    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(closeKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func closeKeyboard() { view.endEditing(true) }
    
    // MARK: - 닉네임 실시간 중복 체크
    @objc private func nicknameEditingChanged(_ tf: UITextField) {
        guard let nickname = tf.text, !nickname.isEmpty,
        let fullName = fullNameTextField.text, !fullName.isEmpty else {
            nicknameErrorLabel.text = ""
            nameErrorLabel.text = "이름을 입력해주세요."
            return
        }
        
        // 타자칠 때마다 부드럽게 애니메이션
        UIView.animate(withDuration: 0.2) {
            self.nicknameErrorLabel.alpha = 1
        }
        
        db.collection("users")
            .whereField("nickname", isEqualTo: nickname)
            .getDocuments { snapshot, _ in
                if let docs = snapshot?.documents, !docs.isEmpty {
                    self.nicknameErrorLabel.text = "이미 사용 중인 닉네임입니다."
                    self.nicknameErrorLabel.textColor = .systemRed
                } else {
                    self.nicknameErrorLabel.text = "사용 가능한 닉네임입니다."
                    self.nicknameErrorLabel.textColor = .systemGreen
                }
            }
    }
    
    // MARK: - 타이머 시작
    private func startTimer() {
        timeLeft = 180
        timerLabel.text = "남은 시간: 03:00"
        
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.timeLeft -= 1
            let min = self.timeLeft / 60
            let sec = self.timeLeft % 60
            
            self.timerLabel.text = String(format: "남은 시간: %02d:%02d", min, sec)
            
            if self.timeLeft <= 0 {
                self.timer?.invalidate()
                self.timerLabel.text = "인증 시간이 만료되었습니다."
            }
        }
    }
    
    // MARK: - 인증번호 전송
    @objc private func sendCode() {
        guard let rawPhone = phoneNumberTextField.text, !rawPhone.isEmpty else {
            phoneErrorLabel.text = "전화번호를 입력해주세요."
            return
        }

        // 🔥 사용자가 010으로 입력해도 +82로 자동 변환
        let phone = formatPhoneNumber(rawPhone)

        PhoneAuthProvider.provider().verifyPhoneNumber(phone, uiDelegate: nil) { id, error in
            if let error = error {
                self.phoneErrorLabel.text = error.localizedDescription
                return
            }
            
            self.verificationID = id
            self.verifyCodeTextField.isHidden = false
            self.verifyErrorLabel.text = "인증번호가 발송되었습니다."
            self.startTimer()
        }
    }
    
    /// 한국 휴대폰 번호를 Firebase용 E.164 포맷으로 변환
    private func formatPhoneNumber(_ raw: String) -> String {
        var number = raw.replacingOccurrences(of: "-", with: "")
        number = number.replacingOccurrences(of: " ", with: "")

        // 이미 +82 로 시작하면 그대로 반환
        if number.hasPrefix("+82") {
            return number
        }

        // "01012345678" -> "+821012345678"
        if number.hasPrefix("0") {
            number.removeFirst()
            return "+82" + number
        }

        // 예외처리: 그냥 숫자면 +82 붙여줌
        return "+82" + number
    }
    
    private func updateSignupButtonState() {
        signupButton.isEnabled = isTermsAgreed
        signupButton.alpha = isTermsAgreed ? 1.0 : 0.5
    }
    
    @objc private func toggleTerms() {
        isTermsAgreed.toggle()
        
        let imageName = isTermsAgreed ? "checkmark.square.fill" : "square"
        termsCheckbox.setImage(UIImage(systemName: imageName), for: .normal)
        termsCheckbox.tintColor = isTermsAgreed ? .systemBlue : .systemGray
        
        updateSignupButtonState()
    }
    
    @objc private func openTerms() {
        let vc = PDFViewrVC()
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }
    
    // MARK: - 비밀번호 정규식 검사
    private func isValidPassword(_ pw: String) -> Bool {
        let regex = "^(?=.*[!@#$%^&*(),.?\":{}|<>]).{8,}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: pw)
    }
    
    // MARK: - 회원가입
    @objc private func signup() {
        
        nicknameErrorLabel.text = ""
        emailErrorLabel.text = ""
        passwordErrorLabel.text = ""
        confirmErrorLabel.text = ""
        phoneErrorLabel.text = ""
        verifyErrorLabel.text = ""
        
        guard isTermsAgreed else {
            let alert = UIAlertController(
                title: "약관 동의 필요",
                message: "회원가입을 위해 개인정보처리방침에 동의해주세요.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
            return
        }
        
        guard let fullName = fullNameTextField.text, !fullName.isEmpty else {
            nameErrorLabel.text = "이름을 입력해주세요."
            return
        }
        
        guard let nickname = nicknameTextField.text, !nickname.isEmpty else {
            nicknameErrorLabel.text = "닉네임을 입력해주세요."
            return
        }
        guard let email = emailTextField.text, !email.isEmpty else {
            emailErrorLabel.text = "이메일을 입력해주세요."
            return
        }
        guard let pw = passwordTextField.text, !pw.isEmpty else {
            passwordErrorLabel.text = "비밀번호를 입력해주세요."
            return
        }
        guard isValidPassword(pw) else {
            passwordErrorLabel.text = "특수문자 포함 8자 이상 입력해주세요."
            return
        }
        guard pw == passwordConfirmTextField.text else {
            confirmErrorLabel.text = "비밀번호가 일치하지 않습니다."
            return
        }
        guard let phone = phoneNumberTextField.text, !phone.isEmpty else {
            phoneErrorLabel.text = "전화번호를 입력해주세요."
            return
        }
        
        // 인증번호 체크
        guard let vid = verificationID,
              let code = verifyCodeTextField.text, !code.isEmpty else {
            verifyErrorLabel.text = "인증번호를 입력해주세요."
            return
        }
        
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: vid, verificationCode: code)
        
        Auth.auth().signIn(with: credential) { _, error in
            if let error = error {
                self.verifyErrorLabel.text = "인증 실패: \(error.localizedDescription)"
                return
            }
            
            // 이메일 계정 생성
            self.createAccount(email: email, pw: pw, fullName: fullName, nickname: nickname, phone: phone)
        }
    }
    
    // MARK: - Firestore 저장
    private func createAccount(email: String, pw: String, fullName: String, nickname: String, phone: String) {
        Auth.auth().createUser(withEmail: email, password: pw) { result, error in
            if let error = error {
                self.emailErrorLabel.text = error.localizedDescription
                return
            }
            
            guard let uid = result?.user.uid else { return }
            
            self.db.collection("users").document(uid).setData([
                "name": fullName,
                "nickname": nickname,
                "email": email,
                "phone": phone,
                "createdAt": Timestamp(date: Date())
            ])
            
            let alert = UIAlertController(title: "가입 완료",
                                          message: "회원가입이 완료되었습니다.",
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
                let tabBarVC = MainTabBarController()
                tabBarVC.modalPresentationStyle = .fullScreen
                self.present(tabBarVC, animated: true)
            }))
            self.present(alert, animated: true)
            
        }
    }
}

// MARK: - UI 커스텀 Extension
private extension UITextField {
    static func makeField(icon: String,
                          placeholder: String,
                          keyboardType: UIKeyboardType = .default,
                          isSecure: Bool = false,
                          hidden: Bool = false) -> UITextField {
        
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.borderStyle = .roundedRect
        tf.keyboardType = keyboardType
        tf.isSecureTextEntry = isSecure
        tf.isHidden = hidden
        tf.backgroundColor = .secondarySystemBackground
        
        let iv = UIImageView(image: UIImage(systemName: icon))
        iv.tintColor = .gray
        iv.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        
        tf.leftView = iv
        tf.leftViewMode = .always
        
        tf.heightAnchor.constraint(equalToConstant: 52).isActive = true
        
        return tf
    }
}

private extension UILabel {
    static func makeError() -> UILabel {
        let lb = UILabel()
        lb.textColor = .systemRed
        lb.font = .systemFont(ofSize: 12)
        lb.numberOfLines = 0
        return lb
    }
}
