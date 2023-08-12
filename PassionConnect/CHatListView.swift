//
//  CHatListView.swift
//  PassionConnect
//
//  Created by marhuenda joris on 30/07/2023.
//

import SwiftUI

struct ChatListView: View {
    @ObservedObject var viewModel: FirestoreViewModel
    
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
            .onAppear {
                viewModel.loadAllConversations()
            }
        }
    }
}
