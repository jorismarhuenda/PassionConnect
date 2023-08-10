//
//  FacebookLoginView.swift
//  PassionConnect
//
//  Created by marhuenda joris on 30/07/2023.
//

import SwiftUI
import Firebase
import FBSDKLoginKit

struct FacebookLoginView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Spacer()
            
            Button(action: signInWithFacebook, label: {
                Text("Se connecter avec Facebook")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            })
            .padding()
            
            Spacer()
        }
        .navigationBarTitle("Connexion avec Facebook", displayMode: .inline)
    }
    
    private func signInWithFacebook() {
        let loginManager = LoginManager()
        loginManager.logIn(permissions: ["public_profile", "email"]) { result in
            switch result {
            case .success(granted: _, declined: _, token: let accessToken):
                if let accessToken = accessToken {
                    let credentials = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
                    Auth.auth().signIn(with: credentials) { authResult, error in
                        if let error = error {
                            print("Erreur lors de la connexion avec Firebase : \(error.localizedDescription)")
                        } else {
                            // L'utilisateur est connecté avec succès
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                } else {
                    print("Impossible de récupérer l'accès Facebook.")
                }
            case .cancelled:
                // Connexion annulée par l'utilisateur
                print("Connexion Facebook annulée")
            case .failed(let error):
                // Erreur lors de la connexion
                print("Erreur lors de la connexion avec Facebook : \(error.localizedDescription)")
            }
        }
    }
}

