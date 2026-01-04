//
//  NotificationDetailVC.swift
//  DangSalon
//
//  Created by 최영건 on 12/24/25.
//

import UIKit

final class NotificationDetailVC: UIViewController {
    
    private let notification: AppNotification
    
    init(notification: AppNotification) {
        self.notification = notification
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
}
