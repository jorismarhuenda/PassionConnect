//
//  DiscoverView.swift
//  PassionConnect
//
//  Created by marhuenda joris on 30/07/2023.
//

import SwiftUI

struct DiscoverView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    @State private var currentMatchIndex: Int = 0
    @State private var randomMatch: Match? = nil
    @State private var isSearching: Bool = false
    @State private var potentialMatches: [Match] = []
    @State private var preferredAge: Double = 25
    @State private var maximumDistance: Double = 50
    
    var body: some View {
        VStack {
            if let match = randomMatch {
                CardView(match: match)
            } else if potentialMatches.isEmpty {
                Text("Aucune correspondance potentielle trouvée")
                    .font(.headline)
                    .padding()
            } else {
                CardView(match: potentialMatches[currentMatchIndex])
            }
            
            VStack {
                Text("Âge préféré : \(Int(preferredAge))")
                Slider(value: $preferredAge, in: 18...100, step: 1)
            }
            .padding()
            
            VStack {
                Text("Distance maximale (en km) : \(Int(maximumDistance))")
                Slider(value: $maximumDistance, in: 1...500, step: 1)
            }
            .padding()
            
            HStack(spacing: 40) {
                Button(action: dislikeCurrentMatch, label: {
                    Image(systemName: "x.circle")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.red)
                })
                .disabled(randomMatch != nil || currentMatchIndex >= potentialMatches.count)
                
                Button(action: likeCurrentMatch, label: {
                    Image(systemName: "heart.circle")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.green)
                })
                .disabled(randomMatch != nil || currentMatchIndex >= potentialMatches.count)
                
                Button(action: unmatchCurrentMatch, label: { // Utilisez cette nouvelle fonction
                    Image(systemName: "person.crop.circle.badge.xmark")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.orange)
                })
                .disabled(randomMatch != nil || currentMatchIndex >= potentialMatches.count)
                
                Button(action: {
                    var arrayOfPotentialMatches: [Match] = []
                    findRandomMatch(completion: { match in
                        if let match = match {
                            // Handle the case where a random match is found
                            print("Found a random match: \(match)")
                        } else {
                            // Handle the case where no more potential matches are available
                            print("No more potential matches.")
                        }
                    }, potentialMatches: &arrayOfPotentialMatches)
                }, label: {
                    Image(systemName: "shuffle")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.blue)
                })
                .disabled(randomMatch != nil || currentMatchIndex >= potentialMatches.count)
            }
            .padding()
        }
        .onReceive(viewModel.$removedLikedUserID) { removedUserID in
            if let userID = removedUserID {
                viewModel.updatePotentialMatchesAfterUnmatch(potentialMatches: &potentialMatches, currentUserID: userID)
            }
        }
        .onAppear {
            searchMatches()
        }
    }
    
    private func unmatchCurrentMatch() {
            guard currentMatchIndex < potentialMatches.count else {
                return
            }
            
            let currentMatch = potentialMatches[currentMatchIndex]
            viewModel.unmatchUser(currentMatch, potentialMatches: &potentialMatches)
        if let currentUserID = viewModel.currentUser?.id {
            viewModel.updatePotentialMatchesAfterUnmatch(potentialMatches: &potentialMatches, currentUserID: currentUserID)
        }
    }
    
    private func likeCurrentMatch() {
        guard currentMatchIndex < potentialMatches.count else {
            return
        }
        
        let currentMatch = potentialMatches[currentMatchIndex]
        viewModel.likeMatch(currentMatch) { error, updatedMatches in
            if let error = error {
                print("Erreur lors du like du match : \(error.localizedDescription)")
            } else {
                self.currentMatchIndex += 1
                // Appeler la fonction suivante pour "liker" le prochain match
                self.likeCurrentMatch()
            }
        }
    }
    
    private func findRandomMatch(completion: @escaping (Match?) -> Void, potentialMatches: inout [Match]) {
        var arrayOfPotentialMatches: [Match] = []
        viewModel.findRandomMatch(completion: { match in
                self.randomMatch = match
            }, potentialMatches: &arrayOfPotentialMatches)
    }
    
    private func dislikeCurrentMatch() {
        currentMatchIndex += 1
    }
    
    private func searchMatches() {
        isSearching = true
        viewModel.searchMatches(preferredAge: Int(preferredAge), maximumDistance: Int(maximumDistance), interests: []) { matches in
            potentialMatches = matches
            isSearching = false
        }
    }
}
