//
//  PetAddVC.swift
//  DangSalon
//
//  Created by 최영건 on 11/23/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

final class PetAddVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let petImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .systemGray6
        iv.layer.cornerRadius = 16
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    private let nameField = UITextField()
    private let breedField = UITextField()
    private let ageField = UITextField()
    private let weightField = UITextField()
    private let memoTextView = UITextView()
    
    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("등록하기", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        btn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        return btn
    }()
    
    private var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        title = "반려견 등록"
        
        setupUI()
        setupGesture()
        saveButton.addTarget(self, action: #selector(savePet), for: .touchUpInside)
    }
    
    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        petImageView.addGestureRecognizer(tap)
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints { $0.edges.width.equalToSuperview() }
        
        [petImageView, nameField, breedField, ageField,
         weightField, memoTextView, saveButton].forEach { contentView.addSubview($0) }
        
        petImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(150)
        }
        
        nameField.snp.makeConstraints {
            $0.top.equalTo(petImageView.snp.bottom).offset(20)
            $0.left.right.equalToSuperview().inset(20)
            $0.height.equalTo(50)
        }
        
        breedField.snp.makeConstraints {
            $0.top.equalTo(nameField.snp.bottom).offset(12)
            $0.left.right.equalTo(nameField)
            $0.height.equalTo(50)
        }
        
        ageField.snp.makeConstraints {
            $0.top.equalTo(breedField.snp.bottom).offset(12)
            $0.left.right.equalTo(nameField)
            $0.height.equalTo(50)
        }
        
        weightField.snp.makeConstraints {
            $0.top.equalTo(ageField.snp.bottom).offset(12)
            $0.left.right.equalTo(nameField)
            $0.height.equalTo(50)
        }
        
        memoTextView.snp.makeConstraints {
            $0.top.equalTo(weightField.snp.bottom).offset(12)
            $0.left.right.equalTo(nameField)
            $0.height.equalTo(120)
        }
        
        saveButton.snp.makeConstraints {
            $0.top.equalTo(memoTextView.snp.bottom).offset(20)
            $0.left.right.equalTo(nameField)
            $0.height.equalTo(55)
            $0.bottom.equalToSuperview().offset(-10)
        }
        
        setupFields()
    }
    
    private func setupFields() {
        [nameField, breedField, ageField, weightField].forEach {
            $0.borderStyle = .roundedRect
        }
        
        nameField.placeholder = "반려견 이름"
        breedField.placeholder = "견종"
        ageField.placeholder = "나이"
        weightField.placeholder = "몸무게 (kg)"
        
        memoTextView.layer.borderWidth = 1
        memoTextView.layer.borderColor = UIColor.systemGray4.cgColor
        memoTextView.layer.cornerRadius = 10
    }
    
    @objc private func selectImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage {
            selectedImage = image
            petImageView.image = image
        }
    }
    
    // MARK: - Save
    @objc private func savePet() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let name = nameField.text, !name.isEmpty else { return }
        
        var data: [String: Any] = [
            "name": name,
            "breed": breedField.text ?? "",
            "age": Int(ageField.text ?? "") ?? 0,
            "weight": Int(weightField.text ?? "") ?? 0,
            "memo": memoTextView.text ?? "",
            "createdAt": Timestamp()
        ]
        
        // 사진 없을 때 바로 저장
        if selectedImage == nil {
            saveToFirestore(uid: uid, data: data)
            return
        }
        
        // Storage 업로드
        uploadImage(uid: uid) { url in
            data["photoURL"] = url
            self.saveToFirestore(uid: uid, data: data)
        }
    }
    
    private func uploadImage(uid: String, completion: @escaping (String) -> Void) {
        guard let imageData = selectedImage?.jpegData(compressionQuality: 0.8) else { return }
        
        let ref = storage.reference()
            .child("pets/\(uid)/\(UUID().uuidString).jpg")
        
        ref.putData(imageData) { _, _ in
            ref.downloadURL { url, _ in
                completion(url?.absoluteString ?? "")
            }
        }
    }
    
    private func saveToFirestore(uid: String, data: [String: Any]) {
        db.collection("users").document(uid)
            .collection("pets")
            .addDocument(data: data) { err in
                if err == nil {
                    self.navigationController?.popViewController(animated: true)
                }
            }
    }
}
