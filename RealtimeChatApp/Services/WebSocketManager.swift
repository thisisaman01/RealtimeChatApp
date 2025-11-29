//
//  WebSocketManager.swift
//  RealtimeChatApp
//
//  Created by AMAN K.A on 29/11/25.
//

import Foundation
import SwiftUI

// MARK: - WebSocket Manager (Production-Grade)

import Foundation
import Network

actor WebSocketManager: NSObject {
    
    // MARK: - Properties
    private var webSocket: URLSessionWebSocketTask?
    private let session: URLSession
    private let url: URL
    private var isConnected: Bool = false
    private var reconnectAttempts: Int = 0
    private let maxReconnectAttempts: Int = 5
    private let reconnectDelay: TimeInterval = 2.0
    private var messageHandlers: [(String) -> Void] = []
    private var connectionStateHandler: ((Bool) -> Void)?
    
    // MARK: - Initialization
    override nonisolated init() {
        self.url = URL(string: "wss://ws.postman-echo.com/raw")!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        super.init()
    }
    
    init(url: URL) {
        self.url = url
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        super.init()
    }
    
    // MARK: - Connection Management
    func connect() {
        Task {
            await establishConnection()
        }
    }
    
    private func establishConnection() async {
        do {
            Logger.log("🔌 Attempting WebSocket connection to: \(url.absoluteString)", level: .info)
            webSocket = session.webSocketTask(with: url)
            webSocket?.resume()
            isConnected = true
            reconnectAttempts = 0
            Logger.log("✅ WebSocket connected successfully", level: .success)
            
            connectionStateHandler?(true)
            
            // Start listening for messages
            await listenForMessages()
        } catch {
            Logger.log("❌ WebSocket connection failed: \(error.localizedDescription)", level: .error)
            isConnected = false
            connectionStateHandler?(false)
            await handleConnectionFailure()
        }
    }
    
    func disconnect() {
        Task {
            await performDisconnect()
        }
    }
    
    private func performDisconnect() async {
        webSocket?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        Logger.log("🔌 WebSocket disconnected", level: .info)
    }
    
    // MARK: - Message Sending
    func send(_ message: WebSocketMessage) async -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(message)
            
            guard let jsonString = String(data: data, encoding: .utf8) else {
                Logger.log("❌ Failed to convert message to string", level: .error)
                return false
            }
            
            Logger.log("🔍 DEBUG Sending WebSocket message: \(jsonString)", level: .debug)
            
            let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
            try await webSocket?.send(wsMessage)
            
            Logger.log("✅ SUCCESS Message sent successfully", level: .success)
            return true
        } catch {
            Logger.log("❌ Failed to send message: \(error.localizedDescription)", level: .error)
            return false
        }
    }
    
    // MARK: - Message Listening (FIXED - Continuous Loop)
    private func listenForMessages() async {
        Logger.log("🔗 Starting message listener loop", level: .debug)
        
        while isConnected {
            do {
                guard let webSocket = webSocket else {
                    Logger.log("⚠️ WebSocket is nil, stopping listener", level: .warning)
                    return
                }
                
                let message = try await webSocket.receive()
                
                switch message {
                case .string(let text):
                    Logger.log("📨 RAW WebSocket string message: \(text)", level: .debug)
                    await handleReceivedMessage(text)
                    
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        Logger.log("📨 RAW WebSocket data message: \(text)", level: .debug)
                        await handleReceivedMessage(text)
                    }
                    
                @unknown default:
                    Logger.log("⚠️ Unknown message type received", level: .warning)
                }
                
                // Continue listening for next message
                // (Loop continues automatically)
                
            } catch URLError.networkConnectionLost {
                Logger.log("⚠️ Network connection lost", level: .warning)
                isConnected = false
                connectionStateHandler?(false)
                await handleConnectionFailure()
                break
                
            } catch {
                if isConnected {
                    Logger.log("❌ Error receiving message: \(error.localizedDescription)", level: .error)
                    isConnected = false
                    connectionStateHandler?(false)
                    await handleConnectionFailure()
                }
                break
            }
        }
        
        Logger.log("🔴 Message listener stopped (isConnected: \(isConnected))", level: .debug)
    }
    
    private func handleReceivedMessage(_ messageText: String) async {
        Logger.log("🔄 Processing received message, handlers count: \(messageHandlers.count)", level: .debug)
        
        for (index, handler) in messageHandlers.enumerated() {
            Logger.log("📤 Passing message to handler \(index)", level: .debug)
            handler(messageText)
        }
    }
    
    // MARK: - Error Handling & Reconnection
    private func handleConnectionFailure() async {
        isConnected = false
        connectionStateHandler?(false)
        
        guard reconnectAttempts < maxReconnectAttempts else {
            Logger.log("❌ Max reconnect attempts reached", level: .error)
            return
        }
        
        reconnectAttempts += 1
        let delay = reconnectDelay * Double(reconnectAttempts)
        
        Logger.log("⏱️ Scheduling reconnect attempt \(reconnectAttempts)/\(maxReconnectAttempts) in \(delay)s", level: .warning)
        
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        await establishConnection()
    }
    
    // MARK: - State Management
    func getConnectionState() -> Bool {
        return isConnected
    }
    
    func addMessageHandler(_ handler: @escaping (String) -> Void) async {
        messageHandlers.append(handler)
        Logger.log("✅ Message handler added, total: \(messageHandlers.count)", level: .debug)
    }
    
    func setConnectionStateHandler(_ handler: @escaping (Bool) -> Void) async {
        connectionStateHandler = handler
        Logger.log("✅ Connection state handler set", level: .debug)
    }
}
