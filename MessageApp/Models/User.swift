//
//  User.swift
//  MessageApp
//
//  Created by Pratham Jadhav on 8/9/24.
//


import Foundation

struct User: Decodable {
    let id: String
    let name: String
    let email: String
    let description: String
    let profileImageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case description
        case profileImageUrl
    }
}

