# RealtimeChatApp

A production-style iOS chat demo built in Swift using MVVM, SwiftUI, and URLSession WebSockets. The app shows chat experience with real-time messaging, delivery status, offline queueing, and an echo bot.

## Features

- Real-time messaging over WebSocket (URLSessionWebSocketTask)
- Two demo conversations: “Support Bot” and “Sales Assistant”
- Send and receive text messages in a chat-style UI
- Message delivery state with ticks (sending, sent, delivered)
- Simulated echo bot replies for easy testing
- Offline message queue and automatic retry on reconnect
- Basic network reachability handling
- Clean MVVM architecture with Combine and async/await
- Structured debug logging for all major events

## Tech Stack

- Swift 5+
- SwiftUI
- Combine
- URLSessionWebSocketTask
- Async/await concurrency
- MVVM + repository pattern

## Running the App

1. Open `RealtimeChatApp.xcodeproj` in Xcode.
2. Select an iOS simulator (or a connected device).
3. Run with `Cmd + R`.

The app will open on the Chats screen. Tap a conversation, send a message, and watch the echo reply and status ticks.
