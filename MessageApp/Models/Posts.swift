//
//  Posts.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/11/24.
//

import Foundation
import FirebaseFirestore

struct Post: Codable {
    @DocumentID var id: String?
    var imageURL: String
    var caption: String
    var authorID: String
    var authorName: String
    var authorImgURL: String
    var timestamp: Timestamp
    var likes: [String]
}
