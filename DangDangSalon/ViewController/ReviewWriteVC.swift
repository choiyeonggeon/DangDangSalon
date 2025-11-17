//
//  ReviewWriteVC.swift
//  DangSalon
//
//  Created by 최영건 on 10/27/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

final class ReviewWriteVC: UIViewController {
    
    // MARK: - Properties
    var shopId: String?
    var reservation: Reservation?
    var reservationPath: (userId: String, reservationId: String)?
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private let imagePickerButton = UIButton(type: .system)
    private let imagePreview = UIScrollView()
    private var selectedImages: [UIImage] = []
    
    // MARK: - UI
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "리뷰 작성"
        label.font = .boldSystemFont(ofSize: 22)
        label.textAlignment = .center
        return label
    }()
    
    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.text = "별점을 선택해주세요."
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var starStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        for i in 1...5 {
            let button = UIButton(type: .system)
            button.tag = i
            button.setTitle("☆", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 36)
            button.tintColor = .black
            button.addTarget(self, action: #selector(starTapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
        return stack
    }()
    
    private var selectedRating: Int = 0 {
        didSet { updateStars() }
    }
    
    private let textView: UITextView = {
        let tv = UITextView()
        tv.text = "내용을 입력해주세요."
        tv.textColor = .lightGray
        tv.font = .systemFont(ofSize: 16)
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.layer.borderWidth = 1
        tv.layer.cornerRadius = 10
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return tv
    }()
    
    private let submitButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("등록하기", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.tintColor = .white
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        btn.layer.cornerRadius = 10
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return btn
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        textView.delegate = self
        
        if let r = reservation {
            print("리뷰 작성 대상 샵:", r.shopName)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func starTapped(_ sender: UIButton) {
        selectedRating = sender.tag
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func submitTapped() {
        guard let shopId = shopId else { return }
        guard selectedRating > 0 else {
            showAlert(title: "별점 선택", message: "별점을 선택해주세요.")
            return
        }
        
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, text != "내용을 입력해주세요." else {
            showAlert(title: "내용 입력", message: "리뷰 내용을 입력해주세요.")
            return
        }
        
        guard let uid = Auth.auth().currentUser?.uid else {
            showAlert(title: "오류", message: "로그인 정보가 없습니다.")
            return
        }
        
        // ⭐ 1) 유저 닉네임 가져오기
        db.collection("users").document(uid).getDocument { userSnap, error in
            let nickname = userSnap?.data()?["nickname"] as? String ?? "사용자"
            
            // ⭐ 2) reviewId 먼저 생성
            let reviewRef = self.db.collection("shops").document(shopId)
                .collection("reviews").document()
            
            let reviewId = reviewRef.documentID
            
            // ⭐ 3) 이미지 업로드 후 저장
            self.uploadImages(shopId: shopId, reviewId: reviewId) { imageURLs in
                
                let data: [String: Any] = [
                    "nickname": nickname,
                    "authorId": uid,
                    "content": text,
                    "rating": Double(self.selectedRating),
                    "timestamp": Timestamp(date: Date()),
                    "imageURLs": imageURLs
                ]
                
                reviewRef.setData(data) { error in
                    if let error = error {
                        self.showAlert(title: "오류", message: "리뷰 저장 실패: \(error.localizedDescription)")
                        return
                    }
                    
                    self.finishReviewWrite()
                }
            }
        }
    }
    
    private func finishReviewWrite() {
        // 예약 리뷰 상태 업데이트
        if let path = self.reservationPath {
            let reservationRef = self.db
                .collection("users").document(path.userId)
                .collection("reservations").document(path.reservationId)
            
            reservationRef.setData([
                "reviewWritten": true
            ], merge: true) { _ in
                NotificationCenter.default.post(name: .reviewWrittenForReservation, object: nil)
                NotificationCenter.default.post(name: .reviewAdded, object: nil)
                
                self.closeReviewScreen()
            }
        } else {
            NotificationCenter.default.post(name: .reviewAdded, object: nil)
            closeReviewScreen()
        }
    }
    
    private func closeReviewScreen() {
        // ⭐️ navigationController 안에 있을 경우 → pop
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            // ⭐️ modal로 띄웠을 경우 → dismiss
            dismiss(animated: true)
        }
    }
    
    // MARK: - Helpers
    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            ratingLabel,
            starStackView,
            textView,
            imagePickerButton,
            imagePreview,
            submitButton
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        
        imagePickerButton.setTitle("📷 사진 선택 (최대 5장)", for: .normal)
        imagePickerButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        imagePickerButton.addTarget(self, action: #selector(selectImages), for: .touchUpInside)
        
        imagePreview.showsHorizontalScrollIndicator = false
        imagePreview.snp.makeConstraints { $0.height.equalTo(90) }
        
        view.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        textView.snp.makeConstraints { $0.height.equalTo(150) }
    }
    
    private func updateStars() {
        for case let button as UIButton in starStackView.arrangedSubviews {
            button.setTitle(button.tag <= selectedRating ? "★" : "☆", for: .normal)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextViewDelegate
extension ReviewWriteVC: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = nil
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = "내용을 입력해주세요."
            textView.textColor = .lightGray
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let reviewAdded = Notification.Name("reviewAdded")
    static let reviewWrittenForReservation = Notification.Name("reviewWrittenForReservation")
}

// MARK: - PHPicker
extension ReviewWriteVC: PHPickerViewControllerDelegate {
    
    @objc private func selectImages() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 5
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func picker(_ picker:PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        
        selectedImages = []
        let group = DispatchGroup()
        
        for item in results {
            if item.itemProvider.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                item.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                    if let img = object as? UIImage {
                        self.selectedImages.append(img)
                    }
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            self.updateImagePreview()
        }
    }
    
    private func updateImagePreview() {
        imagePreview.subviews.forEach { $0.removeFromSuperview() }
        
        var xOffset: CGFloat = 0
        for img in selectedImages {
            let iv = UIImageView(image: img)
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.layer.cornerRadius = 8
            iv.frame = CGRect(x: xOffset, y: 0, width: 80, height: 80)
            
            imagePreview.addSubview(iv)
            xOffset += 90
        }
        imagePreview.contentSize = CGSize(width: xOffset, height: 80)
    }
    
    private func uploadImages(shopId: String, reviewId: String,
                              completion: @escaping ([String]) -> Void) {
        
        if selectedImages.isEmpty {
            completion([])
            return
        }
        
        var urls: [String] = []
        let group = DispatchGroup()
        
        for (index, img) in selectedImages.enumerated() {
            group.enter()
            
            let resized = img.resize(toWidth: 800)
            let path = "shops/\(shopId)/reviews/\(reviewId)/\(index).jpg"
            let ref = storage.reference().child(path)
            
            guard let data = resized.jpegData(compressionQuality: 0.8) else {
                group.leave()
                continue
            }
            
            ref.putData(data, metadata: nil) { _, error in
                if let error = error {
                    print("이미지 업로드 실패:", error.localizedDescription)
                    group.leave()
                    return
                }
                
                ref.downloadURL { url, _ in
                    if let urlStr = url?.absoluteString {
                        urls.append(urlStr)
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(urls)
        }
    }
}

// MARK: - UIImage Resize Helper
extension UIImage {
    func resize(toWidth width: CGFloat) -> UIImage {
        let scale = width / self.size.width
        let height = self.size.height * scale
        
        let newSize = CGSize(width: width, height: height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let newImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImg ?? self
    }
}
