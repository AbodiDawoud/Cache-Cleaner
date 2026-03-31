//
//  ContentView.swift
//  CacheSweep
//

import SwiftUI
import UniformTypeIdentifiers


struct ContentView: View {
    @Environment(ApplicationVM.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var filterSelectionAnimation

    var body: some View {
        @Bindable var model = model

        ZStack(alignment: .bottom) {
            Color.semiBlack.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    statsSection
                    listSection
                }
                .padding(.horizontal, 30)
                .padding(.top, 70)
                .padding(.bottom, 98)
            }

            VStack {
                customTitleBar
                Spacer()
            }

            bottomActionButtons

            if model.showToast {
                ToastView(message: model.toastMessage)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: model.showToast)
            }
        }
        .blur(radius: model.isReceivingDrop ? 50 : 0)
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $model.isReceivingDrop, perform: model.handleDroppedFolders)
        .overlay {
            if model.isReceivingDrop {
                DropOverlayView()
            }
        }
    }

    var customTitleBar: some View {
        HStack {
            Image(nsImage: .init(named: NSImage.applicationIconName)!)
                .resizable()
                .scaledToFit()
                .frame(width: 35, height: 35)
            Text("Cache Sweep")
                .font(.system(size: 20, weight: .bold, design: .rounded))

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 25)
        .background(
            Color.semiBlack
                .ignoresSafeArea()
                .mask(alignment: .top) {
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .black.opacity(1.0), location: 0.50),
                            .init(color: .black.opacity(0.95), location: 0.7),
                            .init(color: .black.opacity(0.6), location: 0.85),
                            .init(color: .black.opacity(0.0), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
        )
    }

    var statsSection: some View {
        HStack(spacing: 16) {
            StatCardView(
                title: "Total Cache",
                value: model.byteString(model.totalSize),
                icon: "database",
                color: .indigo
            )

            StatCardView(
                title: "Total Cleaned",
                value: model.byteString(Int64(model.freedSpace)),
                icon: "circle-check-big",
                color: .seaFoam
            )

            StatCardView(
                title: "Locations",
                value: "\(model.cacheLocations.count)",
                icon: "folder-tree",
                color: .teal
            )
        }
    }

    var listSection: some View {
        VStack(spacing: 11) {
            Text("Known Locations")
                .font(.system(size: 14.5, weight: .semibold))
                .foregroundStyle(.gray)
                .padding(.bottom, 3)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                filterBar
                Spacer()
                addPathButton
                sortMenu
            }

            VStack(spacing: 10) {
                ForEach(model.filteredCacheLocations) { location in
                    CacheRowView(location: location)
                        .onDrop(
                            of: [UTType.plainText.identifier],
                            delegate: DragDropDelegate(target: location, model: model)
                        )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
            }
        }
    }

    var addPathButton: some View {
        Button(action: model.promptForCustomPath) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                Text("Add Path")
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05))
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.10), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
        .help("Add a custom folder to scan and clean")
    }

    var filterBar: some View {
        HStack(spacing: 10) {
            ForEach(CacheFilter.allCases) { filter in
                Button {
                    withAnimation(.snappy) {
                        SoundEffectPlayer.shared.play(.click, volume: 0.55)
                        model.selectedFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(model.selectedFilter == filter ? colorScheme == .dark ? .black : .white : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            ZStack {
                                Capsule(style: .continuous)
                                    .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.10), lineWidth: 1)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05))

                                if model.selectedFilter == filter {
                                    Capsule(style: .continuous)
                                        .fill(colorScheme == .dark ? .white : Color(red: 0.12, green: 0.12, blue: 0.14))
                                        .matchedGeometryEffect(id: "selectedFilterCapsule", in: filterSelectionAnimation)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }
        }
        .padding(.vertical, 2)
    }

    var sortMenu: some View {
        @Bindable var model = model

        return Menu {
            Picker("Sort By", selection: $model.selectedSort.animation()) {
                ForEach(CacheSort.allCases) { sort in
                    Text(sort.rawValue).tag(sort)
                }
            }
            .pickerStyle(.inline)
        } label: {
            HStack(spacing: 8) {
                Text("Sort by")
                    .font(.system(size: 13, weight: .semibold))
                Text(model.selectedSort.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05))
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.10), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .fixedSize()
        .pointingHandCursor()
    }

    var bottomActionButtons: some View {
        HStack(spacing: 12) {
            Button(action: model.scanCaches) {
                HStack {
                    if model.isScanning {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }

                    Text(model.isScanning ? "Scanning..." : "Scan")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .font(.system(size: 14, weight: .semibold))
                .background(.thinMaterial, in: .capsule)
                .overlay {
                    Capsule().stroke(.quaternary, lineWidth: 1)
                }
            }
            .disabled(model.isScanning || model.isCleaning)

            Button(action: model.performClean) {
                HStack {
                    if model.isCleaning {
                        ProgressView().controlSize(.small)
                    }

                    Text(model.isCleaning ? "Cleaning..." : "Clean All")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.background)
                .background(colorScheme == .light ? .black : .white, in: .capsule)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 25)
        .buttonStyle(.plain)
        .pointingHandCursor()
        .background {
            Color.semiBlack
                .mask(alignment: .top) {
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .black.opacity(0.2), location: 0.2),
                            .init(color: .black.opacity(0.4), location: 0.4),
                            .init(color: .black.opacity(0.92), location: 0.6),
                            .init(color: .black.opacity(0.96), location: 0.8),
                            .init(color: .black.opacity(1.0), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .frame(height: 150)
        }
    }
}
