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
        loginManager.logIn(permissions: ["public_profile", "email"]) { (result, error) in
            if let error = error {
                print("Erreur lors de la connexion avec Facebook : \(error.localizedDescription)")
                return
            }
            
            guard let accessToken = AccessToken.current else {
                print("Impossible de récupérer l'accès Facebook.")
                return
            }
            
            let credentials = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
            
            Auth.auth().signIn(with: credentials) { (authResult, error) in
                if let error = error {
                    print("Erreur lors de la connexion avec Firebase : \(error.localizedDescription)")
                    return
                }
                
                // L'utilisateur est connecté avec succès
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

