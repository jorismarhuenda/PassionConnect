//
//  CHatListView.swift
//  PassionConnect
//
//  Created by marhuenda joris on 30/07/2023.
//

import SwiftUI

struct ChatListView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    
    var body: some View {
        NavigationView {
            List(viewModel.conversations) { conversation in
                NavigationLink(destination: ChatView(conversation: conversation, viewModel: viewModel)) {
                    Text(conversation.otherUserName.wrappedValue)
                }
            }
            .navigationBarTitle("Mes Conversations")
        }
        .onAppear {
            viewModel.loadAllConversations()
        }
    }
}
