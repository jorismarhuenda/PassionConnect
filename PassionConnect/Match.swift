//
//  Match.swift
//  PassionConnect
//
//  Created by marhuenda joris on 10/08/2023.
//

import Foundation
import FirebaseFirestoreSwift

struct Match: Identifiable, CustomStringConvertible {
    let id: UUID
    let name: String
    let bio: String
    let interests: [String]
    let profileImageName: String
    let email: String
    let profileImageURL: URL?
    var userName: String
    var age: Int
    var commonInterests: [String]
    
    var description: String {
        return """
        Match:
            ID: \(id)
            Name: \(name)
            Bio: \(bio)
            Interests: \(interests)
            Profile Image Name: \(profileImageName)
            Email: \(email)
            Profile Image URL: \(profileImageURL?.absoluteString ?? "N/A")
        """
    }
}

extension Match {
    static func testData() -> [Match] {
        return [
            Match(id: UUID(), name: "John Doe", bio: "Nature lover", interests: ["Hiking", "Photography"], profileImageName: "john", email: "john@example.com", profileImageURL: URL(string: "https://example.com/john.jpg"), userName: "JohnD", age: 30, commonInterests: ["Hiking"]),
            Match(id: UUID(), name: "Jane Smith", bio: "Foodie and traveler", interests: ["Cooking", "Travel"], profileImageName: "jane", email: "jane@example.com", profileImageURL: URL(string: "https://example.com/jane.jpg"), userName: "JaneS", age: 28, commonInterests: ["Cooking"])
        ]
    }
}

