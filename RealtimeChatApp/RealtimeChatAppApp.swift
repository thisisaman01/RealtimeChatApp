//
//  RealtimeChatAppApp.swift
//  RealtimeChatApp
//
//  Created by AMAN K.A on 29/11/25.
//

//import SwiftUI
//
//@main
//struct RealtimeChatAppApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}

import SwiftUI

@main
struct RealtimeChatApp: App {
    @StateObject private var reachabilityManager = ReachabilityManager()
    @StateObject private var webSocketManager: WebSocketManagerWrapper
    @StateObject private var messageQueueService: MessageQueueService
    @StateObject private var repository: ChatRepository
    @StateObject private var listViewModel: ChatListViewModel
    
    init() {
        let wsManager = WebSocketManager(url: URL(string: "wss://ws.postman-echo.com/raw")!)
        _webSocketManager = StateObject(wrappedValue: WebSocketManagerWrapper(wsManager))
        
        let reachability = ReachabilityManager()
        _reachabilityManager = StateObject(wrappedValue: reachability)
        
        let queueService = MessageQueueService(webSocketManager: wsManager, reachabilityManager: reachability)
        _messageQueueService = StateObject(wrappedValue: queueService)
        
        let chatRepository = ChatRepository(
            webSocketManager: wsManager,
            messageQueueService: queueService,
            reachabilityManager: reachability
        )
        _repository = StateObject(wrappedValue: chatRepository)
        
        let listVM = ChatListViewModel(
            repository: chatRepository,
            messageQueueService: queueService,
            reachabilityManager: reachability
        )
        _listViewModel = StateObject(wrappedValue: listVM)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(reachabilityManager)
                .environmentObject(messageQueueService)
                .environmentObject(repository)
                .environmentObject(listViewModel)
                .onAppear {
                    Task {
                        await webSocketManager.manager.connect()
                    }
                }
        }
    }
}

class WebSocketManagerWrapper: ObservableObject {
    let manager: WebSocketManager
    
    init(_ manager: WebSocketManager) {
        self.manager = manager
    }
}
