//
//  UserProfileView.swift
//  PassionConnect
//
//  Created by marhuenda joris on 30/07/2023.
//

import SwiftUI

struct UserProfileView: View {
    @ObservedObject var viewModel: FirestoreViewModel
        @State private var name: String
        @State private var age: Int
        @State private var interests: [String]
        @State private var description: String
        
        init(viewModel: FirestoreViewModel) {
            self.viewModel = viewModel
            // Initialize the State variables here
            _name = State(initialValue: viewModel.currentUser.name)
            _age = State(initialValue: viewModel.currentUser.age)
            _interests = State(initialValue: viewModel.currentUser.interests)
            _description = State(initialValue: viewModel.currentUser.description)
        }
        
        var body: some View {
        Form {
            Section(header: Text("Informations personnelles")) {
                TextField("Nom", text: $name)
                Stepper(value: $age, in: 18...100, label: {
                    Text("Âge : \(age)")
                })
            }
            
            Section(header: Text("Intérêts")) {
                TextField("Intérêt 1", text: $interests[0])
                TextField("Intérêt 2", text: $interests[1])
                TextField("Intérêt 3", text: $interests[2])
            }
            
            Section(header: Text("Description")) {
                TextEditor(text: $description)
                    .frame(height: 100)
            }
            
            Section {
                Button(action: updateProfile, label: {
                    Text("Enregistrer les modifications")
                })
            }
        }
        .navigationBarTitle("Mon Profil")
        .onAppear {
            // Remplir les champs avec les informations actuelles de l'utilisateur
            name = viewModel.currentUser.name
            age = viewModel.currentUser.age
            interests = viewModel.currentUser.interests
            description = viewModel.currentUser.description
        }
    }
    
    private func updateProfile() {
        guard let currentUserID = viewModel.currentUser.id else {
            return
        }
        
        let updatedUser = User(id: currentUserID, name: name, age: age, interests: interests, description: description)
        
        viewModel.updateUserProfile(updatedUser) { error in
            if let error = error {
                print("Erreur lors de la mise à jour du profil : \(error.localizedDescription)")
            }
        }
    }
}
