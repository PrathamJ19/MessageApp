//
//  Chat.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/9/24.
//

import Foundation
import FirebaseCore

struct Chat {
    let id: String
    let participants: [String]
    let lastMessage: String
    let lastMessageTimestamp: Date

    init?(document: [String: Any], documentID: String) {
        guard let participants = document["participants"] as? [String],
              let lastMessage = document["lastMessage"] as? String,
              let lastMessageTimestamp = (document["lastMessageTimestamp"] as? Timestamp)?.dateValue()
               else {
            return nil
        }
        
        self.id = documentID
        self.participants = participants
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
    }
}
