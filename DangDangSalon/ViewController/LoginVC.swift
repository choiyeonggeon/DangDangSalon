//
//  LoginVC.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/22/25.
//

import UIKit
import SnapKit
import CryptoKit
import FirebaseAuth
import FirebaseFirestore
import KakaoSDKAuth
import KakaoSDKCommon
import AuthenticationServices

class LoginVC: UIViewController {
    
    private var currentNonce: String?
    
    private let emailField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "이메일"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .emailAddress
        return tf
    }()
    
    private let passwordField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "비밀번호"
        tf.borderStyle = .roundedRect
        tf.isSecureTextEntry = true
        return tf
    }()
    
    private let loginButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("로그인", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 10
        btn.titleLabel?.font = .boldSystemFont(ofSize: 16)
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return btn
    }()
    
    private let signupButton: UIButton = {
        let btn = UIButton()
        btn.setTitle("회원가입", for: .normal)
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        return btn
    }()
    
    private let kakaoButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("카카오로 로그인", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(red: 1.0, green: 0.92, blue: 0.0, alpha: 1.0)
        btn.layer.cornerRadius = 10
        btn.titleLabel?.font = .boldSystemFont(ofSize: 16)
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return btn
    }()
    
    private let appleButton: ASAuthorizationAppleIDButton = {
        let btn = ASAuthorizationAppleIDButton()
        btn.cornerRadius = 10
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.text = "로그인"
        lb.font = .boldSystemFont(ofSize: 26)
        lb.textAlignment = .center
        return lb
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        appleButton.isUserInteractionEnabled = true
        setupUI()
        //        kakaoLoginWithApp()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        signupButton.addTarget(self, action: #selector(handleSignup), for: .touchUpInside)
        kakaoButton.addTarget(self, action: #selector(handleKakaoLogin), for: .touchUpInside)
        appleButton.addTarget(self, action: #selector(handleAppleLogin), for: .touchUpInside)
    }
    
    //    func kakaoLoginWithApp() {
    //        UserApi.shared.loginWithKakaoTalk { (oauthToken, error) in
    //            if let error = error {
    //
    //            }
    //        }
    //    }
    
    private func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [
            emailField,
            passwordField,
            loginButton,
            kakaoButton,
            appleButton,
            signupButton
        ])
        
        stackView.axis = .vertical
        stackView.spacing = 14
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        
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
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func handleLogin() {
        guard let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            showAlert(title: "입력 오류", message: "이메일과 비밀번호를 모두 입력해주세요.")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("로그인 실패:", error.localizedDescription)
                self.showAlert(title: "로그인 실패", message: "이메일 또는 비밀번호를 다시 확인해주세요.")
                return
            }
            
            NotificationCenter.default.post(name: .AuthStateDidChange, object: nil)
            
            let tabBarVC = MainTabBarController()
            tabBarVC.modalPresentationStyle = .fullScreen
            self.present(tabBarVC, animated: true)
        }
    }
    
    @objc private func handleSignup() {
        let signupVC = SignupVC()
        navigationController?.pushViewController(signupVC, animated: true)
    }
    
    @objc private func handleKakaoLogin() {
        
    }
    
    @objc private func handleAppleLogin() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        // 🔥 Firebase 인증 위해 SHA256 nonce 넣기
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

extension LoginVC: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        self.view.window ?? UIWindow()
    }
}

extension LoginVC: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        print("🍎 Apple 로그인 실패:", error.localizedDescription)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            guard let identityToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: identityToken, encoding: .utf8),
                  let nonce = currentNonce else {
                print("Apple 로그인: Token 또는 Nonce 문제")
                return
            }
            
            // 🔥 Firebase Auth Credential 생성
            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )
            
            // 🔥 Firebase 로그인
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase 로그인 실패:", error.localizedDescription)
                    return
                }
                
                print("🍎 Firebase Apple 로그인 성공!")
                
                guard let user = authResult?.user else { return }
                let uid = user.uid
                let db = Firestore.firestore()
                
                // Apple에서 제공되는 이름 정보
                let fullName = appleIDCredential.fullName
                let email = appleIDCredential.email
                
                let nickname = fullName?.givenName ?? "사용자"
                
                // 1️⃣ Firestore 유저 문서 확인 후 없으면 생성
                let userRef = db.collection("users").document(uid)
                
                userRef.getDocument { snapshot, _ in
                    if snapshot?.exists == true {
                        // 이미 있는 유저 → 바로 로그인 진행
                        self.finishLogin()
                        return
                    }
                    
                    // 신규 유저 → Firestore 정보 생성
                    let data: [String: Any] = [
                        "nickname": nickname,
                        "email": email ?? user.email ?? "",
                        "loginProvider": "apple",
                        "createdAt": Timestamp()
                    ]
                    
                    userRef.setData(data) { error in
                        if let error = error {
                            print("Firestore 생성 실패:", error.localizedDescription)
                        } else {
                            print("🔥 Firestore 신규 유저 생성 완료")
                        }
                        self.finishLogin()
                    }
                }
            }
        }
    }
    
    private func finishLogin() {
        NotificationCenter.default.post(name: .AuthStateDidChange, object: nil)
        let tabBarVC = MainTabBarController()
        tabBarVC.modalPresentationStyle = .fullScreen
        self.present(tabBarVC, animated: true)
    }
}

extension LoginVC {
    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms = (0 ..< 16).map { _ in UInt8.random(in: 0 ... 255) }
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
