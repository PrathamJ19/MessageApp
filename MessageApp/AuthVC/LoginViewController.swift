//
//  LoginViewController.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/8/24.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addTapGestureToDismissKeyboard()
    }
    
    @IBAction func login_pressed(_ sender: Any) {
        guard let email = emailText.text, !email.isEmpty else {
            showAlert(for: .error(message: "Please enter a valid email!"))
            return
        }
        
        guard let password = passwordText.text, !password.isEmpty else {
            showAlert(for: .error(message: "Please enter a valid password!"))
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { firebaseResult, error in
            if let e = error {
                print(e)
                self.emailText.text = ""
                self.passwordText.text = ""
                self.showAlert(for: .error(message: "Invalid email or Password"))
            } else {
                self.emailText.text = ""
                self.passwordText.text = ""
                self.navigateToMainVC()
                self.showAlert(for: .loginSuccess)
            }
        }
    }
    
    func navigateToMainVC() {
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: \.isKeyWindow) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            if let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeNavController") as? UINavigationController {
                window.rootViewController = homeVC
                window.makeKeyAndVisible()
            }
        }
    }
    
    func showAlert(for type: AlertType) {
        var alert: UIAlertController
        
        switch type {
        case .loginSuccess:
            alert = UIAlertController(title: "Login Successful", message: "Your account has been logged in.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
        case .error(let message):
            alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
        }
        
        present(alert, animated: true)
    }

    func addTapGestureToDismissKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    enum AlertType {
        case loginSuccess
        case error(message: String)
    }
}
