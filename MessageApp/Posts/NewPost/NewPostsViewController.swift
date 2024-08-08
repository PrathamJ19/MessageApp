//
//  NewPostsViewController.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/11/24.
//

import UIKit
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import CoreData

class NewPostsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var postIMG: UIImageView!
    @IBOutlet weak var captionText: UITextView!
    let db = Firestore.firestore()
    
    var name : String?
    var userID : String?
    var userImg : String?
    var message : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        styleCaptions()
        addTapGestureToDismissKeyboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    
    @IBAction func imgAdd_pressed(_ sender: Any) {
        let alert = UIAlertController(title: "Select Image", message: "Choose an image source", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.presentImagePicker(sourceType: .camera)
        }))
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
            self.presentImagePicker(sourceType: .photoLibrary)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @IBAction func post_pressed(_ sender: Any) {
        guard let image = postIMG.image, let caption = captionText.text, !caption.isEmpty else {
                showAlert(for: .error(message: "Please select an image and enter a caption."))
                return
            }
            fetchUserData {
                self.uploadImage(image) { [weak self] url in
                    guard let self = self, let url = url else {
                        self?.showAlert(for: .error(message: "Failed to upload image."))
                        return
                    }
                    
                    self.savePost(imageURL: url.absoluteString, caption: caption)
                 
                    dismiss(animated: true, completion: nil)
                }
            }
        
    }
    
    @IBAction func cancel_pressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func fetchUserData(completion: @escaping () -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
        }

        let userRef = db.collection("users").document(userID)

        userRef.getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                completion()
                return
            }

            if let document = document, document.exists, let data = document.data() {
                self?.userID = userID
                self?.name = data["name"] as? String ?? "Unknown"
                self?.userImg = data["profileImageUrl"] as? String ?? ""
            } else {
                print("Document does not exist")
            }
            
            completion()
        }
    }

    func styleCaptions(){
        
        let isDarkMode = fetchUserPreference()
        
        captionText.backgroundColor = isDarkMode ? .black : .tertiarySystemFill
        captionText.backgroundColor = isDarkMode ? .black : .white
        captionText.textColor = isDarkMode ? .white : .black
        
        captionText.layer.borderColor = UIColor.lightGray.cgColor
        captionText.layer.borderWidth = 1.0
        captionText.layer.cornerRadius = 8.0
        captionText.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
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
    
    func uploadImage(_ image: UIImage, completion: @escaping (URL?) -> Void) {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                completion(nil)
                return
            }

            let storageRef = Storage.storage().reference().child("post_images/\(UUID().uuidString).jpg")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            storageRef.putData(imageData, metadata: metadata) { _, error in
                if let error = error {
                    print("Failed to upload image: \(error)")
                    completion(nil)
                } else {
                    storageRef.downloadURL { url, _ in
                        completion(url)
                    }
                }
            }
        }
    
    func savePost(imageURL: String, caption: String) {
        
            let db = Firestore.firestore()
            let postData: [String: Any] = [
                "imageURL": imageURL,
                "caption": caption,
                "authorID": userID ?? "",
                "authorName": name ?? "Unknown",
                "authorImgURL": userImg ?? "",
                "timestamp": Timestamp(),
                "likes": []
            ]
            
            db.collection("posts").addDocument(data: postData) { [weak self] error in
                if let error = error {
                    print("Error saving post: \(error)")
                    self?.showAlert(for: .error(message: "Failed to save post."))
                } else {
                    self?.showAlert(for: .updateSuccess)
                    self?.clearForm()
                self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    
    func clearForm() {
            postIMG.image = nil
            captionText.text = ""
        }
    
    func showAlert(for type: AlertType) {
        var alert: UIAlertController
        
        switch type {
        case .updateSuccess:
            alert = UIAlertController(title: "Post Uploaded", message: "Your image has been posted successfully.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
    
        case .error(let message):
            alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
        }
        
        present(alert, animated: true)
    }
    
    enum AlertType {
        case updateSuccess
        case error(message: String)
    }
    
    func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = sourceType
            present(imagePicker, animated: true)
        } else {
            showAlert(for: .error(message: "Source type not available"))
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            postIMG.image = selectedImage
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func addTapGestureToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
}
