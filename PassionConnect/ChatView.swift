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
    @State var newMessageText: String = ""
    @State var isImagePickerPresented: Bool = false
    @State var selectedImage: UIImage? = nil
    @State var selectedImageData: Data? = nil
    @State var isUploadingImage: Bool = false
    @State var currentUser: User = User(id: UUID(), name: "John Doe", bio: "", email: "", profileImageName: "profile_image_1", fcmToken: nil, age: 0, interests: [], description: "")
    var otherUser: User = User(id: UUID(), name: "Jane Smith", bio: "", email: "", profileImageName: "profile_image_2", fcmToken: nil, age: 0, interests: [], description: "")
    var conversation: Conversation


    
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
        .onAppear {
            if let fcmToken = UserDefaults.standard.string(forKey: "fcmToken") {
                currentUser.fcmToken = fcmToken
            }
        }
    }
    
    private func sendMessage() {
        var newMessage: ChatMessage

        if let imageUrl = selectedImageData, !imageUrl.isEmpty {
            // Upload the image and get the download URL
            uploadImageToStorage(imageData: imageUrl)
            return
        } else {
            newMessage = ChatMessage(type: .text, senderID: currentUser.id.uuidString, receiverID: otherUser.id.uuidString, text: newMessageText, imageUrl: nil, isRead: false, isConfidential: false, timestamp: Timestamp())
        }

        viewModel.sendMessage(newMessage, in: conversation)

        // Reset state
        newMessageText = ""
        selectedImage = nil
        selectedImageData = nil
        isImagePickerPresented = false
    }


    
    private func uploadImageToStorage(imageData: Data) {
        isUploadingImage = true
        
        let storageRef = Storage.storage().reference()
        let imageName = UUID().uuidString
        let imageRef = storageRef.child("images/\(imageName).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error)")
                isUploadingImage = false
            } else {
                imageRef.downloadURL { url, error in
                    if let imageUrl = url {
                        let newMessage = ChatMessage(type: .image, senderID: currentUser.id.uuidString, receiverID: otherUser.id.uuidString, text: "", imageUrl: imageUrl.absoluteString, isRead: false, isConfidential: false, timestamp: Timestamp())
                        
                        viewModel.sendMessage(newMessage, in: conversation)
                    }
                    
                    isUploadingImage = false
                }
            }
        }
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
