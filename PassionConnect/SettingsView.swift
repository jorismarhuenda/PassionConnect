//
//  SettingsView.swift
//  PassionConnect
//
//  Created by marhuenda joris on 30/07/2023.
//

import SwiftUI
import Firebase

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: FirestoreViewModel
    @State private var isShowingLogoutAlert: Bool = false
    @State private var isShowingDeleteAccountAlert: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Spacer()
                Button("Fermer") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding()
            
            Text("Paramètres")
                .font(.largeTitle)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Nom : \(viewModel.currentUser.name)")
                Text("Biographie : \(viewModel.currentUser.bio)")
                Text("Email : \(viewModel.currentUser.email)")
            }
            
            Button("Modifier le profil") {
                // Open ProfileView for editing profile
                presentationMode.wrappedValue.dismiss()
                viewModel.isProfileViewPresented = true
            }
            .foregroundColor(.blue)
            
            Button("Déconnexion") {
                isShowingLogoutAlert = true
            }
            .foregroundColor(.red)
            .alert(isPresented: $isShowingLogoutAlert) {
                Alert(
                    title: Text("Déconnexion"),
                    message: Text("Êtes-vous sûr de vouloir vous déconnecter ?"),
                    primaryButton: .default(Text("Annuler")),
                    secondaryButton: .destructive(Text("Déconnexion"), action: logout)
                )
            }
            
            Button("Supprimer le compte") {
                isShowingDeleteAccountAlert = true
            }
            .foregroundColor(.red)
            .alert(isPresented: $isShowingDeleteAccountAlert) {
                Alert(
                    title: Text("Supprimer le compte"),
                    message: Text("Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible."),
                    primaryButton: .default(Text("Annuler")),
                    secondaryButton: .destructive(Text("Supprimer"), action: deleteAccount)
                )
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            viewModel.loadCurrentUser()
        }
    }
    
    private func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Erreur lors de la déconnexion : \(error.localizedDescription)")
        }
    }
    
    private func deleteAccount() {
        guard let currentUser = Auth.auth().currentUser else {
            print("Erreur : utilisateur non connecté.")
            return
        }
        
        currentUser.delete { error in
            if let error = error {
                print("Erreur lors de la suppression du compte : \(error.localizedDescription)")
            } else {
                viewModel.deleteUser(id: currentUser.uid)
            }
        }
    }
}

