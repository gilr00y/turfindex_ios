//
//  ThemeExamples.swift
//  grassy
//
//  Created by jason on 1/15/26.
//

import SwiftUI

/// Example usage of TurfTheme components - for reference
struct ThemeExamples: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // MARK: - Colors
                
                Group {
                    Text("Brand Colors")
                        .font(.title2.bold())
                    
                    HStack(spacing: 10) {
                        ColorSwatch(color: TurfTheme.limeGreen, name: "Lime")
                        ColorSwatch(color: TurfTheme.forestGreen, name: "Forest")
                        ColorSwatch(color: TurfTheme.skyBlue, name: "Sky")
                        ColorSwatch(color: TurfTheme.sunOrange, name: "Orange")
                        ColorSwatch(color: TurfTheme.sunYellow, name: "Yellow")
                    }
                }
                
                Divider()
                
                // MARK: - Buttons
                
                Group {
                    Text("Button Styles")
                        .font(.title2.bold())
                    
                    Button("Primary Button") {}
                        .buttonStyle(.turfPrimary)
                    
                    Button("Secondary Button") {}
                        .buttonStyle(.turfSecondary)
                    
                    Button("Outline Button") {}
                        .buttonStyle(.turfOutline)
                }
                .padding(.horizontal)
                
                Divider()
                
                // MARK: - Tags
                
                Group {
                    Text("Tag Styles")
                        .font(.title2.bold())
                    
                    HStack {
                        Text("#golf")
                            .turfTagStyle()
                        
                        Text("#turf")
                            .turfTagStyle()
                        
                        Text("#scorecard")
                            .turfTagStyle()
                    }
                }
                
                Divider()
                
                // MARK: - Gradients
                
                Group {
                    Text("Gradients")
                        .font(.title2.bold())
                    
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(TurfTheme.greenGradient)
                            .frame(height: 80)
                            .overlay {
                                Text("Green")
                                    .foregroundStyle(.white)
                                    .bold()
                            }
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(TurfTheme.sunriseGradient)
                            .frame(height: 80)
                            .overlay {
                                Text("Sunrise")
                                    .foregroundStyle(.white)
                                    .bold()
                            }
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(TurfTheme.skyGradient)
                            .frame(height: 80)
                            .overlay {
                                Text("Sky")
                                    .foregroundStyle(.white)
                                    .bold()
                            }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // MARK: - Icons with Theme
                
                Group {
                    Text("Themed Icons")
                        .font(.title2.bold())
                    
                    HStack(spacing: 30) {
                        Image(systemName: "figure.golf")
                            .font(.system(size: 40))
                            .foregroundStyle(TurfTheme.greenGradient)
                        
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(TurfTheme.sunriseGradient)
                        
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 40))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(TurfTheme.limeGreen, TurfTheme.forestGreen)
                        
                        Image(systemName: "flag.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(TurfTheme.primary)
                    }
                }
                
                Divider()
                
                // MARK: - Cards
                
                Group {
                    Text("Themed Cards")
                        .font(.title2.bold())
                    
                    // Simple card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "figure.golf")
                                .foregroundStyle(TurfTheme.primary)
                            Text("Golf Stats Card")
                                .font(.headline)
                        }
                        
                        Text("Par: 72 • Score: 68 • -4")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Text("#personal-best")
                                .turfTagStyle()
                            Text("#championship")
                                .turfTagStyle()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(TurfTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 8)
                    
                    // Gradient header card
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.title)
                            Text("Performance")
                                .font(.title2.bold())
                            Spacer()
                        }
                        .padding()
                        .foregroundStyle(.white)
                        .turfGradientBackground()
                        
                        // Content
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Rounds Played: 24")
                            Text("Average Score: 76")
                            Text("Best Score: 68")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(TurfTheme.cardBackground)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 10)
                }
                .padding(.horizontal)
                
                Divider()
                
                // MARK: - Usage Tips
                
                Group {
                    Text("Quick Reference")
                        .font(.title2.bold())
                    
                    VStack(alignment: .leading, spacing: 12) {
                        UsageTip(
                            code: ".buttonStyle(.turfPrimary)",
                            description: "Main action buttons"
                        )
                        
                        UsageTip(
                            code: ".foregroundStyle(TurfTheme.primary)",
                            description: "Accent color for icons/text"
                        )
                        
                        UsageTip(
                            code: ".turfTagStyle()",
                            description: "Consistent tag appearance"
                        )
                        
                        UsageTip(
                            code: ".turfGradientBackground()",
                            description: "Apply brand gradient to any view"
                        )
                    }
                    .padding()
                    .background(TurfTheme.backgroundTint)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Theme Examples")
    }
}

// MARK: - Helper Views

struct ColorSwatch: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 50, height: 50)
                .shadow(radius: 2)
            
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct UsageTip: View {
    let code: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(code)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(TurfTheme.forestGreen)
            
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ThemeExamples()
    }
}
