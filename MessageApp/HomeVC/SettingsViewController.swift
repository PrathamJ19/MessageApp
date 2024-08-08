//
//  SettingsViewController.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/8/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import CoreData

class SettingsViewController: UIViewController {

    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var darkModeSW: UISwitch!
    
    let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        darkModeSW.isOn = loadUserPreference()
        applyUserPreferredTheme()
        fetchUserData()
        profileImg.layer.cornerRadius = profileImg.frame.size.width / 2
        profileImg.clipsToBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    @IBAction func logout_pressed(_ sender: Any) {
        logoutButtonTapped()
    }
    
    @IBAction func darkModeSW_switched(_ sender: UISwitch) {
        let isDarkMode = sender.isOn
        saveDarkModePreference(isDarkMode: isDarkMode)
        applyUserPreferredTheme()
    }
    
    func logoutButtonTapped() {
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to log out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
            self.performLogout()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func performLogout() {
        do {
            try Auth.auth().signOut()
            navigateToLogin()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError.localizedDescription)
        }
    }
    
    func navigateToLogin() {
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: \.isKeyWindow) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let loginNavVC = storyboard.instantiateViewController(withIdentifier: "LoginNavViewController") as? UINavigationController {
                window.rootViewController = loginNavVC
                window.makeKeyAndVisible()
            }
        }
    }
    
    func fetchUserData() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user logged in")
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
                let profileImageUrl = data["profileImageUrl"] as? String ?? ""
                
                if !profileImageUrl.isEmpty {
                    self.loadProfileImage(from: profileImageUrl)
                } else {
                    self.profileImg.image = UIImage(named: "defaultPFP")
                }
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func loadProfileImage(from url: String) {
        guard let imageURL = URL(string: url) else {
            self.profileImg.image = UIImage(named: "defaultPFP")
            return
        }

        let task = URLSession.shared.dataTask(with: imageURL) { [weak self] data, response, error in
            if let error = error {
                print("Error loading image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.profileImg.image = UIImage(named: "defaultPFP")
                }
                return
            }

            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self?.profileImg.image = UIImage(named: "defaultPFP")
                }
                return
            }

            DispatchQueue.main.async {
                self?.profileImg.image = image
            }
        }

        task.resume()
    }
    
    func saveDarkModePreference(isDarkMode: Bool) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<UserPreference> = UserPreference.fetchRequest()
        
        do {
            let results = try context.fetch(fetchRequest)
            let preference: UserPreference

            if let existingPreference = results.first {
                preference = existingPreference
            } else {
                preference = UserPreference(context: context)
            }

            preference.isDarkMode = isDarkMode
            try context.save()
        } catch {
            print("Failed to save dark mode preference: \(error)")
        }
    }

    func loadUserPreference() -> Bool {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<UserPreference> = UserPreference.fetchRequest()
        
        do {
            let results = try context.fetch(fetchRequest)
            if let preference = results.first {
                return preference.isDarkMode
            }
            return false
        } catch {
            print("Failed to load dark mode preference: \(error)")
            return false
        }
    }
    
    func applyUserPreferredTheme() {
        if #available(iOS 13.0, *) {
            let isDarkMode = loadUserPreference()
            let windows = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
            windows.forEach { window in
                window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
            }
        }
    }
}
