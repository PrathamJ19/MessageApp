//
//  UserPreviewViewController.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/9/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import CoreData

class UserPreviewViewController: UIViewController {

    @IBOutlet weak var profilePicturePreview: UIImageView!
    @IBOutlet weak var nameText: UILabel!
    @IBOutlet weak var emailText: UILabel!
    @IBOutlet weak var descText: UITextView!
    
    var user: User? 
        
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    
    @IBAction func AddNewChat_pressed(_ sender: Any) {
        guard let currentUserID = Auth.auth().currentUser?.uid, let user = user else {
                print("Error: Current user or selected user is nil.")
                return
            }
            
            let chatID = UUID().uuidString
            
            let chatData: [String: Any] = [
                "participants": [currentUserID, user.id],
                "lastMessage": "",
                "lastMessageTimestamp": Timestamp()
            ]
            
            db.collection("chats").document(chatID).setData(chatData) { error in
                if let error = error {
                    print("Error creating chat: \(error.localizedDescription)")
                    return
                }
              
                self.db.collection("chats").document(chatID).collection("messages").addDocument(data: [:]) { error in
                    if let error = error {
                        print("Error initializing messages subcollection: \(error.localizedDescription)")
                    } else {
                        self.dismiss(animated: true, completion: nil)
                    }
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
    
    
    func loadProfileImage(from url: String) {
            let storageRef = Storage.storage().reference(forURL: url)
            storageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                if let error = error {
                    print("Error downloading profile image: \(error)")
                    return
                }
                if let imageData = data, let image = UIImage(data: imageData) {
                    self.profilePicturePreview.image = image
                }
            }
        }
}
