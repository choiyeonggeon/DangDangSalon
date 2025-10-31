//
//  MainTabBarController.swift
//  DangDangSalon
//
//  Created by 최영건 on 10/16/25.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        configureAppearance()
    }
    
    private func setupTabs() {
        let homeVC = UINavigationController(rootViewController: HomeVC())
        let reservationVC = UINavigationController(rootViewController: MyReservationVC())
        let favoriteVC = UINavigationController(rootViewController: FavoritesVC())
        let moreVC = UINavigationController(rootViewController: MoreVC())
        
        homeVC.tabBarItem = UITabBarItem(
            title: "홈",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        
        reservationVC.tabBarItem = UITabBarItem(
            title: "예약",
            image: UIImage(systemName: "calendar"),
            selectedImage: UIImage(systemName: "calendar.circle.fill")
        )
        
        favoriteVC.tabBarItem = UITabBarItem(
            title: "즐겨찾기",
            image: UIImage(systemName: "heart"),
            selectedImage: UIImage(systemName: "heart.fill")
            )
        
        moreVC.tabBarItem = UITabBarItem(
            title: "더보기",
            image: UIImage(systemName: "ellipsis.circle"),
            selectedImage: UIImage(systemName: "ellipsis.circle.fill")
        )
        
        viewControllers = [homeVC, reservationVC, favoriteVC, moreVC]
    }
    
    private func configureAppearance() {
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .lightGray
        tabBar.layer.cornerRadius = 20
        tabBar.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMinYCorner]
        tabBar.layer.masksToBounds = true
    }
}
