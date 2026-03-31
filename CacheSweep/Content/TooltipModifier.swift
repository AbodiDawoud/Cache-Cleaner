//
//  TooltipModifier.swift
//  CacheSweep
    

import SwiftUI

struct TooltipModifier: ViewModifier {
    let text: String
    let delay: TimeInterval
    

    @State private var showTooltip = false

    func body(content: Content) -> some View {
        content
            .onHover(perform: onMouseEnter)
            .popover(isPresented: $showTooltip) {
                Text(text)
                    .font(.callout)
                    .fontDesign(.rounded)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 12)
            }
    }

    
    func onMouseEnter(_ hovering: Bool) {
        if hovering {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                showTooltip = true
            }
        } else {
            showTooltip = false
        }
    }
}

extension View {
    func tooltip(_ text: String) -> some View {
        modifier(TooltipModifier(text: text, delay: 0.3))
    }
}
