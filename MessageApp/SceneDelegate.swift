//
//  SceneDelegate.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/8/24.
//

import UIKit
import FirebaseAuth
import CoreData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }

                window = UIWindow(windowScene: windowScene)
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                applySavedTheme()

                if Auth.auth().currentUser != nil {
                    let HomeVCController = storyboard.instantiateViewController(withIdentifier: "HomeNavController") as! UINavigationController
                    window?.rootViewController = HomeVCController
                } else {
                    // User is not logged in, load the LoginViewController
                    let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                    window?.rootViewController = UINavigationController(rootViewController: loginVC)
                }

                window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
    
    func applySavedTheme() {
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest: NSFetchRequest<UserPreference> = UserPreference.fetchRequest()
            
            do {
                let results = try context.fetch(fetchRequest)
                let isDarkMode = results.first?.isDarkMode ?? false

                if #available(iOS 13.0, *) {
                    let windows = UIApplication.shared.connectedScenes
                        .compactMap { $0 as? UIWindowScene }
                        .flatMap { $0.windows }
                    windows.forEach { window in
                        window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
                    }
                }
            } catch {
                print("Failed to load dark mode preference: \(error)")
            }
        }

}

