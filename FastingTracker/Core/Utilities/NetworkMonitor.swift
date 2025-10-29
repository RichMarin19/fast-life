//
// NetworkMonitor.swift
// FastingTracker
//
// Created for Phase 6: LLM Intelligence Integration
// Monitor network connectivity for hybrid LLM routing
// Industry Pattern: Graceful degradation (online → LLM, offline → rule-based)
//

import Foundation
import Network
import os.log

/// Monitor network connectivity for hybrid LLM routing
/// **Architecture:** Observe network changes, route queries appropriately
/// **Offline Behavior:** Fall back to rule-based system with user notice
class NetworkMonitor: ObservableObject {

    // MARK: - Singleton

    static let shared = NetworkMonitor()

    // MARK: - Properties

    @Published private(set) var isConnected: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.fastlife.FastLIFe.NetworkMonitor")
    private let logger = Logger(subsystem: "com.fastlife.FastLIFe", category: "Network")

    // MARK: - Initialization

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let newStatus = (path.status == .satisfied)
                self?.isConnected = newStatus
                self?.logger.info("Network status changed: \(newStatus ? "connected" : "disconnected", privacy: .public)")
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
