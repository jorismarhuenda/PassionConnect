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
                
                Button(action: findRandomMatch, label: {
                    Image(systemName: "shuffle")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.blue)
                })
                .disabled(randomMatch != nil || currentMatchIndex >= potentialMatches.count)
            }
            .padding()
        }
        .onAppear {
            searchMatches()
        }
    }
    
    private func likeCurrentMatch() {
        guard currentMatchIndex < potentialMatches.count else {
            return
        }
        
        let currentMatch = potentialMatches[currentMatchIndex]
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
    
    private func searchMatches() {
        isSearching = true
        viewModel.searchMatches(preferredAge: Int(preferredAge), maximumDistance: Int(maximumDistance), interests: []) { matches in
            potentialMatches = matches
            isSearching = false
        }
    }
}
