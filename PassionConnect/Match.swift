//
//  Match.swift
//  PassionConnect
//
//  Created by marhuenda joris on 10/08/2023.
//

import Foundation

struct Match: Identifiable, CustomStringConvertible {
    let id: Int
    let name: String
    let bio: String
    let interests: [String]
    let profileImageName: String
    let email: String
    let profileImageURL: URL?
    
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
            Match(id: 1, name: "John Doe", bio: "Nature lover", interests: ["Hiking", "Photography"], profileImageName: "john", email: "john@example.com", profileImageURL: URL(string: "https://example.com/john.jpg")),
            Match(id: 2, name: "Jane Smith", bio: "Foodie and traveler", interests: ["Cooking", "Travel"], profileImageName: "jane", email: "jane@example.com", profileImageURL: URL(string: "https://example.com/jane.jpg"))
        ]
    }
}
