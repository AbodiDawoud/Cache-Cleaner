//
//  ToastView.swift
//  CacheSweep
    

import SwiftUI

struct ToastView: View {
    let message: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0.35, green: 0.85, blue: 0.55))
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.15, green: 0.12, blue: 0.18))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        )
        .padding(.bottom, 50)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
