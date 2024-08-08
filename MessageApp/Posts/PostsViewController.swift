//
//  PostsViewController.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/11/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import CoreData
import CoreLocation


class PostsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var greetLabel: UILabel!
    
    var posts: [Post] = []
    var userID: String?
    
    let locationManager = CLLocationManager()
    var currentCity: String?
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        updateGreeting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    
            if let currentUserID = Auth.auth().currentUser?.uid {
                self.userID = currentUserID
            } else {
                print("No user logged in")
            }
        
        fetchPosts()
    }
        func didDismissPostPreview() {
            fetchPosts()
        }
    
    func fetchPosts() {
        db.collection("posts").order(by: "timestamp", descending: true).addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching posts: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents found")
                return
            }
            
            self?.posts = documents.compactMap { doc -> Post? in
                try? doc.data(as: Post.self)
            }
            self?.tableView.reloadData()
        }
    }

    
    func fetchUserData() {
        guard userID == Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
        }

        let userRef = db.collection("users").document(userID ?? "")

        userRef.getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }

            guard let self = self else { return }
            
            if let document = document, document.exists, let data = document.data() {
                let name = data["name"] as? String ?? "User"
                let profileImageUrl = data["profileImageUrl"] as? String ?? ""
                
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostsTableViewCell
        let post = posts[indexPath.row]
        
        cell.authorTEXT.text = post.authorName
        cell.captionTEXT.text = post.caption
        cell.uploadtimeText.text = post.timestamp.formattedDateString()
        
        let isDarkMode = fetchUserPreference()
            
        cell.backgroundColor = isDarkMode ? .black : .tertiarySystemFill
        cell.captionTEXT.backgroundColor = isDarkMode ? .black : .white
        cell.captionTEXT.textColor = isDarkMode ? .white : .black
        
        let hasLiked = post.likes.contains(userID ?? "")
        cell.likeButton.setImage(UIImage(systemName: hasLiked ? "hand.thumbsup.fill" : "hand.thumbsup"), for: .normal)
        cell.likeButton.tag = indexPath.row
        cell.likeButton.addTarget(self, action: #selector(likeButtonPressed(_:)), for: .touchUpInside)
        
        if let url = URL(string: post.imageURL) {
            cell.postIMG.loadImage(from: url, placeholder: UIImage(named: "placeholder"))
        }
        if let pfpurl = URL(string: post.authorImgURL) {
            cell.authorIMG.loadImage(from: pfpurl, placeholder: UIImage(named: "placeholder"))
        }
        
        cell.likesText.text = "\(post.likes.count) likes"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 450
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToPreview", sender: self)
    }

    
    @objc func likeButtonPressed(_ sender: UIButton) {
        guard let userID = userID else {
            print("User ID is not set")
            return
        }
        
        let index = sender.tag
        let post = posts[index]
        let postRef = db.collection("posts").document(post.id ?? "")
        
        var updatedLikes = post.likes
        let hasLiked = updatedLikes.contains(userID)
        
        if hasLiked {
            updatedLikes.removeAll { $0 == userID }
        } else {
            updatedLikes.append(userID)
        }
        
        postRef.updateData(["likes": updatedLikes]) { [weak self] error in
            if let error = error {
                print("Error updating like: \(error)")
            } else {
                self?.posts[index].likes = updatedLikes
                self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            }
        }
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


    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToPreview",
           let destinationVC = segue.destination as? PostPreviewViewController,
           let indexPath = tableView.indexPathForSelectedRow {
            
            let selectedPost = posts[indexPath.row]
    
            destinationVC.postImgURL = selectedPost.imageURL
            destinationVC.authorImgURL = selectedPost.authorImgURL
            destinationVC.authorNAME = selectedPost.authorName
            destinationVC.timestampS = selectedPost.timestamp.formattedDateString()
            destinationVC.likescount = "\(selectedPost.likes.count) likes"
            destinationVC.captionTEXT = selectedPost.caption
            destinationVC.postID = selectedPost.id
            destinationVC.userID = selectedPost.authorID
        }
    }
    
    func updateGreeting() {
            let currentHour = Calendar.current.component(.hour, from: Date())
            let greeting: String

            switch currentHour {
            case 0..<12:
                greeting = "Good Morning"
            case 12..<17:
                greeting = "Good Afternoon"
            default:
                greeting = "Good Evening"
            }
            greetLabel.text = greeting
        }
    
}

extension UIImageView {
    func loadImage(from url: URL, placeholder: UIImage? = nil) {
        self.image = placeholder
        
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
    }
}

extension Timestamp {
    func formattedDateString() -> String {
        let date = self.dateValue()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            return dateFormatter.string(from: date)
        }
    }
}


