//
//  Models.swift
//  CacheSweep
    

import Foundation


struct CacheLocation: Identifiable, Equatable {
    var id: String { path }
    let path: String
    let name: String
    let description: String
    var size: Int64 = 0
    let isCritical: Bool
    var isCustom: Bool = false
}


enum CacheFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case user = "User"
    case system = "System"
    case critical = "Critical"

    var id: String { rawValue }
}


enum CacheSort: String, CaseIterable, Identifiable {
    case custom = "Custom"
    case name = "Name"
    case size = "Size"
    case critical = "Critical"

    var id: String { rawValue }
}


enum CacheError: LocalizedError {
    case pathNotFound
    case invalidOutput
    case commandFailed(String)
    case duplicateLocation
    
    var errorDescription: String? {
        switch self {
        case .pathNotFound:
            return "The specified path could not be found."
        case .invalidOutput:
            return "Failed to parse output from shell command."
        case .commandFailed(let message):
            return "Shell command failed: \(message)"
        case .duplicateLocation:
            return "That location is already in the list."
        }
    }
}
