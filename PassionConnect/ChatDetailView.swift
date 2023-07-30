//
//  ChatDetailView.swift
//  PassionConnect
//
//  Created by marhuenda joris on 30/07/2023.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ChatDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: FirestoreViewModel
    var conversation: Conversation
    @State private var newMessageText: String = ""
    @State private var isImagePickerPresented: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var selectedImageData: Data? = nil
    @State private var isUploadingImage: Bool = false
    @State private var isShowingErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack {
            HStack {
                Button("Fermer") {
                    presentationMode.wrappedValue.dismiss()
                }
                Spacer()
            }
            .padding()
            
            List {
                ForEach(conversation.messages) { message in
                    MessageRow(message: message, currentUser: viewModel.currentUser)
                        .contextMenu {
                            Button("Supprimer le message") {
                                deleteMessage(message, in: conversation)
                            }
                        }
                }
            }
            
            if conversation.isTyping {
                Text("En train de taper...")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding()
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
        .alert(isPresented: $isShowingErrorAlert, content: {
            Alert(title: Text("Erreur"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        })
    }
    
    private func sendMessage() {
        if newMessageText.isEmpty && selectedImage == nil {
            return
        }
        
        let newMessage = ChatMessage(type: selectedImage == nil ? .text : .image, senderID: viewModel.currentUser.id, receiverID: conversation.otherUserID, text: newMessageText, imageUrl: nil, isRead: false, isConfidential: false, timestamp: Timestamp())
        
        viewModel.sendMessage(newMessage, in: conversation) { error in
            if let error = error {
                errorMessage = "Erreur lors de l'envoi du message : \(error.localizedDescription)"
                isShowingErrorAlert = true
            } else {
                newMessageText = ""
            }
        }
        
        if let imageData = selectedImageData {
            uploadImageToStorage(imageData: imageData)
            selectedImageData = nil
        }
    }
    
    private func uploadImageToStorage(imageData: Data) {
        guard let conversationID = conversation.id else {
            print("Erreur : impossible d'envoyer l'image, ID de conversation manquant.")
            return
        }
        
        let imageName = UUID().uuidString
        let storageRef = Storage.storage().reference().child("images/\(imageName).jpg")
        
        isUploadingImage = true
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            self.isUploadingImage = false
            if let error = error {
                errorMessage = "Erreur lors de l'envoi de l'image : \(error.localizedDescription)"
                isShowingErrorAlert = true
            } else {
                storageRef.downloadURL { url, error in
                    guard let downloadURL = url else {
                        errorMessage = "Erreur : impossible de récupérer l'URL de téléchargement de l'image."
                        isShowingErrorAlert = true
                        return
                    }
                    let imageUrl = downloadURL.absoluteString
                    let newMessage = ChatMessage(type: .image, senderID: viewModel.currentUser.id, receiverID: conversation.otherUserID, text: nil, imageUrl: imageUrl, isRead: false, isConfidential: false, timestamp: Timestamp())
                    viewModel.sendMessage(newMessage, in: conversation) { error in
                        if let error = error {
                            errorMessage = "Erreur lors de l'envoi du message : \(error.localizedDescription)"
                            isShowingErrorAlert = true
                        }
                    }
                }
            }
        }
    }
    
    private func deleteMessage(_ message: ChatMessage, in conversation: Conversation) {
        viewModel.deleteMessage(message, in: conversation) { error in
            if let error = error {
                errorMessage = "Erreur lors de la suppression du message : \(error.localizedDescription)"
                isShowingErrorAlert = true
            }
        }
    }
}
