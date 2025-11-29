//
//  ReachabilityManager.swift
//  RealtimeChatApp
//
//  Created by AMAN K.A on 29/11/25.
//

import Foundation
import SwiftUI

// MARK: - Reachability Manager
import Network

final class ReachabilityManager: ObservableObject {
    @Published var isConnected: Bool = true
    @Published var isExpensive: Bool = false
    
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.reachability.monitor", qos: .background)
    
    init() {
        monitor = NWPathMonitor()
        
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
                
                let status = path.status == .satisfied ? "Connected" : "Disconnected"
                Logger.log("Network status: \(status)", level: .info)
            }
        }
        
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
