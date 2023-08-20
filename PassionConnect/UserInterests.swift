//
//  UserInterests.swift
//  PassionConnect
//
//  Created by marhuenda joris on 10/08/2023.
//

import SwiftUI

struct UserInterests: Identifiable, Encodable { // Conform to Encodable
    let id: UUID
    var userId: String
    var interests: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case interests
    }
    
    init(id: UUID, userId: String, interests: [String]) {
        self.id = id
        self.userId = userId
        self.interests = interests
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(interests, forKey: .interests)
    }
}
