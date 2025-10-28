//
//  AppDelegate.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/15/25.
//

import UIKit
import TossPayments
import FirebaseFirestore
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        FirebaseApp.configure()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        let nav = UINavigationController(rootViewController: HomeVC())
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let urlString = url.absoluteString
        
        if urlString.starts(with: "dangdangs://success") {
            handlePaymentSuccess(url: url)
        } else if urlString.starts(with: "dangdangs://fail") {
            print("결제 실패: \(urlString)")
        }
        return true
    }
    
    private func handlePaymentSuccess(url: URL) {
        guard
            let components = URLComponents(string: url.absoluteString),
            let queryItems = components.queryItems
        else { return }
        
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
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
}

