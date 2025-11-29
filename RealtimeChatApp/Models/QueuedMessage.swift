//
//  QueuedMessage.swift
//  RealtimeChatApp
//
//  Created by AMAN K.A on 29/11/25.
//

import Foundation


// MARK: QueuedMessage.swift
struct QueuedMessage: Codable {
    let id: String
    let conversationId: String
    let content: String
    let timestamp: Date
    var retryCount: Int = 0
    let maxRetries: Int = 3
    
    var shouldRetry: Bool {
        retryCount < maxRetries
    }
}
