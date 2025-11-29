//
//  ChatDetailView.swift
//  RealtimeChatApp
//
//  Created by AMAN K.A on 29/11/25.
//

import Foundation
import SwiftUI
import Combine


// MARK: ChatDetailView
struct ChatDetailView: View {
    let conversation: ChatConversation
    @EnvironmentObject var repository: ChatRepository
    @StateObject private var viewModel: ChatDetailViewModel
    @FocusState private var isInputFocused: Bool
    
    init(conversation: ChatConversation) {
        self.conversation = conversation
        // Note: Repository passed via environment
        _viewModel = StateObject(wrappedValue: ChatDetailViewModel(conversation: conversation, repository: ChatRepository(webSocketManager: WebSocketManager(), messageQueueService: MessageQueueService(webSocketManager: WebSocketManager(), reachabilityManager: ReachabilityManager()), reachabilityManager: ReachabilityManager())))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text(conversation.participantName)
                            .font(.headline)
                        Text("Online")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    Spacer()
                    Image(systemName: "info.circle")
                        .font(.title3)
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .border(Color.gray.opacity(0.2), width: 1)
            
            // Messages
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if viewModel.messages.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 48))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No messages yet")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                    } else {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message, deliveryStatus: viewModel.getDeliveryStatusIcon(message.id))
                        }
                    }
                }
                .padding()
            }
            .frame(maxHeight: .infinity)
            
            // Input Area
            VStack(spacing: 12) {
                Divider()
                
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $viewModel.inputText)
                        .textFieldStyle(.roundedBorder)
                        .focused($isInputFocused)
                    
                    Button(action: viewModel.sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                    
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
           
            }
            .background(Color(.systemBackground))
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }
}
