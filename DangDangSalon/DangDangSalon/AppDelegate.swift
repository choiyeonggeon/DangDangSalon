//
//  AppDelegate.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/15/25.
//

import UIKit
import TossPayments
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications
import KakaoSDKCommon
import KakaoSDKAuth
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Kakao
        KakaoSDK.initSDK(appKey: "${NATIVE_APP_KEY}")
        
        // Firebase
        FirebaseApp.configure()
        
        // 🔥 push delegate 등록
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        // 🔥 알림 권한 요청 (iOS 10+)
        requestPushAuthorization(application)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        let nav = UINavigationController(rootViewController: HomeVC())
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
        
        return true
    }
    
    // MARK: - 알림 권한 요청 + APNs 등록
    private func requestPushAuthorization(_ application: UIApplication) {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions
        ) { granted, error in
            if let error = error {
                print("알림 권한 요청 실패: \(error.localizedDescription)")
            }
            print("알림 권한: \(granted)")
        }
        
        // 🔥 APNs 등록
        application.registerForRemoteNotifications()
    }
    
    // MARK: - APNs 토큰 수신 (필수)
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token received")
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // MARK: - Firebase -> FCM 토큰 수신
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("📱 FCM Token: \(fcmToken ?? "")")
        
        guard let fcmToken = fcmToken,
              let user = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let collection = user.email?.contains("owner") == true ? "owner" : "users"
        
        db.collection(collection)
            .document(user.uid)
            .setData(["fcmToken": fcmToken], merge: true)
    }
    
    // MARK: - Foreground 알림 표시 방식
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    // MARK: - Toss 결제 URL 처리
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        let urlString = url.absoluteString
        
        if urlString.starts(with: "dangdangs://success") {
            handlePaymentSuccess(url: url)
            return true
        } else if urlString.starts(with: "dangdangs://fail") {
            print("결제 실패:", urlString)
            return true
        }
        
        // 카카오 로그인 URL 처리
        if (AuthApi.isKakaoTalkLoginUrl(url)) {
            return AuthController.handleOpenUrl(url: url)
        }
        
        return false
    }
    
    // MARK: - Toss 결제 Firestore 저장
    private func handlePaymentSuccess(url: URL) {
        guard let components = URLComponents(string: url.absoluteString),
              let queryItems = components.queryItems else { return }
        
        let orderId = queryItems.first(where: { $0.name == "orderId" })?.value ?? ""
        let shopId = queryItems.first(where: { $0.name == "shopId" })?.value ?? ""
        
        let db = Firestore.firestore()
        db.collection("payments").document(orderId).setData([
            "shopId": shopId,
            "orderId": orderId,
            "status": "success",
            "timestamp": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Firestore 저장 실패:", error.localizedDescription)
            } else {
                print("결제 완료 저장됨: \(orderId)")
            }
        }
    }
    
    // Scene 생명주기 (필요 시)
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
}
