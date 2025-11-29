//
//  MessageQueueService.swift
//  RealtimeChatApp
//
//  Created by AMAN K.A on 29/11/25.
//

import Foundation
import SwiftUI


// MARK: - Message Queue Service (CORRECTED)

import Foundation
import Combine

final class MessageQueueService: ObservableObject {
    @Published var queuedMessages: [QueuedMessage] = []
    @Published var isProcessing: Bool = false
    
    private let fileManager = FileManager.default
    private let queueDirectory: URL
    private let queueLock = NSLock()
    
    private let webSocketManager: WebSocketManager
    private let reachabilityManager: ReachabilityManager
    
    init(webSocketManager: WebSocketManager, reachabilityManager: ReachabilityManager) {
        self.webSocketManager = webSocketManager
        self.reachabilityManager = reachabilityManager
        
        // Setup queue directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.queueDirectory = documentsPath.appendingPathComponent("MessageQueue", isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: queueDirectory, withIntermediateDirectories: true)
        } catch {
            Logger.log("Failed to create queue directory: \(error)", level: .error)
        }
        
        // Restore queued messages
        restoreQueuedMessages()
        
        // Monitor network changes
        setupNetworkMonitoring()
    }
    
    // MARK: - Queue Management
    func enqueueMessage(_ message: ChatMessage, conversationId: String) throws {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        let queuedMessage = QueuedMessage(
            id: message.id,
            conversationId: conversationId,
            content: message.content,
            timestamp: Date(),
            retryCount: 0
        )
        
        queuedMessages.append(queuedMessage)
        try saveQueuedMessages()
        
        Logger.log("Message queued: \(queuedMessage.id)", level: .info)
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func processQueue() async {
        guard reachabilityManager.isConnected else {
            Logger.log("Network unavailable, skipping queue processing", level: .warning)
            return
        }
        
        guard !isProcessing else { return }
        
        DispatchQueue.main.async { self.isProcessing = true }
        defer { DispatchQueue.main.async { self.isProcessing = false } }
        
        queueLock.lock()
        let messagesToProcess = queuedMessages.filter { $0.shouldRetry }
        queueLock.unlock()
        
        Logger.log("Processing \(messagesToProcess.count) queued messages", level: .info)
        
        for (_, message) in messagesToProcess.enumerated() {
            let wsMessage = WebSocketMessage(
                type: .text,
                conversationId: message.conversationId,
                sender: "User",
                content: message.content,
                timestamp: message.timestamp,
                messageId: message.id
            )
            
            let success = await webSocketManager.send(wsMessage)
            
            if success {
                queueLock.lock()
                queuedMessages.removeAll { $0.id == message.id }
                queueLock.unlock()
                
                Logger.log("Successfully sent queued message: \(message.id)", level: .success)
            } else {
                queueLock.lock()
                if let idx = queuedMessages.firstIndex(where: { $0.id == message.id }) {
                    queuedMessages[idx].retryCount += 1
                }
                queueLock.unlock()
                
                Logger.log("Failed to send message, retry count: \(message.retryCount + 1)", level: .warning)
            }
            
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
            
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        
        try? saveQueuedMessages()
    }
    
    // MARK: - Persistence
    private func saveQueuedMessages() throws {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        try fileManager.contentsOfDirectory(at: queueDirectory, includingPropertiesForKeys: nil)
            .forEach { try fileManager.removeItem(at: $0) }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        for message in queuedMessages {
            let data = try encoder.encode(message)
            let fileURL = queueDirectory.appendingPathComponent(message.id + ".json")
            try data.write(to: fileURL, options: .atomic)
        }
        
        Logger.log("Saved \(queuedMessages.count) messages to queue", level: .debug)
    }
    
    private func restoreQueuedMessages() {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: queueDirectory, includingPropertiesForKeys: nil)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            for fileURL in files where fileURL.pathExtension == "json" {
                let data = try Data(contentsOf: fileURL)
                let message = try decoder.decode(QueuedMessage.self, from: data)
                queuedMessages.append(message)
            }
            
            Logger.log("Restored \(queuedMessages.count) queued messages", level: .info)
        } catch {
            Logger.log("Failed to restore queued messages: \(error)", level: .error)
        }
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        reachabilityManager.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                if isConnected {
                    Logger.log("Network reconnected, processing message queue", level: .success)
                    Task {
                        await self?.processQueue()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Queue Status
    func getPendingMessageCount() -> Int {
        queueLock.lock()
        defer { queueLock.unlock() }
        return queuedMessages.count
    }
    
    func clearQueue() throws {
        queueLock.lock()
        queuedMessages.removeAll()
        queueLock.unlock()
        
        try fileManager.contentsOfDirectory(at: queueDirectory, includingPropertiesForKeys: nil)
            .forEach { try fileManager.removeItem(at: $0) }
        
        Logger.log("Queue cleared", level: .info)
    }
}
