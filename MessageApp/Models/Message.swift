//
//  Message.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/10/24.
//


import Foundation
import FirebaseFirestore

struct Messages {
    let senderID: String
    let recipientID: String
    let text: String
    let timestamp: Date
    let chatID: String
    let messageType: String
    let documentID: String

    init?(document: [String: Any], documentID: String) {
        guard let senderID = document["senderID"] as? String,
              let recipientID = document["recipientID"] as? String,
              let text = document["text"] as? String,
              let timestamp = (document["timestamp"] as? Timestamp)?.dateValue(),
              let chatID = document["chatID"] as? String else {
            return nil
        }

        self.senderID = senderID
        self.recipientID = recipientID
        self.text = text
        self.timestamp = timestamp
        self.chatID = chatID
        self.messageType = document["messageType"] as? String ?? "text"
        self.documentID = documentID
    }
}

