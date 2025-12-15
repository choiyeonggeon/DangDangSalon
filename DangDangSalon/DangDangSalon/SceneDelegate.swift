//
//  SceneDelegate.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/15/25.
//

import UIKit
import KakaoSDKAuth
import TossPayments

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.overrideUserInterfaceStyle = .light

        let splashView = SplashViewVC()
        window?.rootViewController = splashView
        window?.makeKeyAndVisible()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let mainVC = MainTabBarController()
            let nav = UINavigationController(rootViewController: mainVC)
            nav.isNavigationBarHidden = true
            self.window?.rootViewController = nav
        }
    }

    // 🔥 Toss BrandPay + 결제 콜백 직접 처리 버전 (정상 동작)
    func scene(_ scene: UIScene,
               openURLContexts URLContexts: Set<UIOpenURLContext>) {

        guard let url = URLContexts.first?.url else { return }
        print("📌 [SceneDelegate] OpenURL:", url.absoluteString)

        // --- Toss BrandPay / 결제 콜백 ---
        if url.scheme == "dangsalon" {

            // 성공 콜백 패턴: dangsalon://success?orderId=...&amount=...
            if url.host == "success" ||
               url.host == "brandpay" ||
               url.host == "brandpay-callback" ||
               url.absoluteString.contains("brandpay") {

                NotificationCenter.default.post(
                    name: NSNotification.Name("BrandPayCallback"),
                    object: url
                )
                return
            }

            // 실패 콜백: dangsalon://fail?code=...&message=...
            if url.host == "fail" {
                NotificationCenter.default.post(
                    name: NSNotification.Name("BrandPayFail"),
                    object: url
                )
                return
            }
        }

        // --- Kakao 로그인 콜백 ---
        if AuthApi.isKakaoTalkLoginUrl(url) {
            _ = AuthController.handleOpenUrl(url: url)
        }
    }
}
