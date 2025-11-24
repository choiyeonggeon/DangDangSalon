//
//  PetListVC.swift
//  DangSalon
//
//  Created by 최영건 on 11/23/25.
//

import UIKit
import SnapKit
import FirebaseAuth
import FirebaseFirestore
import SDWebImage

final class PetListVC: UIViewController {
    
    private var pets: [Pet] = []
    private let db = Firestore.firestore()
    
    var onPetSelected: ((Pet) -> Void)?   // 예약 화면 등에서 선택 시 전달할 때 사용
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.register(PetCell.self, forCellReuseIdentifier: "PetCell")
        tv.separatorStyle = .none
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "반려견 목록"
        view.backgroundColor = .systemBackground
        
        setupUI()
        setupNav()
        loadPets()
    }
    
    private func setupNav() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(openAdd)
        )
    }
    
    @objc private func openAdd() {
        let vc = PetAddVC()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    private func loadPets() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid)
            .collection("pets")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                self.pets.removeAll()
                
                snapshot?.documents.forEach { doc in
                    let pet = Pet(id: doc.documentID, data: doc.data())
                    self.pets.append(pet)
                }
                
                self.tableView.reloadData()
            }
    }
}

extension PetListVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        pets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PetCell", for: indexPath) as? PetCell else {
            return UITableViewCell()
        }
        cell.configure(pet: pets[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let pet = pets[indexPath.row]
        
        // 선택 콜백이 있으면 예약 등에서 사용하는 경우
        onPetSelected?(pet)
        
        // PetEditVC로 이동
        let editVC = PetEditVC(pet: pet)
        navigationController?.pushViewController(editVC, animated: true)
    }
    
    // 스와이프 삭제
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let petId = pets[indexPath.row].id
            
            db.collection("users").document(uid)
                .collection("pets").document(petId)
                .delete()
        }
    }
}

final class PetCell: UITableViewCell {
    
    private let photoView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 30
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .systemGray5
        return iv
    }()
    
    private let nameLabel = UILabel()
    private let breedLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        
        contentView.addSubview(photoView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(breedLabel)
        
        photoView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(15)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(40)
        }
        photoView.layer.cornerRadius = 20 // width/height 절반

        nameLabel.snp.makeConstraints {
            $0.left.equalTo(photoView.snp.right).offset(15)
            $0.top.equalToSuperview().offset(15)
        }
        
        breedLabel.snp.makeConstraints {
            $0.left.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(2)
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(pet: Pet) {
        nameLabel.text = pet.name
        breedLabel.text = pet.breed
        
        if let url = pet.photoURL {
            photoView.sd_setImage(with: URL(string: url))
        }
    }
}
