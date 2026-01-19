//
//  LaunchScreenView.swift
//  grassy
//
//  Created by jason on 1/18/26.
//

import SwiftUI

/// Launch screen that displays on app startup
struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // Dark navy background
            TurfTheme.navyBackground
                .ignoresSafeArea()
            
            // Turf Index logo (no background version)
            Image("turf-index-no-bg")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
        }
    }
}

#Preview {
    LaunchScreenView()
}
