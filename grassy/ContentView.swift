//
//  ContentView.swift
//  grassy
//
//  Created by jason on 1/14/26.
//

import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()
    @State private var showLaunchScreen = true
    
    var body: some View {
        ZStack {
            Group {
                if appState.currentUser == nil {
                    LeaderboardView()
                } else {
                    FeedView()
                }
            }
            .environment(appState)
            
            // Launch screen overlay
            if showLaunchScreen {
                LaunchScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            // Show launch screen for 1.5 seconds
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeOut(duration: 0.5)) {
                showLaunchScreen = false
            }
        }
    }
}

#Preview {
    ContentView()
}
