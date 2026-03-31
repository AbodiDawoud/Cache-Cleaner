//
//  DropOverlayView.swift
//  CacheSweep
    

import SwiftUI

struct DropOverlayView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.65 : 0.2), style: StrokeStyle(lineWidth: 2, dash: [10, 8]))
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.55))
            )
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 32, weight: .semibold))
                    Text("Drop Folders to Add Them")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("Dropped folders become custom cleanup paths.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .allowsHitTesting(false)
            .transition(.opacity)
    }
}
