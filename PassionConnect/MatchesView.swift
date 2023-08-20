//
//  MatchesView.swift
//  PassionConnect
//
//  Created by marhuenda joris on 30/07/2023.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct MatchesView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    @State private var isShowingChatView: Bool = false
    @State private var selectedConversation: Conversation? = nil
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.matches) { match in
                    Button(action: {
                        showChatView(for: match)
                    }, label: {
                        MatchRow(match: match)
                    })
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Correspondances")
            .sheet(isPresented: $isShowingChatView, onDismiss: {
                selectedConversation = nil
            }) {
                if let conversation = selectedConversation {
                    ChatDetailView(viewModel: viewModel, conversation: conversation)
                }
            }
        }
        .onAppear {
            viewModel.loadMatches()
        }
    }
    
    private func showChatView(for match: Match) {
        var arrayOfPotentialMatches: [Match] = []
        if let conversation = viewModel.conversations.first(where: { $0.userIDs.contains(match.id) }) {
            selectedConversation = conversation
            isShowingChatView = true
        } else {
            viewModel.createConversation(with: match, completion: { result in
                switch result {
                case .success(let conversation):
                    selectedConversation = conversation
                    isShowingChatView = true
                case .failure(let error):
                    print("Erreur lors de la création de la conversation : \(error.localizedDescription)")
                }
            },
        potentialMatches: &arrayOfPotentialMatches)
        }
    }
}

struct MatchRow: View {
    var match: Match
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.gray)
            VStack(alignment: .leading) {
                Text(match.name)
                    .font(.headline)
                Text(match.bio)
                    .font(.subheadline)
            }
            Spacer()
        }
        .padding()
    }
}
