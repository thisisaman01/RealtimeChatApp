//
//  ContentView.swift
//  RealtimeChatApp
//
//  Created by AMAN K.A on 29/11/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var listViewModel: ChatListViewModel
    @EnvironmentObject var repository: ChatRepository
    @State private var selectedConversation: ChatConversation?
    
    var body: some View {
        ZStack {
            if listViewModel.conversations.isEmpty {
                EmptyStateView(
                    title: "No Conversations",
                    message: "Start by connecting to the real-time service",
                    icon: "bubble.left"
                )
            } else {
                NavigationSplitView {
                    // MARK: Sidebar - Conversation List
                    List(listViewModel.conversations, id: \.id, selection: $selectedConversation) { conversation in
                        NavigationLink(value: conversation) {
                            ChatRowView(conversation: conversation)
                        }
                    }
                    .navigationTitle("Chats")
                } detail: {
                    // MARK: Detail - Chat View
                    if let selectedConv = selectedConversation {
                        ChatDetailView(conversation: selectedConv)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 48))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("Select a conversation")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                // NO onAppear - let user manually select a conversation
            }
            
            // Network status indicator
            VStack {
                if !listViewModel.networkConnected {
                    HStack {
                        Image(systemName: "wifi.slash")
                        Text("No Internet Connection")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                    .padding()
                }
                
                if listViewModel.getPendingMessageCount() > 0 {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text("\(listViewModel.getPendingMessageCount()) message(s) pending...")
                            .font(.caption)
                        
                        Button(action: {
                            listViewModel.retryFailedMessages()
                        }) {
                            Text("Retry")
                                .font(.caption.weight(.semibold))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
                    .padding()
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
