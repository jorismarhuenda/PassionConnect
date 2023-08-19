//
//  UserInterests.swift
//  PassionConnect
//
//  Created by marhuenda joris on 10/08/2023.
//

import SwiftUI

struct UserInterests: Identifiable, Decodable {
    let id: UUID
    let userId: String
    var interests: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case interests
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        interests = try container.decode([String].self, forKey: .interests)
    }
}
