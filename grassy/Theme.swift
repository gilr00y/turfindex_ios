//
//  Theme.swift
//  grassy
//
//  Created by jason on 1/15/26.
//

import SwiftUI

/// Turf Index brand colors and theme
enum TurfTheme {
    // MARK: - Primary Colors
    
    /// Vibrant lime green (from "TURF" text)
    static let limeGreen = Color(red: 0.62, green: 0.82, blue: 0.18) // #9ED12E
    
    /// Deep forest green (from grass and text gradient)
    static let forestGreen = Color(red: 0.13, green: 0.55, blue: 0.13) // #228B22
    
    /// Bright sky blue (from sky in logo)
    static let skyBlue = Color(red: 0.29, green: 0.71, blue: 0.96) // #4AB5F5
    
    /// Warm sun orange
    static let sunOrange = Color(red: 1.0, green: 0.65, blue: 0.0) // #FFA500
    
    /// Golden yellow (from sun rays and chart)
    static let sunYellow = Color(red: 1.0, green: 0.84, blue: 0.0) // #FFD700
    
    /// Dark navy background (from logo background)
    static let navyBackground = Color(red: 0.09, green: 0.13, blue: 0.18) // #172129
    
    /// Pure white (from logo text "INDEX")
    static let white = Color.white
    
    // MARK: - Gradients
    
    /// Main brand gradient (lime to forest green)
    static let greenGradient = LinearGradient(
        colors: [limeGreen, forestGreen],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Sunrise gradient (yellow to orange)
    static let sunriseGradient = LinearGradient(
        colors: [sunYellow, sunOrange],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Sky gradient (light to vibrant blue)
    static let skyGradient = LinearGradient(
        colors: [skyBlue.opacity(0.5), skyBlue],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Semantic Colors
    
    /// Primary accent color for buttons and highlights
    static let primary = limeGreen
    
    /// Secondary accent color
    static let secondary = forestGreen
    
    /// Background for cards and surfaces
    static let cardBackground = Color(.systemBackground)
    
    /// Subtle background tint
    static let backgroundTint = limeGreen.opacity(0.05)
    
    // MARK: - Chart Colors (from logo)
    
    static let chartGreen = forestGreen
    static let chartLime = Color(red: 0.75, green: 0.87, blue: 0.27) // #BFE045
    static let chartYellow = sunYellow
    static let chartOrange = sunOrange
}

// MARK: - View Extensions

extension View {
    /// Applies the primary Turf Index gradient background
    func turfGradientBackground() -> some View {
        self.background(TurfTheme.greenGradient)
    }
    
    /// Applies a subtle tinted background
    func turfBackground() -> some View {
        self.background(TurfTheme.backgroundTint)
    }
}

// MARK: - Button Styles

struct TurfButtonStyle: ButtonStyle {
    var variant: Variant = .primary
    
    enum Variant {
        case primary
        case secondary
        case outline
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(borderColor, lineWidth: variant == .outline ? 2 : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
    
    private var background: AnyShapeStyle {
        switch variant {
        case .primary:
            return AnyShapeStyle(TurfTheme.greenGradient)
        case .secondary:
            return AnyShapeStyle(TurfTheme.secondary)
        case .outline:
            return AnyShapeStyle(Color.clear)
        }
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .primary, .secondary:
            return .white
        case .outline:
            return TurfTheme.primary
        }
    }
    
    private var borderColor: Color {
        variant == .outline ? TurfTheme.primary : .clear
    }
}

extension ButtonStyle where Self == TurfButtonStyle {
    static var turfPrimary: TurfButtonStyle {
        TurfButtonStyle(variant: .primary)
    }
    
    static var turfSecondary: TurfButtonStyle {
        TurfButtonStyle(variant: .secondary)
    }
    
    static var turfOutline: TurfButtonStyle {
        TurfButtonStyle(variant: .outline)
    }
}

// MARK: - Tag Style

struct TurfTagStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(TurfTheme.limeGreen.opacity(0.15))
            .foregroundStyle(TurfTheme.forestGreen)
            .clipShape(Capsule())
    }
}

extension View {
    func turfTagStyle() -> some View {
        modifier(TurfTagStyle())
    }
}
