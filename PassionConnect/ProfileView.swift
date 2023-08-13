//
//  ProfileView.swift
//  PassionConnect
//
//  Created by marhuenda joris on 30/07/2023.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct ProfileView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    @State private var isEditing: Bool = false
    @State private var name: String = ""
    @State private var bio: String = ""
    
    var body: some View {
        VStack {
            if isEditing {
                VStack {
                    TextField("Nom", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    TextField("Biographie", text: $bio)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                .padding()
                .onAppear {
                    name = viewModel.currentUser?.name ?? ""
                    bio = viewModel.currentUser?.bio ?? ""
                }
            } else {
                VStack {
                    Text("Nom : \(viewModel.currentUser?.name ?? "")")
                    Text("Biographie : \(viewModel.currentUser?.bio ?? "")")
                }
                .padding()
            }
            
            Spacer()
            
            if isEditing {
                Button("Enregistrer") {
                    saveChanges()
                    isEditing = false
                }
            } else {
                Button("Modifier le profil") {
                    isEditing = true
                }
            }
        }
        .navigationBarTitle("Profil")
        .onAppear {
            name = viewModel.currentUser?.name ?? ""
            bio = viewModel.currentUser?.bio ?? ""
        }
    }
    
    private func saveChanges() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("Erreur : impossible d'enregistrer les modifications, l'ID de l'utilisateur actuel est manquant.")
            return
        }
        
        viewModel.updateUser(id: currentUserID, name: name, bio: bio) { error in
            if let error = error {
                print("Erreur lors de la mise à jour du profil : \(error.localizedDescription)")
            }
        }
    }
}
