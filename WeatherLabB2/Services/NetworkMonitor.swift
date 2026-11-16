//
//  NetworkMonitor.swift
//  WeatherLabB2
//
//  Created by Abbe Fakih on 2026-11-11.
//


import Foundation
import Network
import Combine

@MainActor
final class NetworkMonitor: ObservableObject {

    @Published private(set) var isConnected = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied

            Task { @MainActor in
                self?.isConnected = connected
            }
        }

        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
