//
//  UserInterestsView.swift
//  PassionConnect
//
//  Created by marhuenda joris on 29/07/2023.
//

import SwiftUI

struct UserInterestsView: View {
    @State private var interests: [String]
    @Binding var isEditing: Bool
    
    init(interests: [String], isEditing: Binding<Bool>) {
        self._interests = State(initialValue: interests)
        self._isEditing = isEditing
    }
    
    var body: some View {
        VStack {
            Text("Intérêts")
                .font(.title)
                .padding(.bottom, 20)
            
            if isEditing {
                EditInterestsListView(interests: $interests)
            } else {
                ShowInterestsListView(interests: interests)
            }
            
            if isEditing {
                Button("Terminer l'édition", action: {
                    isEditing = false
                    // Ici, vous pouvez sauvegarder les intérêts mis à jour dans votre modèle de données ou dans une base de données.
                })
                .padding()
            } else {
                Button("Modifier", action: {
                    isEditing = true
                })
                .padding()
            }
        }
        .padding()
    }
}

struct ShowInterestsListView: View {
    let interests: [String]
    
    var body: some View {
        List(interests, id: \.self) { interest in
            Text(interest)
        }
    }
}

struct EditInterestsListView: View {
    @Binding var interests: [String]
    @State private var newInterest: String = ""
    
    var body: some View {
        VStack {
            List {
                ForEach(interests, id: \.self) { interest in
                    Text(interest)
                }
                .onDelete(perform: deleteInterest)
            }
            .listStyle(PlainListStyle())
            
            HStack {
                TextField("Ajouter un intérêt", text: $newInterest)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Ajouter", action: addInterest)
            }
            .padding(.top, 10)
        }
    }
    
    private func addInterest() {
        if !newInterest.isEmpty {
            interests.append(newInterest)
            newInterest = ""
        }
    }
    
    private func deleteInterest(at offsets: IndexSet) {
        interests.remove(atOffsets: offsets)
    }
}
