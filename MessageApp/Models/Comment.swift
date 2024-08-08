//
//  Comment.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/14/24.
//


import Foundation
import FirebaseFirestore

struct Comment: Codable {
    @DocumentID var id: String?
    var userID: String
    var text: String
    var timestamp: Timestamp

    var authorName: String?
    var authorImgURL: String?
    
    enum CodingKeys: String, CodingKey {
        case userID = "userID"
        case text
        case timestamp
        case authorName
        case authorImgURL
    }
}
