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
import UserNotifications

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
    var displayName: String // Nom à afficher pour la conversation
    var user: User // Utilisateur avec lequel la conversation a lieu
    var messages: [ChatMessage]
    var isTyping: Bool // Indique si l'utilisateur est en train de taper un message
    var quickReplies: [String] // Les réponses rapides pour cette conversation
    var isUnread: Bool // Indique si la conversation est marquée comme "non lue"
    var lastMessageText: String // Le texte du dernier message dans la conversation
    
    init(displayName: String, user: User, messages: [ChatMessage], isTyping: Bool, quickReplies: [String], isUnread: Bool) {
        self.displayName = displayName
        self.user = user
        self.messages = messages
        self.isTyping = isTyping
        self.quickReplies = quickReplies
        self.isUnread = isUnread
        
        // Get the last message text from messages
        self.lastMessageText = messages.last?.text ?? "Aucun message"
    }
}


class MessagingDelegate: NSObject, MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
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
struct PassionConnectApp: App {
    let persistenceController = PersistenceController.shared
    
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
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
