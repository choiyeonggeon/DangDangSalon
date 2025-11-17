//
//  FullImageViewerVC.swift
//  DangSalon
//
//  Created by 최영건 on 11/16/25.
//

import UIKit
import SnapKit

final class FullImageViewerVC: UIViewController, UIScrollViewDelegate {
    
    private let imageURLs: [String]
    private var startIndex: Int
    
    private let scrollView = UIScrollView()
    private let pagingScrollView = UIScrollView()
    
    init(imageURLs: [String], startIndex: Int) {
        self.imageURLs = imageURLs
        self.startIndex = startIndex
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupPagingScroll()
        loadImages()
        setupCloseGesture()
    }
    
    private func setupPagingScroll() {
        pagingScrollView.isPagingEnabled = true
        pagingScrollView.showsHorizontalScrollIndicator = false
        pagingScrollView.backgroundColor = .black
        
        view.addSubview(pagingScrollView)
        pagingScrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    private func loadImages() {
        let width = view.frame.width
        let height = view.frame.height
        
        pagingScrollView.contentSize = CGSize(width: width * CGFloat(imageURLs.count), height: height)
        
        for (index, urlString) in imageURLs.enumerated() {
            
            let zoomScroll = UIScrollView(frame: CGRect(x: width * CGFloat(index), y: 0, width: width, height: height))
            zoomScroll.minimumZoomScale = 1.0
            zoomScroll.maximumZoomScale = 3.0
            zoomScroll.delegate = self
            pagingScrollView.addSubview(zoomScroll)
            
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFit
            iv.backgroundColor = .black
            zoomScroll.addSubview(iv)
            
            iv.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.lessThanOrEqualToSuperview()
                make.height.lessThanOrEqualToSuperview()
            }
            
            if let url = URL(string: urlString) {
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data, let img = UIImage(data: data) {
                        DispatchQueue.main.async { iv.image = img }
                    }
                }.resume()
            }
        }
        
        pagingScrollView.contentOffset.x = width * CGFloat(startIndex)
    }
    
    private func setupCloseGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(close))
        view.addGestureRecognizer(tap)
    }
    
    @objc private func close() {
        dismiss(animated: true)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if scrollView != pagingScrollView {
            return scrollView.subviews.first
        }
        return nil
    }
}
