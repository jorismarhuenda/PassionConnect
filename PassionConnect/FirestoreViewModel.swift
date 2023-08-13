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
import FirebaseFirestoreSwift

class FirestoreViewModel: ObservableObject {
    let db = Firestore.firestore()
    @Published var currentUser: User?
    @Published var matches: [Match] = []
    @Published var conversations: [Conversation] = []
    @Published var isProfileViewPresented: Bool = false
    @Published var removedLikedUserID: UUID?
    @Published var likedUserIDs: [UUID: Set<UUID>] = [:]
    
    init() {
        loadAllConversations()
        subscribeToConversationsChanges()
    }
    
    func loadLikedUserIDs() {
        guard let currentUserID = currentUser?.id else {
            return
        }
        
        // Accédez à la collection "LikedUsers" dans Firestore pour l'utilisateur actuel
        let likedUsersCollection = Firestore.firestore().collection("LikedUsers").document(currentUserID.uuidString)
        
        likedUsersCollection.getDocument { document, error in
            if let document = document, document.exists {
                if let likedIDs = document.data()?["likedUserIDs"] as? [String] {
                    self.likedUserIDs = Dictionary(uniqueKeysWithValues: likedIDs.compactMap { uuidString in
                        guard let uuid = UUID(uuidString: uuidString) else {
                            return nil
                        }
                        return (uuid, Set<UUID>())
                    })
                }
            }
        }
    }
    
    
    // Met à jour les correspondants aimés dans Firestore
    func updateLikedUserIDs(for userID: UUID, completion: @escaping (Error?) -> Void) {
        guard let currentUserID = currentUser?.id else {
            return
        }
        
        // Accédez à la collection "LikedUsers" dans Firestore pour l'utilisateur actuel
        let likedUsersCollection = Firestore.firestore().collection("LikedUsers").document(currentUserID.uuidString)
        
        // Convertissez les UUID en tableau de chaînes pour Firestore
        let likedIDsArray = Array(likedUserIDs.keys).map { $0.uuidString }
        
        // Mettez à jour les données dans Firestore
        likedUsersCollection.setData(["likedUserIDs": likedIDsArray]) { error in
            if let error = error {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    func updatePotentialMatchesAfterUnmatch(_ potentialMatches: inout [Match], currentUserID: UUID) {
        if let matchedUserID = removedLikedUserID {
            if let matchedUserIndex = potentialMatches.firstIndex(where: { $0.id == matchedUserID }) {
                self.likedUserIDs[currentUserID]?.remove(matchedUserID)
                updateLikedUserIDs(for: currentUserID) { error in
                    if let error = error {
                        print("Erreur lors de la mise à jour des correspondants aimés du correspondant : \(error.localizedDescription)")
                    } else {
                        // Mettre à jour la liste des correspondants potentiels après la suppression
                        self.loadPotentialMatches()
                    }
                }
            }
            
            // Réinitialiser la propriété removedLikedUserID
            removedLikedUserID = nil
        }
    }
    
    func unmatchUser(_ match: Match, potentialMatches: inout [Match]) {
        guard let currentUserID = currentUser?.id else {
            return
        }
        
        // Supprimer l'utilisateur de la liste des correspondants aimés par l'utilisateur actuel
        if let userIDs = likedUserIDs[currentUserID] {
            var updatedUserIDs = userIDs
            updatedUserIDs.remove(match.id)
            likedUserIDs[currentUserID] = updatedUserIDs
            updateLikedUserIDs(for: currentUserID) { error in
                if let error = error {
                    print("Erreur lors de la mise à jour des correspondants aimés : \(error.localizedDescription)")
                }
            }
        }
        
        // Supprimer l'utilisateur actuel de la liste des correspondants aimés par le correspondant
        let matchedUserID = match.id
        if var matchedUser = likedUserIDs[matchedUserID] {
            matchedUser.remove(currentUserID)
            likedUserIDs[matchedUserID] = matchedUser
            updateLikedUserIDs(for: matchedUserID) { error in
                if let error = error {
                    print("Erreur lors de la mise à jour des correspondants aimés du correspondant : \(error.localizedDescription)")
                }
            }
            }
        
        // Mettre à jour la liste des correspondants potentiels après la suppression
        updatePotentialMatchesAfterUnmatch(&potentialMatches, currentUserID: currentUserID)
    }



    func deleteConversation(_ conversationID: String) {
        guard let currentUserID = currentUser?.id else {
            return
        }
        
        let localConversations = self.conversations
        
        Firestore.firestore().collection("conversations").document(conversationID).delete { error in
            if let error = error {
                print("Erreur lors de la suppression de la conversation : \(error.localizedDescription)")
            } else {
                // Supprimer la conversation de la liste des conversations de l'utilisateur
                if let index = localConversations.firstIndex(where: { $0.id.uuidString == conversationID }) {
                    self.conversations.remove(at: index)
                }
            }
        }
        
        // Mettre à jour la liste des conversations de l'utilisateur dans Firestore
        updateConversations(for: currentUserID) { error in
            if let error = error {
                print("Erreur lors de la mise à jour des conversations : \(error.localizedDescription)")
            }
        }
        self.conversations = localConversations
    }
    
    // Mettre à jour la liste des conversations de l'utilisateur dans Firestore
        func updateConversations(for userID: UUID, completion: @escaping (Error?) -> Void) {
            // Accédez à la collection "Conversations" dans Firestore pour l'utilisateur
            let conversationsCollection = Firestore.firestore().collection("Conversations").document(userID.uuidString)

            // Construisez un tableau des conversations de l'utilisateur à mettre à jour dans Firestore
            let conversationsToUpdate: [[String: Any]] = conversations.map { conversation in
                return [
                    "id": conversation.id,
                    // Ajoutez d'autres propriétés de conversation à mettre à jour ici
                ]
            }

            // Mettez à jour les données dans Firestore
            conversationsCollection.setData(["conversations": conversationsToUpdate]) { error in
                if let error = error {
                    completion(error)
                } else {
                    completion(nil)
                }
            }
        }
    
    func createConversation(with match: Match, completion: @escaping (Result<Conversation, Error>) -> Void, potentialMatches: inout [Match]) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            let error = NSError(domain: "FirestoreViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "ID de l'utilisateur actuel manquant"])
            completion(.failure(error))
            return
        }
        
        let conversationRef = db.collection("conversations").document()
        
        // Créer le currentUser avec les informations appropriées
        let currentUser = User(
            name: "John Doe",
            bio: "Nature lover",
            email: "john@example.com",
            profileImageName: "john",
            fcmToken: "VotreTokenFCM",
            age: 25,
            interests: ["Intérêt1", "Intérêt2"],
            description: "VotreDescription"
        )
        
        // Convertir les participants en UUID
        guard let currentUserUUID = UUID(uuidString: currentUserID),
              let otherUserUUID = UUID(uuidString: match.id.uuidString) else {
            let error = NSError(domain: "FirestoreViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Erreur lors de la conversion d'UUID"])
            completion(.failure(error))
            return
        }
        
        // Utiliser les UUID pour créer le tableau userIDs
        let userIDs: [UUID] = [currentUserUUID, otherUserUUID]
        
        // Créer la nouvelle conversation
        let conversationUUID = UUID(uuidString: conversationRef.documentID) ?? UUID()
        let conversationData: [String: Any] = [
            "id": conversationUUID.uuidString,
            "userIDs": userIDs.map { $0.uuidString },
            "displayName": "NomAffiché",
            "user": [
                "name": currentUser.name,
                "bio": currentUser.bio,
                "email": currentUser.email,
                "profileImageName": currentUser.profileImageName,
                "fcmToken": currentUser.fcmToken!,
                "age": currentUser.age,
                "interest": currentUser.interests,
                "description": currentUser.description
            ],
            "messages": [], // Mettez en forme les messages ici
            "isTyping": false,
            "quickReplies": [],
            "isUnread": true,
            "lastMessageText": "Aucun message",
            "otherUserName": "NomAutreUtilisateur"
        ]
        
        // Enregistrer la conversation dans Firestore
        conversationRef.setData(conversationData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Créer l'instance Conversation à partir des données
                let conversation = Conversation(
                    id: conversationUUID,
                    userIDs: userIDs,
                    displayName: "NomAffiché",
                    user: currentUser,
                    messages: [],
                    isTyping: false,
                    quickReplies: [],
                    isUnread: true,
                    lastMessageText: "Aucun message",
                    otherUserName: "NomAutreUtilisateur"
                )
                completion(.success(conversation))
            }
        }
    }



    
    func likeMatch(_ match: Match, completion: @escaping (Error?) -> Void, potentialMatches: inout [Match]) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("Erreur : impossible de liker le correspondant, l'ID de l'utilisateur actuel est manquant.")
            return
        }
        
        let likesRef = db.collection("likes")
        
        let likeData: [String: Any] = [
            "userID": currentUserID,
            "likedUserID": match.id,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        likesRef.addDocument(data: likeData) { error in
            if let error = error {
                completion(error)
            } else {
                if let indexToRemove = potentialMatches.firstIndex(where: { $0.id == match.id }) {
                                potentialMatches.remove(at: indexToRemove)
                            }
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
                            let match = Match(id: UUID(), name: "John Doe", bio: "Nature lover", interests: ["Hiking", "Photography"], profileImageName: "john", email: "john@example.com", profileImageURL: URL(string: "https://example.com/john.jpg"), userName: "JohnD", age: 30, commonInterests: ["Hiking"])
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
            
            if let data = snapshot?.data() {
                do {
                    let decoder = Firestore.Decoder()
                    let userInterests = try decoder.decode(UserInterests.self, from: data)
                    DispatchQueue.main.async {
                        self.currentUserInterests = userInterests
                    }
                } catch {
                    print("Erreur lors du décodage des intérêts de l'utilisateur : \(error.localizedDescription)")
                }
            } else {
                print("Aucune donnée d'intérêts utilisateur trouvée.")
            }
        }
    }

    
    
    func loadPotentialMatches(potentialMatches: inout [Match]) {
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
            var potentialMatches = documents.compactMap { document -> Match? in
                do {
                    let match = try document.data(as: Match.self)
                    return match
                } catch {
                    print("Erreur lors du décodage du correspondant potentiel : \(error.localizedDescription)")
                    return nil
                }
            }
            
            DispatchQueue.main.async {
                potentialMatches = potentialMatches
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
        let userRef = firestore.collection("users").document(user.id.uuidString)
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
                    self.currentUser?.name = name
                    self.currentUser?.bio = bio
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
    
    
    func findRandomMatch(completion: @escaping (Match?) -> Void, potentialMatches: inout [Match]) {
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
        let unmatchedMatches = potentialMatches.filter { !likedUserIDs.contains($0.id.uuidString) }
        
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
            var matchedUser = potentialMatches.first { $0.id == matchedUserID }
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

