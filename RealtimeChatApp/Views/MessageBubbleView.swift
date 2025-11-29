//
//  MessageBubbleView.swift
//  RealtimeChatApp
//
//  Created by AMAN K.A on 29/11/25.
//

import Foundation
import SwiftUI

// MARK: MessageBubbleView
struct MessageBubbleView: View {
    let message: ChatMessage
    let deliveryStatus: String
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isIncoming {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding(12)
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                    
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            } else {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(message.content)
                            .padding(12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        
                        Image(systemName: deliveryStatus)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}
