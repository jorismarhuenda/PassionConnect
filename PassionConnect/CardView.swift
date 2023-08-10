//
//  CardView.swift
//  PassionConnect
//
//  Created by marhuenda joris on 10/08/2023.
//

import SwiftUI

struct CardView: View {
    let match: Match
    
    var body: some View {
        VStack {
            Image(match.profileImageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 250)
                .clipped()
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 10) {
                Text(match.name)
                    .font(.headline)
                
                Text(match.bio)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack {
                    ForEach(match.interests, id: \.self) { interest in
                        Text(interest)
                            .font(.footnote)
                            .padding(6)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        let match = Match(id: 1, name: "John Doe", bio: "Nature lover", interests: ["Hiking", "Photography"], profileImageName: "john", email: "john@example.com", profileImageURL: URL(string: "https://example.com/john.jpg"))
        CardView(match: match)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

