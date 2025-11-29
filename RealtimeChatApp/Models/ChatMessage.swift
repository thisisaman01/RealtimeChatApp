//
//  Untitled.swift
//  RealtimeChatApp
//
//  Created by AMAN K.A on 29/11/25.
//

import Foundation

// MARK: ChatMessage.swift
struct ChatMessage: Identifiable, Codable, Hashable {
    let id: String
    let conversationId: String
    let sender: String
    let content: String
    let timestamp: Date
    let isIncoming: Bool
    var deliveryStatus: DeliveryStatus = .sending
    
    enum DeliveryStatus: String, Codable, Hashable {
        case sending, sent, failed, delivered
    }
    
    enum CodingKeys: String, CodingKey {
        case id, conversationId, sender, content, timestamp, isIncoming, deliveryStatus
    }
    
    init(id: String, conversationId: String, sender: String, content: String, timestamp: Date, isIncoming: Bool, deliveryStatus: DeliveryStatus = .sending) {
        self.id = id
        self.conversationId = conversationId
        self.sender = sender
        self.content = content
        self.timestamp = timestamp
        self.isIncoming = isIncoming
        self.deliveryStatus = deliveryStatus
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.conversationId = try container.decode(String.self, forKey: .conversationId)
        self.sender = try container.decode(String.self, forKey: .sender)
        self.content = try container.decode(String.self, forKey: .content)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.isIncoming = try container.decode(Bool.self, forKey: .isIncoming)
        if let status = try? container.decode(DeliveryStatus.self, forKey: .deliveryStatus) {
            self.deliveryStatus = status
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}
