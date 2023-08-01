//
//  ConversationsView.swift
//  PassionConnect
//
//  Created by marhuenda joris on 30/07/2023.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct ConversationsView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    @State private var isShowingChatView: Bool = false
    @State private var selectedConversation: Conversation? = nil
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.conversations) { conversation in
                    Button(action: {
                        showChatView(for: conversation)
                    }, label: {
                        ConversationRow(conversation: conversation)
                    })
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Conversations")
            .sheet(item: $selectedConversation, onDismiss: {
                selectedConversation = nil
            }) { conversation in
                ChatDetailView(viewModel: viewModel, conversation: conversation)
            }
        }
        .onAppear {
            viewModel.loadAllConversations()
        }
    }
    
    private func showChatView(for conversation: Conversation) {
        selectedConversation = conversation
        isShowingChatView = true
    }
}

struct ConversationRow: View {
    var conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(conversation.displayName)
                .font(.headline)
            Text(conversation.lastMessageText)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
    }
}
