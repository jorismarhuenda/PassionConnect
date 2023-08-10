//
//  UserInterests.swift
//  PassionConnect
//
//  Created by marhuenda joris on 10/08/2023.
//

import SwiftUI

struct UserInterests: Identifiable {
    let id = UUID()
    let userId: String 
    var interests: [String]
}
