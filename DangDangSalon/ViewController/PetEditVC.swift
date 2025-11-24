//
//  PetEditVC.swift
//  DangSalon
//
//  Created by 최영건 on 11/24/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class PetEditVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let pet: Pet
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let petImageView = UIImageView()
    private let nameField = UITextField()
    private let breedField = UITextField()
    private let ageField = UITextField()
    private let weightField = UITextField()
    private let memoTextView = UITextView()
    
    private let saveButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    
    private var selectedImage: UIImage?
    
    init(pet: Pet) {
        self.pet = pet
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "반려견 정보 수정"
        view.backgroundColor = .systemBackground
        
        setupUI()
        loadPetInfo()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        petImageView.addGestureRecognizer(tap)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }
        
        // 이미지뷰
        petImageView.backgroundColor = .systemGray6
        petImageView.layer.cornerRadius = 16
        petImageView.clipsToBounds = true
        petImageView.isUserInteractionEnabled = true
        contentView.addSubview(petImageView)
        
        // TextField 기본 스타일
        [nameField, breedField, ageField, weightField].forEach {
            $0.borderStyle = .roundedRect
            $0.backgroundColor = .systemGray6
            $0.font = .systemFont(ofSize: 16)
        }
        
        // TextView 스타일
        memoTextView.layer.borderColor = UIColor.systemGray4.cgColor
        memoTextView.layer.borderWidth = 1
        memoTextView.layer.cornerRadius = 8
        memoTextView.font = .systemFont(ofSize: 16)
        
        [nameField, breedField, ageField, weightField, memoTextView, saveButton, deleteButton].forEach {
            contentView.addSubview($0)
        }
        
        // MARK: - Constraints
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
        }
        
        deleteButton.snp.makeConstraints {
            $0.top.equalTo(saveButton.snp.bottom).offset(12)
            $0.left.right.equalTo(nameField)
            $0.height.equalTo(55)
            $0.bottom.equalToSuperview().offset(-40) // contentView 높이를 결정
        }
        
        // 버튼 스타일
        saveButton.setTitle("저장하기", for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.layer.cornerRadius = 12
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.addTarget(self, action: #selector(updatePet), for: .touchUpInside)
        
        deleteButton.setTitle("삭제하기", for: .normal)
        deleteButton.backgroundColor = .systemRed
        deleteButton.layer.cornerRadius = 12
        deleteButton.setTitleColor(.white, for: .normal)
        deleteButton.addTarget(self, action: #selector(deletePet), for: .touchUpInside)
        
        // 키보드 올라올 때 스크롤뷰 조정
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    private func loadPetInfo() {
        nameField.text = pet.name
        breedField.text = pet.breed
        ageField.text = pet.age
        weightField.text = pet.weight
        memoTextView.text = pet.memo
        
        if let url = URL(string: pet.photoURL ?? "") {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data {
                    DispatchQueue.main.async {
                        self.petImageView.image = UIImage(data: data)
                    }
                }
            }.resume()
        }
    }
    
    // MARK: - Select image
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
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        scrollView.contentInset.bottom = keyboardFrame.height + 20
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
    }
    
    // MARK: - Update
    @objc private func updatePet() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        var data: [String: Any] = [
            "name": nameField.text ?? "",
            "breed": breedField.text ?? "",
            "age": ageField.text ?? "",
            "weight": weightField.text ?? "",
            "memo": memoTextView.text ?? ""
        ]
        
        let ref = db.collection("users").document(uid)
            .collection("pets").document(pet.id)
        
        if selectedImage == nil {
            ref.updateData(data)
            navigationController?.popViewController(animated: true)
            return
        }
        
        // Storage 업로드 후 저장
        uploadImage(uid: uid) { url in
            data["photoURL"] = url
            ref.updateData(data)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func uploadImage(uid: String, completion: @escaping (String) -> Void) {
        guard let imgData = selectedImage?.jpegData(compressionQuality: 0.8) else { return }
        
        let ref = storage.reference().child("pets/\(uid)/\(UUID().uuidString).jpg")
        
        ref.putData(imgData) { _, _ in
            ref.downloadURL { url, _ in
                completion(url?.absoluteString ?? "")
            }
        }
    }
    
    // MARK: - Delete
    @objc private func deletePet() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let ref = db.collection("users").document(uid)
            .collection("pets").document(pet.id)
        
        ref.delete { _ in
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
