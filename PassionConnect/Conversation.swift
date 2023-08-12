//
//  Conversation.swift
//  PassionConnect
//
//  Created by marhuenda joris on 12/08/2023.
//

import SwiftUI

struct Conversation: Identifiable {
    var id = UUID()
    var displayName: String // Nom à afficher pour la conversation
    var user: User // Utilisateur avec lequel la conversation a lieu
    var messages: [ChatMessage]
    var isTyping: Bool // Indique si l'utilisateur est en train de taper un message
    var quickReplies: [String] // Les réponses rapides pour cette conversation
    var isUnread: Bool // Indique si la conversation est marquée comme "non lue"
    var lastMessageText: String // Le texte du dernier message dans la conversation
    let userID: String
    let otherUserID: String
    let otherUserName: String
    
    init(displayName: String, user: User, messages: [ChatMessage], isTyping: Bool, quickReplies: [String], isUnread: Bool, otherUserName: String) {
        self.displayName = displayName
        self.user = user
        self.messages = messages
        self.isTyping = isTyping
        self.quickReplies = quickReplies
        self.isUnread = isUnread
        self.otherUserName = otherUserName
        
        // Get the last message text from messages
        self.lastMessageText = messages.last?.text ?? "Aucun message"
    }
}
