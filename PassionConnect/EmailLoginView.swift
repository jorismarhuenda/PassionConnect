//
//  EmailLoginView.swift
//  PassionConnect
//
//  Created by marhuenda joris on 30/07/2023.
//

import SwiftUI
import Firebase

struct EmailLoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            TextField("Adresse e-mail", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            SecureField("Mot de passe", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: signInWithEmail, label: {
                Text("Se connecter")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            })
            .padding()
            
            Spacer()
        }
        .navigationBarTitle("Connexion avec Email", displayMode: .inline)
    }
    
    private func signInWithEmail() {
        Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                print("Erreur lors de la connexion avec Firebase : \(error.localizedDescription)")
                return
            }
            
            // L'utilisateur est connecté avec succès
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}
