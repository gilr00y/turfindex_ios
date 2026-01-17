//
//  TurfLogoView.swift
//  grassy
//
//  Created by jason on 1/15/26.
//

import SwiftUI

/// Reusable Turf Index logo views in various sizes and styles
struct TurfLogoView: View {
    var size: LogoSize = .medium
    var style: LogoStyle = .full
    
    var body: some View {
        Group {
            switch style {
            case .full:
                fullLogo
            case .iconOnly:
                iconOnly
            case .minimal:
                minimalLogo
            }
        }
        .frame(width: size.dimension, height: size.dimension)
    }
    
    @ViewBuilder
    private var fullLogo: some View {
        if let _ = UIImage(named: "turf-index-logo") {
            // Use the actual logo if available
            Image("turf-index-logo")
                .resizable()
                .scaledToFit()
        } else {
            // Fallback icon with app name
            VStack(spacing: size.spacing) {
                fallbackIcon
                if size != .small {
                    Text("TURF INDEX")
                        .font(size.titleFont)
                        .fontWeight(.bold)
                        .foregroundStyle(TurfTheme.greenGradient)
                }
            }
        }
    }
    
    @ViewBuilder
    private var iconOnly: some View {
        if let _ = UIImage(named: "turf-icon") {
            Image("turf-icon")
                .resizable()
                .scaledToFit()
        } else {
            fallbackIcon
        }
    }
    
    @ViewBuilder
    private var minimalLogo: some View {
        HStack(spacing: 8) {
            if size != .small {
                fallbackIcon
                    .frame(width: size.dimension * 0.4, height: size.dimension * 0.4)
            }
            
            Text("TURF")
                .font(size.titleFont)
                .fontWeight(.bold)
                .foregroundStyle(TurfTheme.greenGradient)
            
            Text("INDEX")
                .font(size.titleFont)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
    }
    
    private var fallbackIcon: some View {
        ZStack {
            // Simplified icon based on logo elements
            Circle()
                .fill(TurfTheme.skyGradient)
                .overlay {
                    Circle()
                        .strokeBorder(TurfTheme.white, lineWidth: size.borderWidth)
                        .padding(size.borderPadding)
                }
            
            VStack(spacing: 0) {
                // Chart bars
                HStack(alignment: .bottom, spacing: size.chartSpacing) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(TurfTheme.chartGreen)
                        .frame(width: size.barWidth, height: size.dimension * 0.15)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(TurfTheme.chartLime)
                        .frame(width: size.barWidth, height: size.dimension * 0.2)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(TurfTheme.chartYellow)
                        .frame(width: size.barWidth, height: size.dimension * 0.25)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(TurfTheme.chartOrange)
                        .frame(width: size.barWidth, height: size.dimension * 0.3)
                }
                .offset(y: size.dimension * 0.1)
                
                // Golf flag
                Image(systemName: "flag.fill")
                    .font(.system(size: size.dimension * 0.15))
                    .foregroundStyle(.red)
                    .offset(x: size.dimension * 0.15, y: -size.dimension * 0.05)
            }
        }
    }
    
    enum LogoSize {
        case small      // 40pt
        case medium     // 80pt
        case large      // 120pt
        case extraLarge // 200pt
        
        var dimension: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 80
            case .large: return 120
            case .extraLarge: return 200
            }
        }
        
        var titleFont: Font {
            switch self {
            case .small: return .caption
            case .medium: return .headline
            case .large: return .title2
            case .extraLarge: return .largeTitle
            }
        }
        
        var spacing: CGFloat {
            dimension * 0.1
        }
        
        var borderWidth: CGFloat {
            switch self {
            case .small: return 1
            case .medium: return 2
            case .large: return 3
            case .extraLarge: return 4
            }
        }
        
        var borderPadding: CGFloat {
            dimension * 0.05
        }
        
        var chartSpacing: CGFloat {
            dimension * 0.02
        }
        
        var barWidth: CGFloat {
            dimension * 0.08
        }
    }
    
    enum LogoStyle {
        case full       // Full logo with image or icon + text
        case iconOnly   // Just the circular icon
        case minimal    // Simplified text-based logo
    }
}

// MARK: - Navigation Title Logo

struct NavigationLogoTitle: View {
    var body: some View {
        TurfLogoView(size: .small, style: .minimal)
    }
}

// MARK: - Previews

#Preview("All Sizes - Full") {
    VStack(spacing: 30) {
        TurfLogoView(size: .small, style: .full)
        TurfLogoView(size: .medium, style: .full)
        TurfLogoView(size: .large, style: .full)
        TurfLogoView(size: .extraLarge, style: .full)
    }
    .padding()
}

#Preview("All Styles - Medium") {
    VStack(spacing: 30) {
        TurfLogoView(size: .medium, style: .full)
        TurfLogoView(size: .medium, style: .iconOnly)
        TurfLogoView(size: .medium, style: .minimal)
    }
    .padding()
}

#Preview("Navigation Title") {
    NavigationStack {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<10) { i in
                    Text("Post \(i)")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavigationLogoTitle()
            }
        }
    }
}
