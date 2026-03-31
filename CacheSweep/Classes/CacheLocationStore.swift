//
//  CacheLocationStore.swift
//  CacheSweep
//

import Foundation

final class CacheLocationStore {
    private let defaults: UserDefaults
    private let orderStorageKey = "cache_location_order"
    private let customLocationsStorageKey = "custom_cache_locations"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func orderedLocations() -> [CacheLocation] {
        let locations = allLocations()
        guard let savedPaths = defaults.array(forKey: orderStorageKey) as? [String] else {
            return locations
        }

        let locationsByPath = Dictionary(uniqueKeysWithValues: locations.map { ($0.path, $0) })
        let savedPathSet = Set(savedPaths)

        var orderedLocations = savedPaths.compactMap { locationsByPath[$0] }
        orderedLocations.append(contentsOf: locations.filter { savedPathSet.contains($0.path) == false })

        return orderedLocations
    }

    func persistOrder(_ locations: [CacheLocation]) {
        defaults.set(locations.map(\.path), forKey: orderStorageKey)
    }

    func customLocations() -> [CacheLocation] {
        guard let data = defaults.data(forKey: customLocationsStorageKey),
              let savedLocations = try? JSONDecoder().decode([PersistedCustomLocation].self, from: data)
        else { return [] }

        return savedLocations.map {
            CacheLocation(
                path: $0.path, name: $0.name,
                description: "",
                isCritical: false, isCustom: true
            )
        }
    }

    func allLocations() -> [CacheLocation] {
        CacheLocationCatalog.builtInLocations + customLocations()
    }

    func addCustomLocation(path: String) throws -> CacheLocation {
        let fileURL = URL(fileURLWithPath: path)
        let normalizedPath = fileURL.standardizedFileURL.path
        let existingPaths = Set(allLocations().map(\.path))

        guard existingPaths.contains(normalizedPath) == false else {
            throw CacheError.duplicateLocation
        }

        let customLocation = CacheLocation(
            path: normalizedPath,
            name: fileURL.lastPathComponent,
            description: "",
            isCritical: false,
            isCustom: true
        )

        var savedCustomLocations = customLocations()
        savedCustomLocations.append(customLocation)
        persistCustomLocations(savedCustomLocations)

        return customLocation
    }

    func removeCustomLocation(path: String) {
        let normalizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        let remainingCustomLocations = customLocations().filter { $0.path != normalizedPath }
        persistCustomLocations(remainingCustomLocations)
    }

    private func persistCustomLocations(_ locations: [CacheLocation]) {
        let payload = locations.map {
            PersistedCustomLocation(path: $0.path, name: $0.name)
        }
        guard let data = try? JSONEncoder().encode(payload) else { return }
        defaults.set(data, forKey: customLocationsStorageKey)
    }
}

/// Simplified version of CacheLocation for storing custom locations with minimal metadata
private struct PersistedCustomLocation: Codable {
    let path: String
    let name: String
}
