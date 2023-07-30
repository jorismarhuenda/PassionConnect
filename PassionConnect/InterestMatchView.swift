//
//  InterestMatchView.swift
//  PassionConnect
//
//  Created by marhuenda joris on 29/07/2023.
//

import SwiftUI

struct InterestMatchView: View {
    @State private var recommendedMatches: [UserInterests] = []
    @State private var isChatPresented: Bool = false
    
    var body: some View {
        VStack {
            Text("Correspondances recommandées")
                .font(.title)
                .padding(.bottom, 20)
            
            if recommendedMatches.isEmpty {
                Text("Aucune correspondance recommandée pour le moment.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(recommendedMatches, id: \.userId) { user in
                    VStack(alignment: .leading) {
                        Text("Utilisateur \(user.userId)")
                            .font(.headline)
                        Text("Intérêts : \(user.interests.joined(separator: ", "))")
                            .font(.subheadline)
                    }
                    .onTapGesture {
                        isChatPresented = true
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .sheet(isPresented: $isChatPresented, content: {
            // Ici, vous pouvez présenter la vue de chat avec l'utilisateur sélectionné.
            // Vous pouvez utiliser une autre classe ou vue SwiftUI pour la gestion des conversations et des messages.
            // Lorsque l'utilisateur ferme la vue de chat, définissez "isChatPresented" à "false".
            Text("Chat View Placeholder")
                .padding()
        })
        .padding()
        .onAppear {
            // Chargez les correspondances recommandées pour l'utilisateur actuel à partir de votre modèle de données ou de votre API.
            // Ici, nous utilisons une liste statique à des fins de démonstration.
            recommendedMatches = loadRecommendedMatches()
        }
    }
    
    private func loadRecommendedMatches() -> [UserInterests] {
        // Vous pouvez implémenter ici la logique pour charger les correspondances recommandées de votre modèle de données ou de votre API.
        // Pour cet exemple, nous utilisons une liste statique.
        
        let user1 = UserInterests(userId: 2, interests: ["Travel", "Hiking", "Reading"])
        let user2 = UserInterests(userId: 3, interests: ["Photography", "Cooking", "Painting"])
        
        return [user1, user2]
    }
}

