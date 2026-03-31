//
//  StatCard.swift
//  CacheSweep
    

import SwiftUI

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(icon)
                .font(.system(size: 27))
                .foregroundStyle(color.gradient)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.15, green: 0.12, blue: 0.18))
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            ProgressiveBlurView().cornerRadius(20)
        )
    }
}

struct ProgressiveBlurView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Base material
            Rectangle()
                .fill(.ultraThinMaterial)
            
            // Progressive gradient overlay
            LinearGradient(
                stops: [
                    .init(color: .semiBlack.opacity(0.0), location: 0.0),
                    .init(color: .semiBlack.opacity(0.05), location: 0.3),
                    .init(color: .semiBlack.opacity(0.15), location: 0.6),
                    .init(color: .semiBlack.opacity(0.25), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            
            // Bottom separator with gradient
            VStack {
                Spacer()
                LinearGradient(
                    colors: [
                        Color.clear,
                        (colorScheme == .dark ? Color.white : Color.black).opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
            }
        }
    }
}
