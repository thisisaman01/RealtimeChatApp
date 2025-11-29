//
//  WebSocketMessage.swift
//  RealtimeChatApp
//
//  Created by AMAN K.A on 29/11/25.
//

import Foundation

// MARK: WebSocketMessage.swift
struct WebSocketMessage: Codable {
    let type: MessageType
    let conversationId: String
    let sender: String
    let content: String?
    let timestamp: Date
    let messageId: String?
    
    enum MessageType: String, Codable {
        case text, systemMessage, typing, ack, reconnect
    }
}
