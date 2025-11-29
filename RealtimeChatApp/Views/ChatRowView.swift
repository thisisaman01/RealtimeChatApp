//
//  ChatRowView.swift
//  RealtimeChatApp
//
//  Created by AMAN K.A on 29/11/25.
//

import Foundation
import SwiftUI

// MARK: ChatRowView
// MARK: ChatRowView
struct ChatRowView: View {
    let conversation: ChatConversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(conversation.participantName)
                            .font(.headline.weight(.semibold))
                        
                        if conversation.isUnread {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(conversation.lastMessagePreview)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(conversation.updatedAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }


                }
            }
        }
        .padding(.vertical, 8)
    }
}
