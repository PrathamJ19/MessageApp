//
//  ProfileEditViewController.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/10/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class ProfileEditViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UITextViewDelegate {

    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var nameTextF: UITextField!
    @IBOutlet weak var descTextF: UITextView!
    
    private var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserData()
        styleUpdate()
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
        
        nameTextF.delegate = self
        descTextF.delegate = self
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func update_pressed(_ sender: Any) {
        guard let userID = currentUserID else { return }
        
        let name = nameTextF.text ?? ""
        let description = descTextF.text ?? ""
        
        var data: [String: Any] = [
            "name": name,
            "description": description
        ]
        
        if profileImg.image != nil {
            uploadImageToFirebase { imageUrl in
                if let imageUrl = imageUrl {
                    data["profileImageUrl"] = imageUrl
                }
                
                self.saveUserData(userID: userID, data: data)
            }
        } else {
            saveUserData(userID: userID, data: data)
        }
    }
    
    @IBAction func EditImg_pressed(_ sender: Any) {
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
    
    func loadUserData() {
        guard let userID = currentUserID else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                self.nameTextF.text = data?["name"] as? String
                self.descTextF.text = data?["description"] as? String
                
                if let imageUrl = data?["profileImageUrl"] as? String, !imageUrl.isEmpty {
                    self.loadProfileImage(from: imageUrl)
                }
            } else {
                self.showAlert(for: .error(message: "Failed to load user data."))
            }
        }
    }
    
    func styleUpdate(){
        descTextF.layer.borderColor = UIColor.lightGray.cgColor
        descTextF.layer.borderWidth = 1.0
        descTextF.layer.cornerRadius = 5.0
        descTextF.textContainerInset = UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 5)
        
        profileImg.layer.cornerRadius = profileImg.frame.size.width / 2
        profileImg.clipsToBounds = true
    }
    
    func loadProfileImage(from url: String) {
        let storageRef = Storage.storage().reference(forURL: url)
        storageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                self.showAlert(for: .error(message: "Failed to load profile image: \(error.localizedDescription)"))
            } else if let data = data, let image = UIImage(data: data) {
                self.profileImg.image = image
            }
        }
    }
    
    func uploadImageToFirebase(completion: @escaping (String?) -> Void) {
        guard let image = profileImg.image else {
            completion(nil)
            return
        }
        
        let resizedImage = resizeImage(image: image, targetSize: CGSize(width: 400, height: 400))
        guard let imageData = resizedImage.jpegData(compressionQuality: 1) else {
            completion(nil)
            return
        }
        
        let storageRef = Storage.storage().reference().child("profile_images/\(UUID().uuidString).jpg")
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                self.showAlert(for: .error(message: "Failed to upload image: \(error.localizedDescription)"))
                completion(nil)
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    self.showAlert(for: .error(message: "Failed to get download URL: \(error.localizedDescription)"))
                    completion(nil)
                    return
                }
                
                completion(url?.absoluteString)
            }
        }
    }
    
    func saveUserData(userID: String, data: [String: Any]) {
        let db = Firestore.firestore()
        db.collection("users").document(userID).updateData(data) { error in
            if let error = error {
                self.showAlert(for: .error(message: "Error updating user data: \(error.localizedDescription)"))
            } else {
                self.showAlert(for: .updateSuccess)
            }
        }
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize = CGSize(width: 400, height: 400)) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let scaleFactor = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        let rect = CGRect(x: (targetSize.width - newSize.width) / 2,
                          y: (targetSize.height - newSize.height) / 2,
                          width: newSize.width,
                          height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    func showAlert(for type: AlertType) {
        var alert: UIAlertController
        
        switch type {
        case .updateSuccess:
            alert = UIAlertController(title: "Profile Updated", message: "Your profile has been updated successfully.", preferredStyle: .alert)
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
            profileImg.image = selectedImage
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
