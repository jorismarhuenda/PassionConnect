//
//  MessageRow.swift
//  PassionConnect
//
//  Created by marhuenda joris on 12/08/2023.
//

import SwiftUI

struct MessageRow: View {
    var message: ChatMessage
    var currentUser: User
    
    var body: some View {
        HStack {
            if message.senderID == currentUser.id.uuidString {
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
