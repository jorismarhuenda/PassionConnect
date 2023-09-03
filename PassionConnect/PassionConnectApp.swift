//
//  PassionConnectApp.swift
//  PassionConnect
//
//  Created by marhuenda joris on 03/09/2023.
//

import SwiftUI
import Firebase

@main
struct PassionConnectApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        FirebaseApp.configure()
        Messaging.messaging().delegate = MyMessagingDelegate()
        // Configurer les options de notification pour l'obtention du consentement de l'utilisateur (si nécessaire)
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
