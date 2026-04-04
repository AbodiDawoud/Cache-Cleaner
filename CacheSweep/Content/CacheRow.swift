//
//  CacheRow.swift
//  CacheSweep
    

import SwiftUI


struct CacheRowView: View {
    var location: CacheLocation
    @Environment(ApplicationVM.self) private var model
    
    @State private var showDescriptionPopover: Bool = false
    @State private var haveCopied: Bool = false
    
    var body: some View {
        HStack(spacing: 13) {
            Image(.gripHorizontal)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.secondary)
                .help("Drag to reorder")
                .onHover {
                    $0 ? NSCursor.openHand.push() : NSCursor.pop()
                }
                .onDrag {
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                    model.draggedLocation = location
                    return NSItemProvider(object: location.path as NSString)
                } preview: {
                    Color.clear.frame(width: 1, height: 1)
                }
                

            HStack(alignment: .top, spacing: 6) {
                Text(location.name)
                    .font(.system(size: 14, weight: .semibold))

                if location.isCritical {
                    Image(.badgeAlert)
                        .font(.system(size: 15))
                        .foregroundColor(Color(red: 0.95, green: 0.65, blue: 0.25))
                        .background(Color.almostClear)
                        .tooltip("This location contains system logs or diagnostics.\nCleaning it is usually safe,\nbut it can remove troubleshooting history and some data may be recreated by macOS.")
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Text(formattedBytes)
                    .font(.system(size: 13, design: .monospaced))
                    .opacity(0.8)
                
                divider
                
                if location.isCustom {
                    Button {
                        SoundEffectPlayer.shared.play(.tick)
                        model.removeCustomLocation(location)
                    } label: {
                        Image(.badgeMinus)
                            .foregroundStyle(.pink.gradient)
                            .background(Color.almostClear)
                    }
                    .pointingHandCursor()
                    .help("Remove This Custom Path")
                } else {
                    Image(.badgeHelp)
                        .foregroundStyle(.primary)
                        .background(Color.almostClear)
                        .pointingHandCursor()
                        .onTapGesture {
                            SoundEffectPlayer.shared.play(.tick)
                            showDescriptionPopover.toggle()
                        }
                        .popover(isPresented: $showDescriptionPopover) {
                            Text(location.description)
                                .font(.callout)
                                .fontDesign(.rounded)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 12)
                        }
                }
                
                divider
                
                Button(action: copyPath) {
                    Image(haveCopied ? .check : .copy)
                        .foregroundStyle(.primary)
                        .background(Color.almostClear)
                }
                .pointingHandCursor()
                .help("Copy Path")

                
                divider
                
                Button { model.clearLocation(location) } label: {
                    Image(.trash)
                        .foregroundStyle(.pink.gradient)
                        .background(Color.almostClear)
                }
                .pointingHandCursor()
                .help("Clear Path Cache")
                
                divider
                
                Button(action: revealInFinder) {
                    Image(.chevronRight)
                        .foregroundStyle(.primary)
                        .background(Color.almostClear)
                }
                .pointingHandCursor()
                .help("Reveal in Finder")
            }
            .buttonStyle(.plain)
            .fontWeight(.medium)
            .imageScale(.large)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
        )
        .contextMenu {
            Button("Re-Scan") { model.rescanLocation(location) }
            Divider()
            
            Button("Copy Path", action: copyPath)
            Button("Clear Cache", role: .destructive) { model.clearLocation(location) }

            if location.isCustom {
                Button("Remove from list", role: .destructive) { model.removeCustomLocation(location) }
            }
            
            Divider()
            Button("Reveal in Finder", action: revealInFinder)
        }
    }
    
    private var divider: some View {
        Divider().padding(.vertical, 2)
    }
    
    var formattedBytes: String {
        if location.size == 0 { return "0 KB" }
        return CacheController.shared.byteString(location.size)
    }
    
    func copyPath() {
        if haveCopied { return }
        
        SoundEffectPlayer.shared.play(.tick)
        haveCopied = true

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(location.path, forType: .string)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            haveCopied = false
        }
    }
    
    func revealInFinder() {
        SoundEffectPlayer.shared.play(.tick)
        NSWorkspace.shared.selectFile(location.path, inFileViewerRootedAtPath: "")
    }
}
