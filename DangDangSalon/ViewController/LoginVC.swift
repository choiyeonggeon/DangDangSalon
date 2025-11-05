//
//  LoginVC.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/22/25.
//

import UIKit
import SnapKit
import FirebaseAuth
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
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        
        request.requestedScopes = [.fullName, .email]
        
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
        print("로그인 실패:", error.localizedDescription)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIdCredential as ASAuthorizationAppleIDCredential:
            let userIdentifier = appleIdCredential.user
            let fullName = appleIdCredential.fullName
            let email = appleIdCredential.email
            
            let identityToken = appleIdCredential.identityToken
            let authorizationCode = appleIdCredential.authorizationCode
            
            print("Apple ID 로그인에 성공하였습니다.")
            print("사용자 ID: \(userIdentifier)")
            print("전체 이름: \(fullName?.givenName ?? "") \(fullName?.familyName ?? "")")
            print("이메일: \(email ?? "")")
            print("Token: \(identityToken!)")
            print("authorizationCode: \(authorizationCode!)")
            
            let tabBarVC = MainTabBarController()
            tabBarVC.modalPresentationStyle = .fullScreen
            self.present(tabBarVC, animated: true)
            
        case let passwordCredential as ASPasswordCredential:
            let userIdentifier = passwordCredential.user
            let password = passwordCredential.password
            
            print("암호 기반 인증에 성공하였습니다.")
            print("사용자 이름: \(userIdentifier)")
            print("비밀번호: \(password)")
            
            let tabBarVC = MainTabBarController()
            tabBarVC.modalPresentationStyle = .fullScreen
            self.present(tabBarVC, animated: true)
            
            
        default:
            break
        }
    }
}
