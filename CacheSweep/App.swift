//
//  CacheSweepApp.swift
//  CacheSweep
    

import SwiftUI

@main
struct CacheSweepApp: App {
    @AppStorage("app_appearance") var appAppearance: String?
    @State private var vm = ApplicationVM()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(vm)
                .frame(minWidth: 700, minHeight: 600)
                .preferredColorScheme(stringToColorScheme())
                .task  {
                    monitorAppearanceShortcut()
                    vm.handleAppLaunch()
                    guard let keyWindow = NSApp.keyWindow else { return }
                    keyWindow.standardWindowButton(.zoomButton)?.isHidden = true
                    keyWindow.standardWindowButton(.zoomButton)?.isEnabled = false
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
    
    // cmd + shift + a (toggle scheme)
    func monitorAppearanceShortcut() {
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            if event.modifierFlags.contains([.command, .shift]) && event.charactersIgnoringModifiers == "A" {
                self.appAppearance = self.appAppearance == "light" ? "dark" : "light"
                return nil
            }
            
            return event
        }
    }
    
    func stringToColorScheme() -> ColorScheme? {
        guard let appAppearance else { return nil }
        
        switch appAppearance.lowercased() {
        case "light": return .light
        default: return .dark
        }
    }
}
