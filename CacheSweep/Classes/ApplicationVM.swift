//
//  ApplicationVM.swift
//  CacheSweep
//

import AppKit
import Observation
import SwiftUI
import UniformTypeIdentifiers


@MainActor
@Observable
final class ApplicationVM {
    var cacheLocations: [CacheLocation] = []
    var draggedLocation: CacheLocation?
    var selectedFilter: CacheFilter = .all
    var selectedSort: CacheSort = .custom
    var isReceivingDrop = false
    var isScanning = false
    var isCleaning = false
    var showToast = false
    var toastMessage = ""
    var freedSpace: Int = 0 {
        didSet {
            UserDefaults.standard.set(freedSpace, forKey: Self.freedSpaceStorageKey)
        }
    }

    @ObservationIgnored private let controller = CacheController.shared
    @ObservationIgnored private let locationStore: CacheLocationStore
    @ObservationIgnored private let soundPlayer = SoundEffectPlayer.shared
    @ObservationIgnored private var toastDismissTask: Task<Void, Never>?

    private static let toastDurationNanoseconds: UInt64 = 3_000_000_000
    private static let freedSpaceStorageKey = "freed_space"

    init(locationStore: CacheLocationStore = CacheLocationStore()) {
        self.locationStore = locationStore
        self.freedSpace = UserDefaults.standard.integer(forKey: Self.freedSpaceStorageKey)
        self.cacheLocations = locationStore.orderedLocations()
    }

    var totalSize: Int64 {
        cacheLocations.reduce(0) { $0 + $1.size }
    }

    var filteredCacheLocations: [CacheLocation] {
        let filtered: [CacheLocation]

        switch selectedFilter {
        case .all:
            filtered = cacheLocations
        case .user:
            filtered = cacheLocations.filter { $0.path.hasPrefix(NSHomeDirectory()) }
        case .system:
            filtered = cacheLocations.filter { $0.path.hasPrefix(NSHomeDirectory()) == false }
        case .critical:
            filtered = cacheLocations.filter(\.isCritical)
        }

        switch selectedSort {
        case .custom:
            return filtered
        case .name:
            return filtered.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .size:
            return filtered.sorted {
                if $0.size == $1.size {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                return $0.size > $1.size
            }
        case .critical:
            return filtered.sorted {
                if $0.isCritical == $1.isCritical {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                return $0.isCritical && !$1.isCritical
            }
        }
    }

    func handleAppLaunch() {
        soundPlayer.play(.startup, volume: 0.75)
        scanCaches()
    }

    func scanCaches() {
        guard isScanning == false, isCleaning == false else { return }
        isScanning = true
        soundPlayer.play(.tick, volume: 0.75)

        let paths = cacheLocations.map(\.path)
        Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let results = await controller.scanPaths(paths)

            for index in cacheLocations.indices {
                let path = cacheLocations[index].path
                cacheLocations[index].size = results[path] ?? 0
            }

            isScanning = false
            soundPlayer.play(.success, volume: 0.8)
            presentToast("Scan complete! Found \(controller.byteString(totalSize))")
        }
    }

    func rescanLocation(_ location: CacheLocation) {
        Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let size = (try? await controller.calculateDirectorySize(at: location.path)) ?? 0
            guard let index = cacheLocations.firstIndex(where: { $0.path == location.path }) else { return }

            cacheLocations[index].size = size
            soundPlayer.play(.tick, volume: 0.7)
            presentToast("Rescanned \(location.name)")
        }
    }

    func performClean() {
        guard isCleaning == false, isScanning == false else { return }
        isCleaning = true
        soundPlayer.play(.tick, volume: 0.8)

        let paths = cacheLocations.map(\.path)
        Task(priority: .background) { [weak self] in
            guard let self else { return }

            let (totalFreed, errors) = await controller.cleanPaths(paths)

            if errors.isEmpty == false {
                errors.values.forEach { print($0) }
            } else {
                print("Successfully cleaned caches! \(totalFreed) bytes freed")
            }

            isCleaning = false
            freedSpace += Int(totalFreed)
            soundPlayer.play(errors.isEmpty ? .success : .failure, volume: 0.85)
            presentToast("Cleaned \(controller.byteString(totalFreed))!")
        }
    }

    func clearLocation(_ location: CacheLocation) {
        Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            do {
                let freed = try await controller.deleteDirectoryContents(at: location.path)
                let refreshedSize = (try? await controller.calculateDirectorySize(at: location.path)) ?? 0

                if let index = cacheLocations.firstIndex(where: { $0.path == location.path }) {
                    cacheLocations[index].size = refreshedSize
                }

                freedSpace += Int(freed)
                soundPlayer.play(.success, volume: 0.8)
                presentToast("Cleaned \(location.name)")
            } catch {
                soundPlayer.play(.failure, volume: 0.85)
                presentToast("Couldn’t clean \(location.name)")
            }
        }
    }

    func promptForCustomPath() {
        soundPlayer.play(.click, volume: 0.7)
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.resolvesAliases = true
        panel.prompt = "Add Path"
        panel.message = "Choose a folder to include in Cache Sweep."

        guard panel.runModal() == .OK, let selectedURL = panel.url else {
            return
        }

        do {
            let newLocation = try addCustomLocation(from: selectedURL.path)
            soundPlayer.play(.success, volume: 0.8)
            presentToast("Added \(newLocation.name)")
        } catch CacheError.duplicateLocation {
            soundPlayer.play(.failure, volume: 0.85)
            presentToast("That path is already in the list")
        } catch {
            soundPlayer.play(.failure, volume: 0.85)
            presentToast("Couldn’t add that path")
        }
    }

    @discardableResult
    func addCustomLocation(from path: String) throws -> CacheLocation {
        let newLocation = try locationStore.addCustomLocation(path: path)

        withAnimation(.snappy) {
            cacheLocations.append(newLocation)
        }
        persistOrder()

        return newLocation
    }

    func removeCustomLocation(_ location: CacheLocation) {
        guard location.isCustom else { return }

        withAnimation(.snappy) {
            cacheLocations.removeAll { $0.path == location.path }
        }
        locationStore.removeCustomLocation(path: location.path)
        persistOrder()
        soundPlayer.play(.tick, volume: 0.7)
        presentToast("Removed \(location.name)")
    }

    func handleDroppedFolders(providers: [NSItemProvider]) -> Bool {
        let fileURLType = UTType.fileURL.identifier
        let matchingProviders = providers.filter { $0.hasItemConformingToTypeIdentifier(fileURLType) }

        guard matchingProviders.isEmpty == false else {
            return false
        }

        for provider in matchingProviders {
            provider.loadDataRepresentation(forTypeIdentifier: fileURLType) { [weak self] data, _ in
                guard
                    let self,
                    let data,
                    let url = URL(dataRepresentation: data, relativeTo: nil)
                else {
                    return
                }

                Task { @MainActor [weak self] in
                    guard let self else { return }

                    do {
                        let newLocation = try addCustomLocation(from: url.path)
                        soundPlayer.play(.success, volume: 0.8)
                        presentToast("Added \(newLocation.name)")
                    } catch CacheError.duplicateLocation {
                        soundPlayer.play(.failure, volume: 0.85)
                        presentToast("That path is already in the list")
                    } catch {
                        soundPlayer.play(.failure, volume: 0.85)
                        presentToast("Couldn’t add that path")
                    }
                }
            }
        }

        return true
    }

    func moveDraggedLocation(to target: CacheLocation) {
        guard
            let draggedLocation,
            draggedLocation != target,
            let fromIndex = cacheLocations.firstIndex(of: draggedLocation),
            let toIndex = cacheLocations.firstIndex(of: target)
        else {
            return
        }

        withAnimation(.snappy) {
            cacheLocations.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }

        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        persistOrder()
    }

    func finishDragging() {
        draggedLocation = nil
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
        persistOrder()
    }

    func persistOrder() {
        locationStore.persistOrder(cacheLocations)
    }

    func byteString(_ bytes: Int64) -> String {
        controller.byteString(bytes)
    }

    func presentToast(_ message: String) {
        toastDismissTask?.cancel()
        toastMessage = message

        withAnimation {
            showToast = true
        }

        toastDismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: Self.toastDurationNanoseconds)
            guard Task.isCancelled == false else { return }

            await MainActor.run {
                guard let self else { return }
                withAnimation {
                    self.showToast = false
                }
            }
        }
    }
}
