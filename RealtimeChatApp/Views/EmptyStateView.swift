//
//  EmptyStateView.swift
//  RealtimeChatApp
//
//  Created by AMAN K.A on 29/11/25.
//

import Foundation
import SwiftUI


// MARK: EmptyStateView
struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
        .environmentObject(ChatListViewModel(
            repository: ChatRepository(webSocketManager: WebSocketManager(), messageQueueService: MessageQueueService(webSocketManager: WebSocketManager(), reachabilityManager: ReachabilityManager()), reachabilityManager: ReachabilityManager()),
            messageQueueService: MessageQueueService(webSocketManager: WebSocketManager(), reachabilityManager: ReachabilityManager()),
            reachabilityManager: ReachabilityManager()
        ))
}
