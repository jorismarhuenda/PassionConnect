//
//  Messaging.swift
//  PassionConnect
//
//  Created by marhuenda joris on 10/08/2023.
//

import FirebaseMessaging

class MyMessaging {
    static let shared = MyMessaging()

    func subscribe(to topic: String) {
        Messaging.messaging().subscribe(toTopic: topic) { error in
            if let error = error {
                print("Erreur lors de l'abonnement au topic \(topic) : \(error.localizedDescription)")
            } else {
                print("Abonnement au topic \(topic) avec succès.")
            }
        }
    }
    
    func unsubscribe(from topic: String) {
        Messaging.messaging().unsubscribe(fromTopic: topic) { error in
            if let error = error {
                print("Erreur lors de la désinscription du topic \(topic) : \(error.localizedDescription)")
            } else {
                print("Désinscription du topic \(topic) avec succès.")
            }
        }
    }
}
