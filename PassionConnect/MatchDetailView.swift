//
//  MatchDetailView.swift
//  PassionConnect
//
//  Created by marhuenda joris on 30/07/2023.
//

import SwiftUI

struct MatchDetailView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    var match: Match
    
    var body: some View {
        VStack {
            Text("Correspondance avec \(match.userName)")
                .font(.title)
                .padding()
            
            Text("Âge : \(match.age)")
                .padding()
            
            Text("Intérêts communs : \(match.commonInterests.joined(separator: ", "))")
                .padding()
            
            // Ajouter d'autres détails de correspondance si nécessaire
            
            Button(action: unmatchUser, label: {
                Text("Supprimer la correspondance")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            })
            .padding()
            
            Spacer()
        }
    }
    
    private func unmatchUser() {
        var arrayOfPotentialMatches: [Match] = []
        viewModel.unmatchUser(match, potentialMatches: &arrayOfPotentialMatches)
    }
}
