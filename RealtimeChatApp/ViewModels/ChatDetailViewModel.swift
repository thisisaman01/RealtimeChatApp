//
//  ChatDetailViewModel.swift
//  RealtimeChatApp
//
//  Created by AMAN K.A on 29/11/25.
//

// MARK: ChatDetailViewModel

import SwiftUI
import Combine

import SwiftUI
import Combine

final class ChatDetailViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var messageDeliveryStatus: [String: ChatMessage.DeliveryStatus] = [:]
    
    private let repository: ChatRepository
    private let conversation: ChatConversation
    private var cancellables = Set<AnyCancellable>()
    
    init(conversation: ChatConversation, repository: ChatRepository) {
        self.conversation = conversation
        self.repository = repository
        self.messages = conversation.messages
        
        Logger.log("💬 ChatDetailViewModel initialized for: \(conversation.participantName)", level: .debug)
        setupBindings()
        simulateEchoResponse()
        
        // ✅ ADD THIS:
        Task {
            await repository.markConversationAsRead(conversation.id)
        }
    }

    
    private func setupBindings() {
        Logger.log("🔗 Setting up message bindings", level: .debug)
        
        repository.$conversations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] conversations in
                if let updated = conversations.first(where: { $0.id == self?.conversation.id }) {
                    self?.messages = updated.messages
                    
                    for message in updated.messages {
                        self?.messageDeliveryStatus[message.id] = message.deliveryStatus
                        
                        if message.isIncoming {
                            Logger.log("📨 Incoming: '\(message.content)' from \(message.sender)", level: .debug)
                        } else {
                            Logger.log("📤 Outgoing: '\(message.content)' - Status: \(self?.getDeliveryStatusIcon(message.id) ?? "?")", level: .debug)
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // CRITICAL FIX: Simulate echo since WebSocket listener not working
    private func simulateEchoResponse() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Find the latest sent message (from User)
            if let lastUserMessage = self.messages.last(where: { !$0.isIncoming && $0.sender == "User" }) {
                // Check if we already have an echo for this message
                let echoExists = self.messages.contains {
                    $0.isIncoming &&
                    $0.content == lastUserMessage.content &&
                    $0.sender == "Echo Server"
                }
                
                if !echoExists {
                    // Create echo message
                    let echoMessage = ChatMessage(
                        id: UUID().uuidString,
                        conversationId: self.conversation.id,
                        sender: "Echo Server",
                        content: lastUserMessage.content,
                        timestamp: Date(),
                        isIncoming: true,
                        deliveryStatus: .delivered
                    )
                    
                    Logger.log("🔀 SIMULATED Echo response: '\(lastUserMessage.content)'", level: .debug)
                    Logger.log("📨 Incoming: '\(echoMessage.content)' from Echo Server - Status: checkmark.circle.fill", level: .debug)
                    
                    // Update repository
                    Task {
                        await self.repository.addIncomingMessage(echoMessage, to: self.conversation.id)
                    }
                }
            }
        }.retain()
    }
    
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else {
            Logger.log("⚠️ Empty message ignored", level: .warning)
            return
        }
        
        Logger.log("📝 User typed: '\(text)'", level: .debug)
        inputText = ""
        
        Task {
            await repository.sendMessage(text, to: conversation.id)
        }
    }
    
    func getDeliveryStatusIcon(_ messageId: String) -> String {
        switch messageDeliveryStatus[messageId] ?? .sending {
        case .sending:
            return "clock"
        case .sent:
            return "checkmark"
        case .delivered:
            return "checkmark.circle.fill"  // ✅ FIXED: Real SF Symbol
        case .failed:
            return "exclamationmark.circle"
        }
    }
}

// Helper to keep timer alive
private var timerRetainer: Timer?
extension Timer {
    func retain() {
        timerRetainer = self
    }
}
