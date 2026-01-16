//
//  ContentView.swift
//  grassy
//
//  Created by jason on 1/14/26.
//

import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()
    
    var body: some View {
        Group {
            if appState.currentUser == nil {
                OnboardingView()
            } else {
                FeedView()
            }
        }
        .environment(appState)
    }
}

#Preview {
    ContentView()
}
