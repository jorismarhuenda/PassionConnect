//
//  DiscoverView.swift
//  PassionConnect
//
//  Created by marhuenda joris on 30/07/2023.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct DiscoverView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    @State private var currentMatchIndex: Int = 0
    @State private var randomMatch: Match? = nil
    
    var body: some View {
            VStack {
                if let match = randomMatch {
                    CardView(match: match)
                } else if viewModel.potentialMatches.isEmpty {
                    Text("Aucune correspondance potentielle trouvée")
                        .font(.headline)
                        .padding()
                } else {
                    CardView(match: viewModel.potentialMatches[currentMatchIndex])
                }
                
                HStack(spacing: 40) {
                    Button(action: dislikeCurrentMatch, label: {
                        Image(systemName: "x.circle")
                            .resizable()
                            .frame(width: 44, height: 44)
                            .foregroundColor(.red)
                    })
                    .disabled(randomMatch != nil || currentMatchIndex >= viewModel.potentialMatches.count)
                    
                    Button(action: likeCurrentMatch, label: {
                        Image(systemName: "heart.circle")
                                                .resizable()
                                                .frame(width: 44, height: 44)
                                                .foregroundColor(.green)
                                        })
                                        .disabled(randomMatch != nil || currentMatchIndex >= viewModel.potentialMatches.count)
                                        
                                        Button(action: findRandomMatch, label: {
                                            Image(systemName: "shuffle")
                                                .resizable()
                                                .frame(width: 44, height: 44)
                                                .foregroundColor(.blue)
                                        })
                                        .disabled(randomMatch != nil || currentMatchIndex >= viewModel.potentialMatches.count)
                                    }
                                    .padding()
                                }
                                .onAppear {
                                    viewModel.loadPotentialMatches()
                                }
                            }
    
    private func likeCurrentMatch() {
        guard currentMatchIndex < viewModel.potentialMatches.count else {
            return
        }
        
        let currentMatch = viewModel.potentialMatches[currentMatchIndex]
        viewModel.likeMatch(currentMatch) { error in
            if let error = error {
                print("Erreur lors du like du match : \(error.localizedDescription)")
            } else {
                currentMatchIndex += 1
            }
        }
    }
    
    private func findRandomMatch() {
            viewModel.findRandomMatch { match in
                self.randomMatch = match
            }
        }
    
    private func dislikeCurrentMatch() {
        currentMatchIndex += 1
    }
}
