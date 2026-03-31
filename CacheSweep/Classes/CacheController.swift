//
//  CacheController.swift
//  CacheSweep
    

import Foundation


/// `CacheController` manages cache directories: scanning, cleaning, and size calculation.
/// It can perform privileged operations via shell commands using `osascript` when needed.
final class CacheController {
    static let shared = CacheController()
    
    private let fileManager = FileManager.default
    private let byteFormatter: ByteCountFormatter
    
    
    private init() {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        self.byteFormatter = formatter
    }

    

    /// Calculates the total directory size using the system `du` command for performance.
    /// Falls back to manual enumeration if the command fails.
    func calculateDirectorySize(at path: String) async throws -> Int64 {
        do {
            return try await calculateSizeWithCommand(at: path)
        } catch {
            return try calculateSizeManually(at: path)
        }
    }
    
    
    
    /// Scans multiple directories concurrently and returns their total sizes.
    func scanPaths(_ paths: [String]) async -> [String: Int64] {
        var results: [String: Int64] = [:]
        
        await withTaskGroup(of: (String, Int64).self) { group in
            for path in paths {
                group.addTask { [weak self] in
                    guard let self = self else { return (path, 0) }
                    do {
                        let size = try await self.calculateDirectorySize(at: path)
                        return (path, size)
                    } catch {
                        return (path, 0)
                    }
                }
            }
            
            for await (path, size) in group {
                results[path] = size
            }
        }
        
        return results
    }
    
    
    
    /// Deletes all contents within a given directory.
    /// If the path requires admin privileges, the system will prompt for password.
    func deleteDirectoryContents(at path: String) async throws -> Int64 {
        guard fileManager.fileExists(atPath: path) else {
            throw CacheError.pathNotFound
        }
        
        let requiresAuth = requiresAdminPrivileges(for: path)
        let sizeBeforeDeletion = try await calculateDirectorySize(at: path)
        
        let command = "rm -rf '\(path)'/*"
        _ = try await executeShellCommand(command, withAdmin: requiresAuth)
        
        return sizeBeforeDeletion
    }
    
    
    
    /// Cleans multiple paths and reports total freed space and any errors.
    func cleanPaths(_ paths: [String]) async -> (totalFreed: Int64, errors: [String: Error]) {
        var totalFreed: Int64 = 0
        var errors: [String: Error] = [:]
        
        for path in paths {
            do {
                let freed = try await deleteDirectoryContents(at: path)
                totalFreed += freed
            } catch {
                errors[path] = error
            }
        }
        
        return (totalFreed, errors)
    }
    
    
    
    /// Checks if the path exists.
    func pathExists(_ path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }
    
    
    /// Determines if a given path likely requires admin privileges to modify.
    func requiresAdminPrivileges(for path: String) -> Bool {
        let adminPaths = ["/Library", "/private/var"]
        return adminPaths.contains { path.hasPrefix($0) }
    }
    
    
    func byteString(_ bytes: Int64) -> String {
        self.byteFormatter.string(fromByteCount: bytes)
    }
}


private extension CacheController {
    
    /// Executes a shell command.
    /// - Parameters:
    ///   - command: The shell command to execute.
    ///   - withAdmin: Whether to run with administrator privileges (prompts user).
    /// - Returns: The command’s output as a string.
    func executeShellCommand(_ command: String, withAdmin: Bool = false) async throws -> String {
        let task = Process()
        let pipe = Pipe()
        
        if withAdmin {
            // Uses osascript to prompt for admin rights
            task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            task.arguments = [
                "-e",
                "do shell script \"\(command.replacingOccurrences(of: "\"", with: "\\\""))\" with administrator privileges"
            ]
        } else {
            task.executableURL = URL(fileURLWithPath: "/bin/sh")
            task.arguments = ["-c", command]
        }
        
        task.standardOutput = pipe
        task.standardError = pipe
        
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        if task.terminationStatus != 0 {
            throw CacheError.commandFailed(output)
        }
        
        return output
    }
    
    
    // Uses the `du` shell command to calculate directory size (very fast).
    func calculateSizeWithCommand(at path: String) async throws -> Int64 {
        let command = "du -sk '\(path)' 2>/dev/null | awk '{print $1}'"
        let output = try await executeShellCommand(command)
        
        if let kilobytes = Int64(output.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return kilobytes * 1024 // Convert KB to bytes
        } else {
            throw CacheError.invalidOutput
        }
    }
    
    
    // Fallback: manually enumerate all files and sum their sizes.
    func calculateSizeManually(at path: String) throws -> Int64 {
        guard fileManager.fileExists(atPath: path) else { return 0 }
        
        var totalSize: Int64 = 0
        
        if let enumerator = fileManager.enumerator(atPath: path) {
            for case let file as String in enumerator {
                let fullPath = (path as NSString).appendingPathComponent(file)
                if let attributes = try? fileManager.attributesOfItem(atPath: fullPath),
                   let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            }
        }
        
        return totalSize
    }
}


extension CacheController {
    // Test function to verify permissions
    func testPathAccess() async {
        let testPaths = [
            "/Users/mo7/Library/Caches",
            "/Library/Caches",
            "/private/var/tmp"
        ]
        
        for path in testPaths {
            let isPathAccessible = fileManager.isReadableFile(atPath: path) && fileManager.isWritableFile(atPath: path)
            
            print("Testing: \(path)")
            print("  Exists: \(pathExists(path))")
            print("  Accessible: \(isPathAccessible)")
            print("  Requires Admin: \(requiresAdminPrivileges(for: path))")
            
            do {
                let size = try await calculateDirectorySize(at: path)
                print("  Size: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))")
            } catch {
                print("  Error: \(error.localizedDescription)")
            }
            print("---")
        }
    }
}
