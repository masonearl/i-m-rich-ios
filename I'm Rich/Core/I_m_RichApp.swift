//
//  I_m_RichApp.swift
//  I'm Rich
//
//  Created by Mason Earl on 10/26/25.
//

import SwiftUI
import GameKit

@main
struct I_m_RichApp: App {
    @StateObject private var gameCenter = GameCenterManager.shared
    
    init() {
        // Authenticate Game Center on launch
        GameCenterManager.shared.authenticatePlayer()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameCenter)
        }
    }
}
