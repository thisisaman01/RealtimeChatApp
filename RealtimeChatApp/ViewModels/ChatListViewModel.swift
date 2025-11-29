//
//  ChatListViewModel.swift
//  RealtimeChatApp
//
//  Created by AMAN K.A on 29/11/25.
//


import SwiftUI
import Combine

// MARK: ChatListViewModel
final class ChatListViewModel: ObservableObject {
    @Published var conversations: [ChatConversation] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var networkConnected: Bool = true
    @Published var showingQueueStatus: Bool = false
    
    private let repository: ChatRepository
    private let messageQueueService: MessageQueueService
    private let reachabilityManager: ReachabilityManager
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: ChatRepository,
         messageQueueService: MessageQueueService,
         reachabilityManager: ReachabilityManager) {
        self.repository = repository
        self.messageQueueService = messageQueueService
        self.reachabilityManager = reachabilityManager
        
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind conversations from repository
        repository.$conversations
            .receive(on: DispatchQueue.main)
            .assign(to: &$conversations)
        
        // Monitor network state
        reachabilityManager.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$networkConnected)
        
        // Monitor queue status
        messageQueueService.$isProcessing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isProcessing in
                if !isProcessing && self?.messageQueueService.queuedMessages.count ?? 0 > 0 {
                    self?.showingQueueStatus = true
                }
            }
            .store(in: &cancellables)
    }
    
    func refreshConversations() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isLoading = false
        }
    }
    
    func getPendingMessageCount() -> Int {
        messageQueueService.getPendingMessageCount()
    }
    
    func retryFailedMessages() {
        Task {
            await messageQueueService.processQueue()
        }
    }
}
