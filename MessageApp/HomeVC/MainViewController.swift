//
//  MainViewController.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/8/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var profilePicture: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var welcomeText: UILabel!
   
    @IBOutlet weak var searchBar: UITableView!
    
    var chats: [Chat] = []
    let db = Firestore.firestore()
    
    var filteredChats: [Chat] = []
    var isSearching = false
    var participantDetails: [String: (name: String, profileImageUrl: String)] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
        let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeDownGesture.direction = .down
        self.view.addGestureRecognizer(swipeDownGesture)
        
        fetchUserData()
        fetchChats()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        fetchChats()
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
                let name = data["name"] as? String ?? "User"
                let profileImageUrl = data["profileImageUrl"] as? String ?? ""

                self.welcomeText.text = "Welcome, \(name)!"
                
                if !profileImageUrl.isEmpty {
                    self.loadProfileImage(from: profileImageUrl)
                } else {
                    self.profilePicture.setImage(UIImage(named: "placeholderProfileImage"), for: .normal)
                }
            } else {
                print("Document does not exist")
            }
        }
    }

    func loadProfileImage(from url: String) {
        let storageRef = Storage.storage().reference(forURL: url)
        storageRef.getData(maxSize: 2 * 1024 * 1024) { [weak self] data, error in
            if let error = error {
                print("Error downloading profile image: \(error.localizedDescription)")
                return
            }

            guard let self = self, let imageData = data, let image = UIImage(data: imageData) else {
                return
            }

            DispatchQueue.main.async {
                let resizedImage = self.resizeImage(image: image, targetSize: self.profilePicture.frame.size)
            
                self.profilePicture.setImage(resizedImage, for: .normal)
                
                self.profilePicture.layer.cornerRadius = self.profilePicture.frame.height / 2
                self.profilePicture.clipsToBounds = true
            }
        }
    }
    
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let scaleRatio = min(widthRatio, heightRatio)

        let newSize = CGSize(width: size.width * scaleRatio, height: size.height * scaleRatio)
        let rect = CGRect(x: (targetSize.width - newSize.width) / 2,
                          y: (targetSize.height - newSize.height) / 2,
                          width: newSize.width,
                          height: newSize.height)
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { context in
            image.draw(in: rect)
        }

        return resizedImage
    }
    
    func fetchChats() {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                print("No user logged in")
                return
            }

            db.collection("chats")
                .whereField("participants", arrayContains: currentUserID)
                .getDocuments { [weak self] (snapshot, error) in
                    if let error = error {
                        print("Error fetching chats: \(error.localizedDescription)")
                        return
                    }

                    guard let self = self else { return }

                    var fetchedChats: [Chat] = []
                    var participantDetails: [String: (name: String, profileImageUrl: String)] = [:]

                    if let snapshot = snapshot {
                        let dispatchGroup = DispatchGroup()

                        for document in snapshot.documents {
                            let data = document.data()
                            let chatID = document.documentID
                            let participants = data["participants"] as? [String] ?? []
                            let lastMessage = data["lastMessage"] as? String ?? ""
                            let lastMessageTimestamp = (data["lastMessageTimestamp"] as? Timestamp)?.dateValue() ?? Date()

                            if let chat = Chat(document: data, documentID: chatID) {
                                fetchedChats.append(chat)

                                for participantID in participants {
                                    dispatchGroup.enter()
                                    self.fetchParticipantDetails(userID: participantID) { name, profileImageUrl in
                                        participantDetails[participantID] = (name: name, profileImageUrl: profileImageUrl)
                                        dispatchGroup.leave()
                                    }
                                }
                            }
                        }

                        dispatchGroup.notify(queue: .main) {
                            self.chats = fetchedChats
                            self.participantDetails = participantDetails
                            self.tableView.reloadData()
                        }
                    }
                }
        }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return isSearching ? filteredChats.count : chats.count
        }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatTableViewCell
        let chat = isSearching ? filteredChats[indexPath.row] : chats[indexPath.row]

        guard let currentUserID = Auth.auth().currentUser?.uid,
              let otherParticipantID = chat.participants.first(where: { $0 != currentUserID }) else {
            cell.chatName.text = "Unknown"
            cell.chatLastSeen.text = "N/A"
            cell.chatLastTStamp.text = ""
            cell.chatPFP.image = UIImage(named: "defaultPFP")
            return cell
        }

        let participantName = participantDetails[otherParticipantID] ?? (name: "Unknown", profileImageUrl: "")
        let profileImageURL = participantName.profileImageUrl
        
        cell.chatName.text = participantName.name
        cell.chatLastSeen.text = chat.lastMessage
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        let timestampString = dateFormatter.string(from: chat.lastMessageTimestamp)
        cell.chatLastTStamp.text = timestampString

        if !profileImageURL.isEmpty {
            loadImage(from: participantName.profileImageUrl) { image in
                DispatchQueue.main.async {
                    cell.chatPFP.image = image ?? UIImage(named: "defaultPFP")
                }
            }
        } else {
            cell.chatPFP.image = UIImage(named: "defaultPFP")
        }

        return cell
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            isSearching = !searchText.isEmpty
            filteredChats = chats.filter { chat in
                let participantName = participantDetails[chat.participants.first(where: { $0 != Auth.auth().currentUser?.uid }) ?? ""]?.name ?? ""
                return participantName.lowercased().contains(searchText.lowercased())
            }
            tableView.reloadData()
        }
        

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func fetchParticipantDetails(userID: String, completion: @escaping (String, String) -> Void) {
            db.collection("users").document(userID).getDocument { (document, error) in
                if let error = error {
                    print("Error fetching participant details: \(error.localizedDescription)")
                    completion("", "")
                    return
                }

                guard let document = document, document.exists, let data = document.data() else {
                    completion("", "")
                    return
                }

                let name = data["name"] as? String ?? "Unknown"
                let profileImageURL = data["profileImageUrl"] as? String ?? ""
                completion(name, profileImageURL)
            }
        }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedChat = isSearching ? filteredChats[indexPath.row] : chats[indexPath.row]
        performSegue(withIdentifier: "goToChat", sender: selectedChat)
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToChat", let destinationVC = segue.destination as? ChatViewController,
           let selectedChat = sender as? Chat {
            guard let currentUserID = Auth.auth().currentUser?.uid,
                  let otherParticipantID = selectedChat.participants.first(where: { $0 != currentUserID }) else {
                return
            }
            
            let participantName = participantDetails[otherParticipantID] ?? (name: "Unknown", profileImageUrl: "")
            
            fetchUserData(userID: otherParticipantID) { name, email, desc, profileImageUrl in
                let email = email ?? ""
                let desc = desc ?? ""
                
                destinationVC.otherParticipantEmail = email
                destinationVC.otherParticipantDesc = desc
            }
            
            destinationVC.chat = selectedChat
            destinationVC.otherParticipantID = otherParticipantID
            destinationVC.otherParticipantName = participantName.name
            destinationVC.otherParticipantProfileImageURL = participantName.profileImageUrl
        }
    }


    func loadImage(from url: String, completion: @escaping (UIImage?) -> Void) {
        let storageRef = Storage.storage().reference(forURL: url)
        storageRef.getData(maxSize: 2 * 1024 * 1024) { data, error in
            if let error = error {
                print("Error downloading image: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let imageData = data, let image = UIImage(data: imageData) else {
                completion(nil)
                return
            }
            
            let resizedImage = self.resizeImage(image: image, targetSize: CGSize(width: 40, height: 40))
            completion(resizedImage)
        }
    }
    
    func fetchUserData(userID: String, completion: @escaping (String?, String?, String?, String?) -> Void) {
        let userRef = Firestore.firestore().collection("users").document(userID)

        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                completion(nil, nil, nil, nil)
                return
            }

            guard let document = document, document.exists, let data = document.data() else {
                print("Document does not exist")
                completion(nil, nil, nil, nil)
                return
            }

            let name = data["name"] as? String
            let email = data["email"] as? String
            let desc = data["description"] as? String
            let profileImageUrl = data["profileImageUrl"] as? String
            completion(name, email, desc, profileImageUrl)
        }
    }

   
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
            let location = sender.location(in: self.view)
            
            if !tableView.frame.contains(location) {
                dismissKeyboard()
            }
        }
    
    @objc func handleSwipeDown(_ sender: UISwipeGestureRecognizer) {
            dismissKeyboard()
        }

        @objc func dismissKeyboard() {
            view.endEditing(true)
        }
}

