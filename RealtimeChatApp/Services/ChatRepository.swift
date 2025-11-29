//
//  ChatRepository.swift
//  RealtimeChatApp
//
//  Created by AMAN K.A on 29/11/25.
//

import Foundation
import SwiftUI
import Combine

final class ChatRepository: ObservableObject {
    @Published var conversations: [ChatConversation] = []
    @Published var selectedConversation: ChatConversation?
    
    private let webSocketManager: WebSocketManager
    private let messageQueueService: MessageQueueService
    private let reachabilityManager: ReachabilityManager
    private let conversationLock = NSLock()
    
    private var cancellables = Set<AnyCancellable>()
    
    init(webSocketManager: WebSocketManager,
         messageQueueService: MessageQueueService,
         reachabilityManager: ReachabilityManager) {
        self.webSocketManager = webSocketManager
        self.messageQueueService = messageQueueService
        self.reachabilityManager = reachabilityManager
        
        Logger.log("🟢 ChatRepository initialized", level: .success)
        setupInitialConversations()
        setupWebSocketHandlers()
    }
    
    // MARK: - Setup
    private func setupInitialConversations() {
        let initialConversations = [
            ChatConversation(
                id: "conv_1",
                participantName: "Support Bot",
                messages: [],
                createdAt: Date(),
                updatedAt: Date()
            ),
            ChatConversation(
                id: "conv_2",
                participantName: "Sales Assistant",
                messages: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        
        DispatchQueue.main.async {
            self.conversations = initialConversations
            Logger.log("📋 Initialized 2 conversations", level: .debug)
        }
    }
    
    // MARK: - WebSocket Setup
    private func setupWebSocketHandlers() {
        Logger.log("🔗 Setting up WebSocket handlers", level: .debug)
        
        Task {
            await webSocketManager.addMessageHandler { [weak self] messageText in
                Logger.log("📨 WebSocket message received: \(messageText)", level: .debug)
                self?.handleWebSocketMessage(messageText)
            }
            
            await webSocketManager.setConnectionStateHandler { [weak self] isConnected in
                Logger.log("🔌 WebSocket state: \(isConnected ? "✅ Connected" : "❌ Disconnected")", level: .info)
                if isConnected {
                    Task {
                        await self?.messageQueueService.processQueue()
                    }
                }
            }
        }
    }
    
    
    // MARK: - Message Receiving
    private func handleWebSocketMessage(_ messageText: String) {
        Logger.log("🔄 Processing WebSocket message...", level: .debug)
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            // Try JSON first
            if let jsonData = messageText.data(using: .utf8),
               let wsMessage = try? decoder.decode(WebSocketMessage.self, from: jsonData) {
                Logger.log("✅ Decoded JSON message from: \(wsMessage.sender)", level: .success)
                addMessageToConversation(wsMessage)
            } else {
                // Echo server sends plain text - create synthetic incoming message
                let echoMessage = WebSocketMessage(
                    type: .text,
                    conversationId: "conv_1",
                    sender: "Echo Server",
                    content: messageText.trimmingCharacters(in: .whitespaces),
                    timestamp: Date(),
                    messageId: UUID().uuidString
                )
                
                Logger.log("🔀 Echo server response: '\(messageText)'", level: .debug)
                addMessageToConversation(echoMessage)
            }
        } catch {
            Logger.log("❌ Message processing error: \(error)", level: .error)
        }
    }
    
    private func addMessageToConversation(_ wsMessage: WebSocketMessage) {
        conversationLock.lock()
        defer { conversationLock.unlock() }
        
        guard let index = conversations.firstIndex(where: { $0.id == wsMessage.conversationId }) else {
            Logger.log("⚠️ Conversation not found: \(wsMessage.conversationId)", level: .warning)
            return
        }
        
        let chatMessage = ChatMessage(
            id: wsMessage.messageId ?? UUID().uuidString,
            conversationId: wsMessage.conversationId,
            sender: wsMessage.sender,
            content: wsMessage.content ?? "",
            timestamp: wsMessage.timestamp,
            isIncoming: true,
            deliveryStatus: .delivered
        )
        
        DispatchQueue.main.async { [weak self] in
            guard var conv = self?.conversations[index] else { return }
            conv.messages.append(chatMessage)
            conv.updatedAt = Date()
            conv.unreadCount += 1  // ✅ INCREMENT UNREAD
            self?.conversations[index] = conv
            
            Logger.log("📊 UNREAD COUNT NOW: \(conv.unreadCount)", level: .success)
            Logger.log("✅ Message added + unread updated", level: .success)
        }
    }
    
    // ✅ SINGLE DEFINITION - NOT DUPLICATE
    func addIncomingMessage(_ message: ChatMessage, to conversationId: String) async {
        conversationLock.lock()
        
        Logger.log("📨 addIncomingMessage called for: \(conversationId)", level: .debug)
        
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }) else {
            conversationLock.unlock()
            Logger.log("❌ Conversation NOT FOUND", level: .error)
            return
        }
        
        let oldCount = conversations[index].unreadCount
        Logger.log("📊 BEFORE: unreadCount = \(oldCount)", level: .debug)
        
        conversations[index].messages.append(message)
        conversations[index].unreadCount += 1
        conversations[index].updatedAt = Date()
        
        let newCount = conversations[index].unreadCount
        Logger.log("📊 AFTER: unreadCount = \(newCount)", level: .debug)
        
        conversationLock.unlock()
        
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
            Logger.log("🔔 UI Updated", level: .debug)
        }
    }
    
    // ✅ SINGLE DEFINITION - NO DUPLICATE
    func markConversationAsRead(_ conversationId: String) async {
        Logger.log("🔓 Marking as read: \(conversationId)", level: .debug)
        
        conversationLock.lock()
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }) else {
            conversationLock.unlock()
            Logger.log("❌ Not found to mark read", level: .error)
            return
        }
        
        let beforeCount = conversations[index].unreadCount
        conversations[index].unreadCount = 0
        conversationLock.unlock()
        
        Logger.log("📊 Unread: \(beforeCount) → 0", level: .debug)
        
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
            Logger.log("🔔 Badge cleared", level: .debug)
        }
    }
    
    // MARK: - Sending Messages
    func sendMessage(_ content: String, to conversationId: String) async {
        let messageId = UUID().uuidString
        let message = ChatMessage(
            id: messageId,
            conversationId: conversationId,
            sender: "User",
            content: content,
            timestamp: Date(),
            isIncoming: false,
            deliveryStatus: .sending
        )
        
        Logger.log("📤 Sending message: '\(content)' with ID: \(messageId)", level: .info)
        
        // Add to local conversation immediately
        conversationLock.lock()
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }) else {
            conversationLock.unlock()
            Logger.log("❌ Cannot send: Conversation not found: \(conversationId)", level: .error)
            return
        }
        conversations[index].messages.append(message)
        conversationLock.unlock()
        
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
            Logger.log("🔵 Message added locally with .sending status", level: .debug)
        }
        
        // Try to send via WebSocket
        let wsMessage = WebSocketMessage(
            type: .text,
            conversationId: conversationId,
            sender: "User",
            content: content,
            timestamp: Date(),
            messageId: messageId
        )
        
        let success = await webSocketManager.send(wsMessage)
        
        // Update delivery status
        conversationLock.lock()
        if let msgIndex = conversations[index].messages.firstIndex(where: { $0.id == messageId }) {
            if success {
                conversations[index].messages[msgIndex].deliveryStatus = .sent
                Logger.log("✅ Message sent successfully: \(messageId)", level: .success)
                
                // Automatically update to delivered after 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.conversationLock.lock()
                    if let finalIndex = self?.conversations[index].messages.firstIndex(where: { $0.id == messageId }) {
                        self?.conversations[index].messages[finalIndex].deliveryStatus = .delivered
                        Logger.log("✅ Message marked as delivered: \(messageId)", level: .success)
                        self?.objectWillChange.send()
                    }
                    self?.conversationLock.unlock()
                }
            } else {
                conversations[index].messages[msgIndex].deliveryStatus = .failed
                Logger.log("❌ Message failed to send, queuing: \(messageId)", level: .warning)
                
                do {
                    try messageQueueService.enqueueMessage(message, conversationId: conversationId)
                    Logger.log("📋 Message queued for retry: \(messageId)", level: .info)
                } catch {
                    Logger.log("❌ Failed to queue message: \(error)", level: .error)
                }
            }
        }
        conversationLock.unlock()
        
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }
}

