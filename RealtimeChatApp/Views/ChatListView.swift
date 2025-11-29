//
//  ChatListView.swift
//  RealtimeChatApp
//
//  Created by AMAN K.A on 29/11/25.
//

import Foundation
import SwiftUI


// MARK: ChatListView
struct ChatListView: View {
    @EnvironmentObject var listViewModel: ChatListViewModel
    @State private var selectedConversation: ChatConversation?
    
    var body: some View {
        List(listViewModel.conversations, id: \.id, selection: $selectedConversation) { conversation in
            NavigationLink(value: conversation) {
                ChatRowView(conversation: conversation)
            }
            .tag(conversation)
        }
        .navigationTitle("Chats")
        .refreshable {
            listViewModel.refreshConversations()
        }
    }
}
