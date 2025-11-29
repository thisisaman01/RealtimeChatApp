//
//  ChatConversation.swift
//  RealtimeChatApp
//
//  Created by AMAN K.A on 29/11/25.
//

import Foundation

// MARK: ChatConversation.swift
struct ChatConversation: Identifiable, Codable, Hashable, Equatable {
    let id: String
    let participantName: String
    var messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date
    var unreadCount: Int = 0
    
    var lastMessage: ChatMessage? {
        messages.last
    }
    
    var lastMessagePreview: String {
        guard let last = lastMessage else { return "No messages" }
        return last.content.count > 50 ? String(last.content.prefix(50)) + "..." : last.content
    }
    
    var isUnread: Bool {
        unreadCount > 0
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ChatConversation, rhs: ChatConversation) -> Bool {
        lhs.id == rhs.id && lhs.updatedAt == rhs.updatedAt
    }
}
