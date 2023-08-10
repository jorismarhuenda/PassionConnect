//
//  FirestoreViewModel.swift
//  PassionConnect
//
//  Created by marhuenda joris on 10/08/2023.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import UserNotifications

class FirestoreViewModel: ObservableObject {
    private let db = Firestore.firestore()
    @Published var currentUser: User = User(name: "", bio: "", email: "")
    @Published var matches: [Match] = []
    @Published var conversations: [Conversation] = []
    @Published var isProfileViewPresented: Bool = false
    
    init() {
        loadAllConversations()
        subscribeToConversationsChanges()
    }
    
    func unmatchUser(_ match: Match) {
            guard let currentUserID = currentUser.id else {
                return
            }
            
            // Supprimer l'utilisateur de la liste des correspondants aimés par l'utilisateur actuel
            likedUserIDs.remove(match.userID)
            updateLikedUserIDs(for: currentUserID) { error in
                if let error = error {
                    print("Erreur lors de la mise à jour des correspondants aimés : \(error.localizedDescription)")
                }
            }
        // Supprimer l'utilisateur actuel de la liste des correspondants aimés par le correspondant
                if let matchedUserID = match.userID {
                    var matchedUser = potentialMatches.first { $0.userID == matchedUserID }
                    matchedUser?.likedUserIDs.remove(currentUserID)
                    if let updatedMatchedUser = matchedUser {
                        updateLikedUserIDs(for: matchedUserID) { error in
                            if let error = error {
                                print("Erreur lors de la mise à jour des correspondants aimés du correspondant : \(error.localizedDescription)")
                            }
                        }
                    }
                }
                
                // Mettre à jour la liste des correspondants potentiels après la suppression
                loadPotentialMatches()
            }
    
    func deleteConversation(_ conversationID: String) {
            guard let currentUserID = currentUser.id else {
                return
            }
            
            Firestore.firestore().collection("conversations").document(conversationID).delete { error in
                if let error = error {
                    print("Erreur lors de la suppression de la conversation : \(error.localizedDescription)")
                } else {
                    // Supprimer la conversation de la liste des conversations de l'utilisateur
                    if let index = conversations.firstIndex(where: { $0.id == conversationID }) {
                        conversations.remove(at: index)
                    }
                }
            }
            
            // Mettre à jour la liste des conversations de l'utilisateur dans Firestore
            updateConversations(for: currentUserID) { error in
                if let error = error {
                    print("Erreur lors de la mise à jour des conversations : \(error.localizedDescription)")
                }
            }
        }
    
    func createConversation(with match: Match, completion: @escaping (Result<Conversation, Error>) -> Void) {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                let error = NSError(domain: "FirestoreViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "ID de l'utilisateur actuel manquant"])
                completion(.failure(error))
                return
            }

            let conversationRef = db.collection("conversations").document()

            let participants: [String] = [currentUserID, match.userID]
            let newConversation = Conversation(id: conversationRef.documentID, userIDs: participants)

            conversationRef.setData(newConversation.toDictionary()) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(newConversation))
                }
            }
        }
    
    func likeMatch(_ match: Match, completion: @escaping (Error?) -> Void) {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                print("Erreur : impossible de liker le correspondant, l'ID de l'utilisateur actuel est manquant.")
                return
            }
            
            let likesRef = db.collection("likes")
            
            let likeData: [String: Any] = [
                "userID": currentUserID,
                "likedUserID": match.userID,
                "timestamp": FieldValue.serverTimestamp()
            ]
            
            likesRef.addDocument(data: likeData) { error in
                if let error = error {
                    completion(error)
                } else {
                    self.potentialMatches.removeAll { $0.userID == match.userID }
                    completion(nil)
                }
            }
        }
    
    func searchMatches(preferredAge: Int, maximumDistance: Int, interests: [String], completion: @escaping ([Match]) -> Void) {
            let query = Firestore.firestore().collection("users")
                .whereField("age", isGreaterThanOrEqualTo: preferredAge)
                .whereField("age", isLessThanOrEqualTo: preferredAge + 5) // On peut ajuster cette plage d'âge selon les préférences
                .whereField("distance", isLessThanOrEqualTo: maximumDistance)
                .whereField("interests", arrayContainsAny: interests)
            
            query.getDocuments { querySnapshot, error in
                if let error = error {
                    print("Erreur lors de la recherche de correspondances : \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                var matches: [Match] = []
                for document in querySnapshot!.documents {
                    do {
                        if let user = try document.data(as: User.self) {
                            if user.id != currentUser.id && !likedUserIDs.contains(user.id!) {
                                let match = Match(userID: user.id!, userName: user.name, age: user.age, commonInterests: Array(Set(user.interests).intersection(interests)))
                                matches.append(match)
                            }
                        }
                    } catch {
                                        print("Erreur lors de la conversion des données : \(error.localizedDescription)")
                                    }
                                }
                                
                                completion(matches)
                            }
                        }
    
    func loadUserInterests() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("Erreur : utilisateur non connecté.")
            return
        }

        let userInterestsRef = db.collection("userInterests").document(currentUserID)

        userInterestsRef.getDocument { snapshot, error in
            if let error = error {
                print("Erreur lors du chargement des intérêts de l'utilisateur : \(error.localizedDescription)")
                return
            }

            if let data = snapshot?.data(), let userInterests = try? Firestore.Decoder().decode(UserInterests.self, from: data) {
                DispatchQueue.main.async {
                    self.currentUserInterests = userInterests
                }
            } else {
                print("Aucune donnée d'intérêts utilisateur trouvée.")
            }
        }
    }

    
    func loadPotentialMatches() {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                print("Erreur : impossible de charger les correspondants potentiels, l'ID de l'utilisateur actuel est manquant.")
                return
            }
            
            let potentialMatchesRef = db.collection("potentialMatches").document(currentUserID).collection("matches")
            
            potentialMatchesRef.getDocuments { snapshot, error in
                if let error = error {
                    print("Erreur lors du chargement des correspondants potentiels : \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("Aucun correspondant potentiel trouvé.")
                    return
                }
                let potentialMatches = documents.compactMap { document -> Match? in
                                do {
                                    let match = try document.data(as: Match.self)
                                    return match
                                } catch {
                                    print("Erreur lors du décodage du correspondant potentiel : \(error.localizedDescription)")
                                    return nil
                                }
                            }
                            
                            DispatchQueue.main.async {
                                self.potentialMatches = potentialMatches
                            }
                        }
                    }
    
    func loadCurrentUser() {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                print("Erreur : impossible de charger l'utilisateur actuel, l'ID de l'utilisateur actuel est manquant.")
                return
            }

            let usersRef = db.collection("users").document(currentUserID)
            usersRef.getDocument { snapshot, error in
                if let error = error {
                    print("Erreur lors du chargement de l'utilisateur actuel : \(error.localizedDescription)")
                    return
                }

                if let data = snapshot?.data(), let user = try? Firestore.Decoder().decode(User.self, from: data) {
                    DispatchQueue.main.async {
                        self.currentUser = user
                    }
                } else {
                    print("Aucune donnée d'utilisateur trouvée.")
                }
            }
        }
    
    func updateUserProfile(_ user: User, firestore: Firestore, completion: @escaping (Error?) -> Void) {
        let userRef = firestore.collection("users").document(user.id)
        let updatedData: [String: Any] = [
            "name": user.name,
            "age": user.age,
            "interests": user.interests,
            "description": user.description
        ]

        userRef.updateData(updatedData) { error in
            if let error = error {
                completion(error)
            } else {
                DispatchQueue.main.async {
                    // Mettez à jour les propriétés de l'utilisateur actuel ici si nécessaire
                }
                completion(nil)
            }
        }
    }

    
    func updateUser(id: String, name: String, bio: String, completion: @escaping (Error?) -> Void) {
            let userRef = db.collection("users").document(id)
            let updatedData: [String: Any] = [
                "name": name,
                "bio": bio
            ]

            userRef.updateData(updatedData) { error in
                if let error = error {
                    completion(error)
                } else {
                    DispatchQueue.main.async {
                        self.currentUser.name = name
                        self.currentUser.bio = bio
                    }
                    completion(nil)
                }
            }
        }
    
    func deleteUser(id: String) {
            let userRef = db.collection("users").document(id)

            userRef.delete { error in
                if let error = error {
                    print("Erreur lors de la suppression de l'utilisateur : \(error.localizedDescription)")
                }
            }
        }
    
    func updateUserInterests(_ interests: [String], completion: @escaping (Error?) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return
        }

        let userInterestsRef = db.collection("userInterests").document(currentUserID)
        let updatedInterests = UserInterests(userId: currentUserID, interests: interests)  // Ajoutez l'ID de l'utilisateur ici

        do {
            try userInterestsRef.setData(from: updatedInterests, merge: true) { error in
                if let error = error {
                    completion(error)
                } else {
                    DispatchQueue.main.async {
                        self.currentUserInterests = updatedInterests
                    }
                    completion(nil)
                }
            }
        } catch {
            print("Erreur lors de la mise à jour des intérêts de l'utilisateur : \(error.localizedDescription)")
            completion(error)
        }
    }

    
    func findRandomMatch(completion: @escaping (Match?) -> Void) {
            guard let currentUserID = currentUser.id else {
                completion(nil)
                return
            }
            
            // Vérifie si l'utilisateur a déjà aimé tous les correspondants potentiels
            if likedUserIDs.count == potentialMatches.count {
                completion(nil)
                return
            }
            
            // Filtrer les correspondants potentiels pour obtenir ceux qui n'ont pas encore été aimés
            let unmatchedMatches = potentialMatches.filter { !likedUserIDs.contains($0.userID) }
            
            // Sélectionner un correspondant aléatoire parmi les correspondants potentiels non aimés
            let randomIndex = Int.random(in: 0..<unmatchedMatches.count)
            let randomMatch = unmatchedMatches[randomIndex]
            // Mettre à jour la liste des correspondants aimés par l'utilisateur actuel
                likedUserIDs.insert(randomMatch.userID)
                updateLikedUserIDs(for: currentUserID) { error in
                    if let error = error {
                        print("Erreur lors de la mise à jour des correspondants aimés : \(error.localizedDescription)")
                    }
                }
                
                // Mettre à jour les correspondants aimés par le correspondant sélectionné
                if let matchedUserID = randomMatch.userID {
                    var matchedUser = potentialMatches.first { $0.userID == matchedUserID }
                    matchedUser?.likedUserIDs.insert(currentUserID)
                    if let updatedMatchedUser = matchedUser {
                        updateLikedUserIDs(for: matchedUserID) { error in
                            if let error = error {
                                print("Erreur lors de la mise à jour des correspondants aimés du correspondant sélectionné : \(error.localizedDescription)")
                            }
                        }
                        completion(updatedMatchedUser)
                    }
                }
                
                completion(randomMatch)
            }
    
    func loadMatches() {
            guard let currentUserID = Auth.auth().currentUser?.uid else {
                print("Erreur : impossible de charger les correspondances, l'ID de l'utilisateur actuel est manquant.")
                return
            }

            let usersRef = db.collection("users")
            usersRef.getDocuments { snapshot, error in
                if let error = error {
                    print("Erreur lors du chargement des correspondances : \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else {
                                print("Aucun document trouvé pour les correspondances.")
                                return
                            }
                            
                            var newMatches: [Match] = []
                            for document in documents {
                                if let match = try? document.data(as: Match.self), match.id != currentUserID {
                                    newMatches.append(match)
                                }
                            }
                            
                            DispatchQueue.main.async {
                                self.matches = newMatches
                            }
                        }
                    }
    
    func loadAllConversations() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("Erreur : utilisateur non connecté.")
            return
        }
        
        // Récupérer les conversations de l'utilisateur actuellement connecté depuis Firestore
        db.collection("conversations")
            .whereField("userIDs", arrayContains: currentUserID)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Erreur lors de la récupération des conversations : \(error?.localizedDescription ?? "Erreur inconnue")")
                    return
                }
                
                self.conversations = documents.compactMap { document in
                    do {
                        if let conversation = try document.data(as: Conversation.self) {
                            return conversation
                        } else {
                            print("Erreur : impossible de convertir le document en Conversation.")
                            return nil
                        }
                    } catch {
                        print("Erreur lors de la conversion du document en Conversation : \(error.localizedDescription)")
                        return nil
                }
            }
        }
    }
    
    func subscribeToConversationsChanges() {
        // Abonnement aux modifications de la collection de conversations dans Firestore
                guard let currentUserID = Auth.auth().currentUser?.uid else {
                    print("Erreur : utilisateur non connecté.")
                    return
                }
                
                db.collection("conversations")
                    .whereField("userIDs", arrayContains: currentUserID)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("Erreur lors de la récupération des conversations : \(error?.localizedDescription ?? "Erreur inconnue")")
                            return
                        }
                        
                        self.conversations = documents.compactMap { document in
                            do {
                                if let conversation = try document.data(as: Conversation.self) {
                                    return conversation
                                } else {
                                    print("Erreur : impossible de convertir le document en Conversation.")
                                                                return nil
                                                            }
                                                        } catch {
                                                            print("Erreur lors de la conversion du document en Conversation : \(error.localizedDescription)")
                                                            return nil
                }
            }
        }
    }
    
    func sendMessage(_ message: ChatMessage, in conversation: Conversation) {
            guard let conversationID = conversation.id else {
                print("Erreur : impossible d'envoyer le message, ID de conversation manquant.")
                return
            }
            
            // Ajouter le message à la conversation dans Firestore
            do {
                var newConversation = conversation
                newConversation.messages.append(message)
                try db.collection("conversations").document(conversationID).setData(from: newConversation)
            } catch {
                print("Erreur lors de l'ajout du message à la conversation : \(error.localizedDescription)")
            }
        }
    
    func deleteMessage(_ message: ChatMessage, in conversation: Conversation) {
            guard let conversationID = conversation.id else {
                print("Erreur : impossible de supprimer le message, ID de conversation manquant.")
                return
            }
            
            // Supprimer le message de la conversation dans Firestore
            do {
                var newConversation = conversation
                newConversation.messages.removeAll { $0.id == message.id }
                try db.collection("conversations").document(conversationID).setData(from: newConversation)
            } catch {
                print("Erreur lors de la suppression du message de la conversation : \(error.localizedDescription)")
            }
        }
    
    func markAsUnread(_ conversation: Conversation) {
            guard let conversationID = conversation.id else {
                print("Erreur : impossible de marquer comme non lu, ID de conversation manquant.")
                return
            }
            
            // Marquer la conversation comme "non lue" dans Firestore
            do {
                var newConversation = conversation
                newConversation.isUnread = true
                try db.collection("conversations").document(conversationID).setData(from: newConversation)
            } catch {
                print("Erreur lors du marquage comme non lu de la conversation : \(error.localizedDescription)")
            }
        }
    
    func sendQuickReply(_ quickReply: String, in conversation: Conversation) {
            guard let currentUserID = Auth.auth().currentUser?.uid,
                  let otherUserID = conversation.userIDs.first(where: { $0 != currentUserID }) else {
                print("Erreur : impossible d'envoyer la réponse rapide, informations utilisateur manquantes.")
                return
            }
            
            let newMessage = ChatMessage(type: .text, senderID: currentUserID, receiverID: otherUserID, text: quickReply, imageUrl: nil, isRead: false, isConfidential: false, timestamp: Timestamp())
            
            sendMessage(newMessage, in: conversation)
    }
}
