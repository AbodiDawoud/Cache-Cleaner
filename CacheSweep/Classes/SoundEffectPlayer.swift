//
//  SoundEffectPlayer.swift
//  CacheSweep
//

import AppKit
import Foundation


@MainActor
final class SoundEffectPlayer {
    static let shared = SoundEffectPlayer()

    private var sounds: [SoundEffect: NSSound] = [:]

    private init(bundle: Bundle = .main) {
        for effect in SoundEffect.allCases {
            if let sound = Self.loadSound(effect, bundle: bundle) {
                sounds[effect] = sound
            }
        }
    }

    func play(_ effect: SoundEffect, volume: Float = 1.0) {
        let sound = sounds[effect]!

        if sound.isPlaying {
            sound.stop()
        }

        sound.volume = volume
        sound.play()
    }

    private static func loadSound(_ effect: SoundEffect, bundle: Bundle) -> NSSound? {
        let url =
            bundle.url(forResource: effect.rawValue, withExtension: effect.fileExtension, subdirectory: "SoundEffects")
            ?? bundle.url(forResource: effect.rawValue, withExtension: effect.fileExtension)

        guard let url else { return nil }
        return NSSound(contentsOf: url, byReference: false)
    }
}

enum SoundEffect: String, CaseIterable {
    case click = "01_click"
    case tick = "02_tick"
    case success = "03_success"
    case failure = "04_failure"
    case startup = "05_startup"

    var fileExtension: String { "wav" }
}
