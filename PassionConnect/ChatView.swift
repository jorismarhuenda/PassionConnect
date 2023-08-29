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
    var id: String = UUID().uuidString
    var type: MessageType
    var senderID: String
    var receiverID: String
    var text: String?
    var imageUrl: String?
    var isRead: Bool // Indique si le message a été lu ou non
    var isConfidential: Bool // Indique si le message est confidentiel
    var timestamp: Timestamp?
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case senderID
        case receiverID
        case text
        case imageUrl
        case isRead
        case isConfidential
        case timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decode(MessageType.self, forKey: .type)
        self.senderID = try container.decode(String.self, forKey: .senderID)
        self.receiverID = try container.decode(String.self, forKey: .receiverID)
        self.text = try container.decodeIfPresent(String.self, forKey: .text)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.isRead = try container.decode(Bool.self, forKey: .isRead)
        self.isConfidential = try container.decode(Bool.self, forKey: .isConfidential)
        let timestampValue = try container.decode(Double.self, forKey: .timestamp)
        self.timestamp = Timestamp(seconds: Int64(timestampValue), nanoseconds: 0)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(senderID, forKey: .senderID)
        try container.encode(receiverID, forKey: .receiverID)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encode(isRead, forKey: .isRead)
        try container.encode(isConfidential, forKey: .isConfidential)
        if let timestamp = timestamp {
            try container.encode(Double(timestamp.seconds), forKey: .timestamp)
        }
    }
}

struct ChatView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: FirestoreViewModel
    @State private var isChatViewPresented = false
    @State var newMessageText: String = ""
    @State var isImagePickerPresented: Bool
    @State var selectedImage: UIImage?
    @State var selectedImageData: Data?
    @State var isUploadingImage: Bool
    @State var currentUser: User = User(id: UUID(), name: "John Doe", bio: "", email: "", profileImageName: "profile_image_1", fcmToken: nil, age: 0, interests: [], description: "")
    var otherUser: User = User(id: UUID(), name: "Jane Smith", bio: "", email: "", profileImageName: "profile_image_2", fcmToken: nil, age: 0, interests: [], description: "")
    var conversation: Conversation
    
    
    
    var body: some View {
        NavigationView {
            List(viewModel.conversations) { conversation in
                NavigationLink(
                    destination: ChatView(
                        isPresented: .constant(false),
                        viewModel: viewModel,
                        newMessageText: "",
                        isImagePickerPresented: false,
                        selectedImage: nil,
                        selectedImageData: nil,
                        isUploadingImage: false,
                        currentUser: User(id: UUID(), name: "John Doe", bio: "", email: "", profileImageName: "profile_image_1", fcmToken: nil, age: 0, interests: [], description: ""),
                        otherUser: User(id: UUID(), name: "Jane Smith", bio: "", email: "", profileImageName: "profile_image_2", fcmToken: nil, age: 0, interests: [], description: ""),
                        conversation: conversation
                    )
                ) {
                    Text(conversation.otherUserName)
                }
                .navigationBarTitle("Mes Conversations")
            }
            
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
                viewModel.loadAllConversations()
                if let fcmToken = UserDefaults.standard.string(forKey: "fcmToken") {
                    currentUser.fcmToken = fcmToken
                }
            }
        }
    }
        
        private func sendMessage() {
            if let imageData = selectedImageData, !imageData.isEmpty {
                // Upload the image and get the download URL
                uploadImageToStorage(imageData: imageData)
            } else {
                let newMessage = ChatMessage(
                    type: .image,
                    senderID: self.currentUser.id.uuidString,
                    receiverID: self.otherUser.id.uuidString,
                    text: "",
                    imageUrl: nil,
                    isRead: false,
                    isConfidential: false,
                    timestamp: Timestamp()
                )
                
                viewModel.sendMessage(newMessage, in: conversation)
                
                // Reset state
                newMessageText = ""
            }
            
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
                            let newMessage = ChatMessage(
                                type: .image,
                                senderID: self.currentUser.id.uuidString,
                                receiverID: self.otherUser.id.uuidString,
                                text: "",
                                imageUrl: imageUrl.absoluteString,
                                isRead: false,
                                isConfidential: false,
                                timestamp: Timestamp()
                            )
                            
                            self.viewModel.sendMessage(newMessage, in: self.conversation)
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
