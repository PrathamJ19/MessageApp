//
//  SignupViewController.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/8/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class SignupViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var cpasswordText: UITextField!
    var isGoingBack = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonPressed))
        self.navigationItem.leftBarButtonItem = newBackButton
        
        setCustomBackButton()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        swipeDownGesture.direction = .down
        self.view.addGestureRecognizer(swipeDownGesture)
    }
    
    @IBAction func imageEdit_pressed(_ sender: Any) {
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
    
    @IBAction func signup_pressed(_ sender: Any) {
        guard let email = emailText.text, !email.isEmpty else {
            showAlert(for: .error(message: "Please enter a valid email!"))
            return
        }
        
        guard let name = nameText.text, !name.isEmpty else {
            showAlert(for: .error(message: "Please enter a valid name!"))
            return
        }
        
        guard let password = passwordText.text, !password.isEmpty, password.count >= 6 else {
            showAlert(for: .error(message: "Please enter a valid password! Passwords cannot be less than 6 characters."))
            return
        }
        
        guard let confirmPassword = cpasswordText.text, !confirmPassword.isEmpty else {
            showAlert(for: .error(message: "Please confirm your password!"))
            return
        }
        
        if password == confirmPassword {
            Auth.auth().createUser(withEmail: email, password: password) { firebaseResult, error in
                if let error = error {
                    self.handleFirebaseAuthError(error)
                    return
                }
                
                guard let userID = firebaseResult?.user.uid else {
                    self.showAlert(for: .error(message: "Something went wrong. Try again."))
                    return
                }
                
                self.uploadImageToFirebase { imageUrl in
                    self.saveUserData(userID: userID, name: name, email: email, description: "", imageUrl: imageUrl)
                }
            }
        } else {
            showAlert(for: .error(message: "Passwords do not match!"))
        }
    }
    
    func handleFirebaseAuthError(_ error: Error) {
        if let nsError = error as NSError? {
            let errorCode = AuthErrorCode(rawValue: nsError.code)
            let errorMessage: String
            switch errorCode {
            case .emailAlreadyInUse:
                errorMessage = nsError.localizedDescription
            default:
                errorMessage = "Something went wrong. Try again."
            }
            showAlert(for: .error(message: errorMessage))
        } else {
            showAlert(for: .error(message: "Something went wrong. Try again."))
        }
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
            profileImage.image = selectedImage
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func uploadImageToFirebase(completion: @escaping (String?) -> Void) {
        guard let image = profileImage.image else {
            completion(nil)
            return
        }
        
        // Resize the image to 400x400 pixels
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

    func resizeImage(image: UIImage, targetSize: CGSize = CGSize(width: 400, height: 400)) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Determine the scale factor to use
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Compute the new size
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        
        // Center the image in the target size
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

    func saveUserData(userID: String, name: String, email: String, description: String, imageUrl: String?) {
        var data: [String: Any] = [
            "email": email,
            "name": name,
            "description" : description
        ]
        
        if let imageUrl = imageUrl {
            data["profileImageUrl"] = imageUrl
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userID).setData(data) { error in
            if let error = error {
                self.showAlert(for: .error(message: "Error saving user data: \(error.localizedDescription)"))
            } else {
                self.navigateToMainVC()
                self.showAlert(for: .signupSuccess)
            }
        }
    }
    
    func showAlert(for type: AlertType) {
        var alert: UIAlertController
        
        switch type {
        case .discardChanges:
            alert = UIAlertController(title: "Are you sure you want to leave Sign Up?", message: "", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Discard Changes", style: .destructive, handler: { _ in
                self.isGoingBack = true
                self.navigationController?.popViewController(animated: true)
            }))
            
            alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel))
            
        case .signupSuccess:
            alert = UIAlertController(title: "Sign Up Successful", message: "Your account has been created.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
        case .error(let message):
            alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
        }
        
        present(alert, animated: true)
    }
    
    @objc func backButtonPressed() {
        if nameText.text?.isEmpty == false || emailText.text?.isEmpty == false || passwordText.text?.isEmpty == false || cpasswordText.text?.isEmpty == false {
            showAlert(for: .discardChanges)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func navigateToMainVC() {
           if let window = UIApplication.shared.connectedScenes
                                   .compactMap({ $0 as? UIWindowScene })
                                   .first?.windows
                                   .first(where: \.isKeyWindow) {
               let storyboard = UIStoryboard(name: "Main", bundle: nil)
               
               if let HomeVC = storyboard.instantiateViewController(withIdentifier: "HomeNavController") as? UINavigationController {
                   window.rootViewController = HomeVC
                   window.makeKeyAndVisible()
               }
           }
       }
    
    @objc private func customBackButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    func setCustomBackButton() {
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal) // Use SF Symbols for chevron
        backButton.addTarget(self, action: #selector(customBackButtonTapped), for: .touchUpInside)
        
        backButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        
        let customBackButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = customBackButtonItem
    }
    
    enum AlertType {
        case discardChanges
        case signupSuccess
        case error(message: String)
    }
}
