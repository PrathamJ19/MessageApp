//
//  ChatViewController.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/10/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var participantImg: UIImageView!
    @IBOutlet weak var participantText: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textInput: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    let db = Firestore.firestore()
    
    var chat: Chat?
    var otherParticipantID: String?
    var otherParticipantEmail: String?
    var otherParticipantDesc: String?
    var otherParticipantName: String?
    var otherParticipantProfileImageURL: String?
    var messages: [Messages] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        textInput.delegate = self
        
        participantImg.layer.cornerRadius = participantImg.frame.size.width / 2
        participantImg.clipsToBounds = true
        
        setupParticipantDetails()
        fetchMessages()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
            let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            swipeDown.direction = .down
            view.addGestureRecognizer(swipeDown)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        setCustomBackButton()
        setupRightBarButton()
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        let keyboardHeight = keyboardFrame.cgRectValue.height
        self.view.frame.origin.y = -keyboardHeight
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        self.view.frame.origin.y = 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showUserPreview" {
            if let destinationVC = segue.destination as? ProfileChatViewController {
                if let name = otherParticipantName,
                   let profileImageUrl = otherParticipantProfileImageURL,
                   let otherParticipantID = otherParticipantID,
                   let Email = otherParticipantEmail,
                   let Desc = otherParticipantDesc
                {
                    let user = User(id: otherParticipantID,
                                    name: name,
                                    email: Email,
                                    description: Desc,
                                    profileImageUrl: profileImageUrl)
                    destinationVC.user = user
                }
            }
        }
    }
    
    @IBAction func sendBtn_pressed(_ sender: Any) {
        guard let messageText = textInput.text, !messageText.isEmpty else {
            print("Message is empty")
            return
        }
        guard let currentUserID = Auth.auth().currentUser?.uid, let chatID = chat?.id else {
            print("No user logged in or chat ID is missing")
            return
        }

        let messageData: [String: Any] = [
            "senderID": currentUserID,
            "recipientID": otherParticipantID ?? "",
            "text": messageText,
            "timestamp": Timestamp(),
            "chatID": chatID,
            "messageType": "text"
        ]

        db.collection("chats").document(chatID).collection("messages").addDocument(data: messageData) { [weak self] error in
            if let error = error {
                print("Error sending message: \(error.localizedDescription)")
                return
            }

            let chatUpdateData: [String: Any] = [
                "lastMessage": messageText,
                "lastMessageTimestamp": Timestamp()
            ]

            self?.db.collection("chats").document(chatID).updateData(chatUpdateData) { error in
                if let error = error {
                    print("Error updating chat: \(error.localizedDescription)")
                }
            }
            self?.textInput.text = ""
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageTableViewCell
        let message = messages[indexPath.row]
        let currentUserID = Auth.auth().currentUser?.uid

        cell.messageLabel.text = message.text
        cell.isIncoming = message.senderID != currentUserID

        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
                let messageToDelete = messages[indexPath.row]

                let alert = UIAlertController(title: "Delete Message", message: "Are you sure you want to delete this message?", preferredStyle: .alert)
                
                let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
                    let chatUpdateData: [String: Any] = [
                        "lastMessage": "~Message deleted~",
                        "lastMessageTimestamp": Timestamp()
                    ]
                    
                    self.db.collection("chats").document(messageToDelete.chatID).updateData(chatUpdateData) { error in
                        if let error = error {
                            print("Error updating chat: \(error.localizedDescription)")
                        }
                    }
                    
                    self.db.collection("chats").document(messageToDelete.chatID)
                        .collection("messages")
                        .document(messageToDelete.documentID)
                        .delete { error in
                            if let error = error {
                                print("Error deleting document: \(error.localizedDescription)")
                            }
                        }
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                
                alert.addAction(deleteAction)
                alert.addAction(cancelAction)
                
                self.present(alert, animated: true, completion: nil)
            }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let message = messages[indexPath.row]
        let currentUserID = Auth.auth().currentUser?.uid

        if message.senderID == currentUserID {
            return .delete
        } else {
            return .none
        }
    }
    
    func fetchMessages() {
        guard let chatID = chat?.id else { return }

        db.collection("chats").document(chatID).collection("messages")
            .order(by: "timestamp").addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching messages: \(error.localizedDescription)")
                    return
                }

                var fetchedMessages: [Messages] = []
                    snapshot?.documents.forEach { document in
                        if let message = Messages(document: document.data(), documentID: document.documentID) {
                            fetchedMessages.append(message)
                    }
                }
              
                self?.messages = fetchedMessages
                self?.tableView.reloadData()
                
                if let messageCount = self?.messages.count, messageCount > 0 {
                    let indexPath = IndexPath(row: messageCount - 1, section: 0)
                    self?.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                }
            }
    }
    
    func setupParticipantDetails() {
        participantText.text = otherParticipantName ?? "Unknown"
        
        if let imageURL = otherParticipantProfileImageURL, !imageURL.isEmpty {
            loadImage(from: imageURL) { [weak self] image in
                self?.participantImg.image = image ?? UIImage(named: "defaultPFP")
            }
        } else {
            participantImg.image = UIImage(named: "defaultPFP")
        }
    }
    
    private func loadImage(from url: String, completion: @escaping (UIImage?) -> Void) {
        guard let imageURL = URL(string: url) else {
            completion(nil)
            return
        }
        
        DispatchQueue.global().async {
            do {
                let data = try Data(contentsOf: imageURL)
                let image = UIImage(data: data)
                DispatchQueue.main.async {
                    completion(image)
                }
            } catch {
                print("Error loading image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    func setCustomBackButton() {
        let backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.addTarget(self, action: #selector(customBackButtonTapped), for: .touchUpInside)
        
        backButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        
        let customBackButtonItem = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = customBackButtonItem
    }

    @objc private func customBackButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func profileButtonTapped() {
        performSegue(withIdentifier: "showUserPreview", sender: nil)
    }

    func setupRightBarButton() {
        let profileButton = UIButton(type: .custom)
        profileButton.setImage(UIImage(systemName: "person.circle"), for: .normal)
        profileButton.addTarget(self, action: #selector(profileButtonTapped), for: .touchUpInside)
        
        let profileBarButtonItem = UIBarButtonItem(customView: profileButton)
        navigationItem.rightBarButtonItem = profileBarButtonItem
    }
}
