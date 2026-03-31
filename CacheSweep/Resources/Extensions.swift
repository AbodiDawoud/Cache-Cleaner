//
//  Extensions.swift
//  CacheSweep
    

import SwiftUI


extension NSColor {
    var color: Color {
        Color(nsColor: self)
    }
}

extension Color {
    static var almostClear: Color {
        Color.white.opacity(0.001)
    }
}

extension View {
    func pointingHandCursor() -> some View {
        self.onHover {
            $0 ? NSCursor.pointingHand.push() : NSCursor.pop()
        }
    }
}
