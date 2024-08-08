//
//  ProfileChatViewController.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/10/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import CoreData

class ProfileChatViewController: UIViewController {

    @IBOutlet weak var profilePicturePreview: UIImageView!
    @IBOutlet weak var nameText: UILabel!
    @IBOutlet weak var emailText: UILabel!
    @IBOutlet weak var descText: UITextView!
    
    var user: User?
    var userID: String?
        
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchUserData()
        
        styleUpdate()
        if let user = user {
            nameText.text = user.name
            emailText.text = user.email
            descText.text = user.description
        if let profileImageUrl = user.profileImageUrl {
                loadProfileImage(from: profileImageUrl)
            }
        }
    }
    
    @IBAction func cancel_pressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func fetchUserData() {
        guard let userID = userID else {
            return
        }

        let userRef = db.collection("users").document(userID)

        userRef.getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }

            guard let self = self else { return }
            
            if let document = document, document.exists, let data = document.data() {
                self.nameText.text = data["name"] as? String ?? "Unknown"
                self.loadProfileImage(from: data["profileImageUrl"] as? String ?? "")
                self.descText.text = data["description"] as? String ?? "No description"
                self.emailText.text = data["email"] as? String ?? "Unknown"
                
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func loadProfileImage(from url: String) {
        let storageRef = Storage.storage().reference(forURL: url)
        storageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                print("Error downloading profile image: \(error)")
                self.profilePicturePreview.image = UIImage(named: "defaultPFP")
                return
            }
            if let imageData = data, let image = UIImage(data: imageData) {
                self.profilePicturePreview.image = image
            } else {
                self.profilePicturePreview.image = UIImage(named: "defaultPFP")
            }
        }
    }

    func styleUpdate(){
        
        let isDarkMode = fetchUserPreference()
        
        profilePicturePreview.contentMode = .scaleAspectFill
        profilePicturePreview.layer.cornerRadius = self.profilePicturePreview.frame.height / 2
        profilePicturePreview.clipsToBounds = true
        
        descText.backgroundColor = isDarkMode ? .black : .tertiarySystemFill
        descText.backgroundColor = isDarkMode ? .black : .white
        descText.textColor = isDarkMode ? .white : .black
        
        descText.layer.borderColor = UIColor.lightGray.cgColor
        descText.layer.borderWidth = 1.0
        descText.layer.cornerRadius = 8.0
        descText.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    func fetchUserPreference() -> Bool {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<UserPreference> = UserPreference.fetchRequest()
        
        do {
            let results = try context.fetch(fetchRequest)
            if let userPreference = results.first {
                return userPreference.isDarkMode
            }
        } catch {
            print("Failed to fetch user preference: \(error)")
        }
        return false
    }
}
