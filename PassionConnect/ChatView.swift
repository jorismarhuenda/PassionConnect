//
//  ChatView.swift
//  PassionConnect
//
//  Created by marhuenda joris on 29/07/2023.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift
import UserNotifications

struct User: Identifiable, Codable {
    var id = UUID()
    var name: String
    var bio: String
    var email: String
    var profileImageName: String
    var fcmToken: String? // Stocke le token FCM de l'utilisateur pour les notifications push
}

enum MessageType: String, Codable {
    case text
    case image
}

struct ChatMessage: Identifiable, Codable {
    @DocumentID var id: String? = UUID().uuidString
    var type: MessageType
    var senderID: String
    var receiverID: String
    var text: String?
    var imageUrl: String?
    var isRead: Bool // Indique si le message a été lu ou non
    var isConfidential: Bool // Indique si le message est confidentiel
    @ServerTimestamp var timestamp: Timestamp?
}

struct Conversation: Identifiable {
    var id = UUID()
    var user: User
    var messages: [ChatMessage]
    var isTyping: Bool // Indique si l'utilisateur est en train de taper un message
    var quickReplies: [String] // Les réponses rapides pour cette conversation
    var isUnread: Bool // Indique si la conversation est marquée comme "non lue"
}

class MessagingDelegate: NSObject, MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcmToken = fcmToken {
            // Mettre à jour le token FCM de l'utilisateur dans Firestore
            let userId = Auth.auth().currentUser?.uid // Supposons que vous utilisez Firebase Authentication pour gérer l'authentification des utilisateurs
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
}


class FirestoreViewModel: ObservableObject {
    private let db = Firestore.firestore()
    @Published var currentUser: User = User(name: "", bio: "", email: "")
    @Published var matches: [Match] = []
    @Published var conversations: [Conversation] = []
    
    init() {
        loadAllConversations()
        subscribeToConversationsChanges()
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

struct ChatView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel = FirestoreViewModel()
    @State private var newMessageText: String = ""
    @State private var isImagePickerPresented: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var selectedImageData: Data? = nil
    @State private var isUploadingImage: Bool = false
    private var currentUser: User = User(name: "John Doe", profileImageName: "profile_image_1", fcmToken: nil)
    private var otherUser: User = User(name: "Jane Smith", profileImageName: "profile_image_2", fcmToken: nil)
    
    var body: some View {
        VStack {
            HStack {
                Button("Fermer") {
                    isPresented = false
                }
                Spacer()
            }
            .padding()
            
            List {
                ForEach(viewModel.conversations) { conversation in
                    VStack(alignment: .leading) {
                        Text(conversation.user.name)
                            .font(.headline)
                        ForEach(conversation.messages) { message in
                            MessageRow(message: message, currentUser: currentUser)
                                .contextMenu {
                                    Button("Supprimer le message") {
                                        viewModel.deleteMessage(message, in: conversation)
                                    }
                                }
                        }
                        
                        if conversation.isTyping {
                            Text("Typing...")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }
                    .contextMenu {
                        ForEach(conversation.quickReplies, id: \.self) { reply in
                            Button(reply, action: {
                                viewModel.sendQuickReply(reply, in: conversation)
                            })
                        }
                        
                        Button("Marquer comme non lu") {
                            viewModel.markAsUnread(conversation)
                        }
                    }
                }
            }
            
            HStack {
                Button(action: {
                    isImagePickerPresented = true
                }, label: {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                })
                .padding(.trailing, 8)
                
                TextField("Saisir un message", text: $newMessageText, onCommit: sendMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Envoyer", action: sendMessage)
            }
            .padding()
            .sheet(isPresented: $isImagePickerPresented, onDismiss: {
                if let imageData = selectedImageData {
                    uploadImageToStorage(imageData: imageData)
                    selectedImageData = nil
                }
            }) {
                ImagePicker(selectedImage: $selectedImage)
            }
        }
        .onAppear {
            if let fcmToken = UserDefaults.standard.string(forKey: "fcmToken") {
                currentUser.fcmToken = fcmToken
            }
        }
    }
    
    private func sendMessage() {
        let newMessage = ChatMessage(type: .text, senderID: currentUser.id, receiverID: otherUser.id, text: newMessageText, imageUrl: nil, isRead: false, isConfidential: false, timestamp: Timestamp())
        viewModel.sendMessage(newMessage)
        newMessageText = ""
    }
    
    private func uploadImageToStorage(imageData: Data) {
        isUploadingImage = true
        // ...
    }
}

struct MessageRow: View {
    var message: ChatMessage
    var currentUser: User
    
    var body: some View {
        HStack {
            if message.senderID == currentUser.id {
                Spacer()
                switch message.type {
                case .text:
                    Text(message.text ?? "")
                        .padding()
                        .background(message.isRead ? Color.blue : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                case .image:
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .padding()
                        .background(message.isRead ? Color.blue : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                VStack(alignment: .leading) {
                    Text(message.senderID)
                        .font(.footnote)
                    switch message.type {
                    case .text:
                        Text(message.text ?? "")
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    case .image:
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                Spacer()
            }
            if message.isConfidential {
                Image(systemName: "lock.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = context.coordinator
        imagePicker.sourceType = .photoLibrary
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

@main
struct YourApp: App {
    init() {
        FirebaseApp.configure()
        Messaging.messaging().delegate = MessagingDelegate()
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
        }
    }
}
