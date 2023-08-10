//
//  User.swift
//  PassionConnect
//
//  Created by marhuenda joris on 09/08/2023.
//

import SwiftUI

struct User: Identifiable, Codable {
    var id = UUID()
    var name: String
    var bio: String
    var email: String
    var profileImageName: String
    var fcmToken: String? // Stocke le token FCM de l'utilisateur pour les notifications push
    var age: Int
    var interests: [String]
    var description: String
}

