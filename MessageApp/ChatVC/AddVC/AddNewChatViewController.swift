//
//  AddNewChatViewController.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/9/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class AddNewChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var allUsers = [User]()
    var excUsers = [User]()
    var filteredUsers = [User]()
    var currentUserID: String?
   
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
        currentUserID = Auth.auth().currentUser?.uid
        fetchExistingChats()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showUserPreview" {
            if let destinationVC = segue.destination as? UserPreviewViewController,
               let user = sender as? User {
                destinationVC.user = user
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
        let user = filteredUsers[indexPath.row]
        cell.textLabel?.text = user.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser = filteredUsers[indexPath.row]
        performSegue(withIdentifier: "showUserPreview", sender: selectedUser)
    }
    
    func fetchAllUsers(excluding excludedUserIDs: [String]) {
        guard let currentUserID = currentUserID else { return }
        
        db.collection("users").getDocuments { [weak self] (snapshot, error) in
            if let error = error {
                print("Error fetching users: \(error.localizedDescription)")
                return
            }
            
            if let snapshot = snapshot {
                let allUsers = snapshot.documents.compactMap { document in
                    let data = document.data()
                    return User(
                        id: document.documentID,
                        name: data["name"] as? String ?? "No Name",
                        email: data["email"] as? String ?? "No Email",
                        description: data["description"] as? String ?? "No Description",
                        profileImageUrl: data["profileImageUrl"] as? String
                    )
                }
                
                self?.excUsers = allUsers.filter { user in
                    return !excludedUserIDs.contains(user.id) && user.id != currentUserID
                }
                
                self?.filteredUsers = self?.excUsers ?? []
                
                self?.tableView.reloadData()
            }
        }
    }

    func fetchExistingChats() {
        guard let currentUserID = currentUserID else { return }
        
        db.collection("chats")
            .whereField("participants", arrayContains: currentUserID)
            .getDocuments { [weak self] (snapshot, error) in
                if let error = error {
                    print("Error fetching chats: \(error.localizedDescription)")
                    return
                }
                
                var existingChatUserIDs: [String] = []
                
                if let snapshot = snapshot {
                    for document in snapshot.documents {
                        if let participants = document.data()["participants"] as? [String] {
                            existingChatUserIDs.append(contentsOf: participants.filter { $0 != currentUserID })
                        }
                    }
                }
                self?.fetchAllUsers(excluding: existingChatUserIDs)
            }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredUsers = excUsers
        } else {
            filteredUsers = excUsers.filter { user in
                return user.name.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
