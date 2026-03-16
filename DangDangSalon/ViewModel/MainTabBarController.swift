//
//  MainTabBarController.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/16/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkAdminAndSetupTabs()
        configureAppearance()
    }
    
    private func checkAdminAndSetupTabs() {
        guard let uid = Auth.auth().currentUser?.uid else {
            setupTabs(isAdmin: false)
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snap, _ in
            let role = snap?.data()?["role"] as? String ?? ""
            let isAdmin = (role == "admin")
            
            DispatchQueue.main.async {
                self.setupTabs(isAdmin: isAdmin)
            }
        }
    }
    
    private func setupTabs(isAdmin: Bool) {
        let homeVC = UINavigationController(rootViewController: HomeVC())
        let reservationVC = UINavigationController(rootViewController: MyReservationVC())
        let favoriteVC = UINavigationController(rootViewController: FavoritesVC())
        let moreVC = UINavigationController(rootViewController: MoreVC())
        
        homeVC.tabBarItem = UITabBarItem(title: "홈", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
        
        reservationVC.tabBarItem = UITabBarItem(title: "예약", image: UIImage(systemName: "calendar"), selectedImage: UIImage(systemName: "calendar.circle.fill"))
        
        favoriteVC.tabBarItem = UITabBarItem(title: "즐겨찾기", image: UIImage(systemName: "heart"), selectedImage: UIImage(systemName: "heart.fill"))
        
        moreVC.tabBarItem = UITabBarItem(title: "더보기", image: UIImage(systemName: "ellipsis.circle"), selectedImage: UIImage(systemName: "ellipsis.circle.fill"))
        
        var vcs: [UIViewController] = [homeVC, reservationVC, favoriteVC, moreVC]
        
        if isAdmin {
            let adminVC = UINavigationController(rootViewController: AdminVC())
            adminVC.tabBarItem = UITabBarItem(
                title: "관리자",
                image: UIImage(systemName: "person.crop.circle.badge.checkmark"),
                selectedImage: UIImage(systemName: "person.crop.circle.badge.checkmark.fill")
            )
            vcs.append(adminVC)
        }
        
        self.viewControllers = vcs
    }
    
    private func configureAppearance() {
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .lightGray
        tabBar.layer.cornerRadius = 20
        tabBar.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner]
        tabBar.layer.masksToBounds = true
    }
}
