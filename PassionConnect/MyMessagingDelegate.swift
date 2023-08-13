//
//  MyMessagingDelegate.swift
//  PassionConnect
//
//  Created by marhuenda joris on 13/08/2023.
//

import Firebase
import FirebaseMessaging
import UserNotifications

class MyMessagingDelegate: NSObject, MessagingDelegate {
    private func messaging(_ messaging: MyMessaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcmToken = fcmToken {
            // Mettre à jour le token FCM de l'utilisateur dans Firestore
            let userId = Auth.auth().currentUser?.uid
            guard let userId = userId else { return }
            
            let userRef = Firestore.firestore().collection("users").document(userId)
            userRef.updateData(["fcmToken": fcmToken]) { error in
                if let error = error {
                    print("Erreur lors de la mise à jour du token FCM dans Firestore : \(error.localizedDescription)")
                } else {
                    print("Token FCM mis à jour dans Firestore avec succès : \(fcmToken)")
                }
            }
            
            UserDefaults.standard.setValue(fcmToken, forKey: "fcmToken") // Stocker le token FCM dans la mémoire
        }
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        // Gérer la réception d'un message distant (notification push)
        print("Message distant reçu : \(remoteMessage.appData)")
        // Traitez le contenu du message distant comme requis
        processRemoteMessage(remoteMessage.appData)
    }
    
    private func updateFCMTokenOnServer(_ token: String) {
        // Envoyez le token FCM au serveur backend pour mise à jour
        // Exemple de code pour envoyer le token via une requête HTTP
        let urlString = "https://votre-serveur-backend.com/update_fcm_token"
        if let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            let params: [String: Any] = ["fcmToken": token]
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("Erreur lors de la mise à jour du token FCM sur le serveur : \(error.localizedDescription)")
                    } else {
                        print("Token FCM mis à jour sur le serveur avec succès")
                    }
                }
                task.resume()
            } catch {
                print("Erreur lors de la sérialisation des données : \(error.localizedDescription)")
            }
        }
    }

    private func processRemoteMessage(_ messageData: [AnyHashable: Any]) {
        // Assurez-vous que le message contient les données requises pour afficher une notification
        guard let title = messageData["title"] as? String,
              let body = messageData["body"] as? String else {
            print("Données de message insuffisantes pour afficher la notification")
            return
        }
        
        // Créez un contenu de notification
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        // Configurez l'affichage de la notification
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        let center = UNUserNotificationCenter.current()
        
        // Demandez l'autorisation à l'utilisateur pour afficher la notification
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                // Ajoutez la notification au centre de notifications
                center.add(request) { error in
                    if let error = error {
                        print("Erreur lors de l'ajout de la notification : \(error.localizedDescription)")
                    } else {
                        print("Notification affichée avec succès")
                    }
                }
            } else if let error = error {
                print("Erreur lors de la demande d'autorisation : \(error.localizedDescription)")
            }
        }
    }

}

