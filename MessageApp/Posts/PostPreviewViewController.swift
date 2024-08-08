//
//  PostPreviewViewController.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/11/24.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import CoreData

class PostPreviewViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var postIMG: UIImageView!
    @IBOutlet weak var authorImg: UIImageView!
    @IBOutlet weak var authorNAme: UILabel!
    @IBOutlet weak var timeStamp: UILabel!
    @IBOutlet weak var likesCount: UILabel!
    @IBOutlet weak var captionText: UITextView!
    @IBOutlet weak var commentText: UITextField!
    
    @IBOutlet weak var tableView: UITableView!
    
    var postImgURL: String?
    var authorImgURL: String?
    var authorNAME: String?
    var timestampS: String?
    var likescount: String?
    var captionTEXT: String?
    var userName: String?
    var userImg: String?
    var userID: String?
    
    var comments: [Comment] = []
    var selectedComment: Comment?
    var postID: String?

    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
        
        authorImg.layer.cornerRadius = authorImg.frame.size.width / 2
        
        // Assuming you have an IBOutlet to your UIImageView
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        authorImg.isUserInteractionEnabled = true
        authorImg.addGestureRecognizer(tapGestureRecognizer)
        
        DataFetch()
        fetchUserData()
        fetchComments()
        styleCaptions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToPreview" {
            if let destinationVC = segue.destination as? ProfileChatViewController {
                if let selectedComment = selectedComment {
                    destinationVC.userID = selectedComment.userID
                    }
                else {
                    destinationVC.userID = self.userID
                    }
            }
        }
    }
    
    @objc func imageTapped(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "goToPreview", sender: self)
    }


    
    // Handle row selection in the table view
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            selectedComment = comments[indexPath.row]
            performSegue(withIdentifier: "goToPreview", sender: self)
        }
    
    @IBAction func Comment_pressed(_ sender: Any) {
        guard let commentText = commentText.text, !commentText.isEmpty, let postID = postID else {
                    return
                }
                
                let newComment: [String: Any] = [
                    "userID": Auth.auth().currentUser?.uid ?? "",
                    "text": commentText,
                    "timestamp": Timestamp(),
                    "authorName": userName ?? "Unknown",
                    "authorImgURL": userImg ?? "defaultPFP"
                ]
                
            db.collection("posts").document(postID).collection("comments").addDocument(data: newComment) { [weak self] error in
                    if let error = error {
                        print("Error adding comment: \(error)")
                    } else {
                        self?.fetchComments()
                        self?.commentText.text = ""
                    }
                }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
           return comments.count
       }
       
       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
           let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentTableViewCell
           let comment = comments[indexPath.row]
           
           cell.authorName.text = "\(comment.authorName ?? "Unknown") : "
           cell.commentLabel.text = comment.text
           
           if let url = URL(string: comment.authorImgURL ?? "") {
               cell.authorImg.loadImage(from: url, placeholder: UIImage(named: "defaultPFP"))
           }
           
           return cell
       }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let commentToDelete = comments[indexPath.row]
            
            let alert = UIAlertController(title: "Delete comment", message: "Are you sure you want to delete this comment?", preferredStyle: .alert)
            
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
                print("Post ID: \(self.postID ?? "nil")")
                print("Comment ID: \(commentToDelete.id ?? "nil")")

                self.db.collection("posts").document(self.postID ?? "")
                    .collection("comments")
                    .document(commentToDelete.id ?? "")
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
        let comments = comments[indexPath.row]
        let currentUserID = Auth.auth().currentUser?.uid
        if comments.userID == currentUserID {
            return .delete
        } else {
            return .none
        }
    }
    
    func DataFetch(){
        authorNAme.text = authorNAME
        timeStamp.text = timestampS
        likesCount.text = likescount
        captionText.text = captionTEXT
        
        if let postIamgeURL = postImgURL {
            if let url = URL(string: postIamgeURL) {
                postIMG.loadImage(from: url, placeholder: UIImage(named: "placeholder"))
            }
        }
        
        if let authorImageURL = authorImgURL {
            if let url = URL(string: authorImageURL) {
                authorImg.loadImage(from: url, placeholder: UIImage(named: "placeholder"))
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
                self.userName = data["name"] as? String ?? "Unknown"
                self.userImg = data["profileImageUrl"] as? String ?? ""
                
            } else {
                print("Document does not exist")
            }
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

    
    func fetchComments() {
        guard let postID = postID else {
            print("Post ID is not set")
            return
        }

        db.collection("posts").document(postID).collection("comments")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching comments: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("No comments found")
                    return
                }

                self?.comments = documents.compactMap { doc -> Comment? in
                    let data = doc.data()
                    var comment = try? doc.data(as: Comment.self)
                    comment?.id = doc.documentID
                    return comment
                }

                self?.tableView.reloadData()
            }
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
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

}
