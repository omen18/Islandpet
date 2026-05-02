//
//  HapticsService.swift
//  IslandPet
//
//  CoreHaptics-backed haptic score. Falls back gracefully to UIKit
//  generators on devices without the haptic engine (none of these exist
//  in iOS 17+, but the fallback keeps the simulator quiet).
//
//  Philosophy: haptics are part of the UI, not a sprinkle. Every named
//  beat in the app maps to one named pattern here, and every pattern is
//  designed in pairs (intensity + sharpness curves). If you want to add
//  a new haptic, add it as a *named beat*, not an inline call.
//
//  Reference: WWDC 2019 "Designing Audio-Haptic Experiences"
//

import UIKit
import CoreHaptics

@MainActor
final class HapticsService {
    static let shared = HapticsService()

    private var engine: CHHapticEngine?
    private var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    private init() {
        prepareEngine()
    }

    // MARK: - Public beats

    /// Tiny tap. Buttons, toggles, list selections.
    func tap()        { play(.tap) }

    /// Firmer bump. Tab switch, sheet present, primary action confirmation.
    func bump()       { play(.bump) }

    /// Heavy thunk. Something locked-in (start focus, evolution beat 1).
    func thunk()      { play(.thunk) }

    /// Two-stage success. Ascending pair, ends sharp.
    func success()    { play(.success) }

    /// Friendly warning. Single soft pulse, no alarm.
    func warning()    { play(.warning) }

    /// Streak save / freeze used. Crystalline, cool.
    func streakSave() { play(.streakSave) }

    /// Level up. Three ascending taps with rising sharpness.
    func levelUp()    { play(.levelUp) }

    /// Evolution. The big one. Six-beat chord with anticipation, hit, settle.
    /// ~1.6s long; pair with EvolutionCinematicView.
    func evolve()     { play(.evolve) }

    /// Pet-tap reaction. Soft, organic, like poking a creature.
    func petPoke()    { play(.petPoke) }

    /// Heartbeat (used during focus session ambient feedback).
    /// Stops with `stopHeartbeat()`.
    func startHeartbeat() {
        stopHeartbeat()
        guard supportsHaptics, let engine else { return }
        do {
            heartbeatPlayer = try engine.makeAdvancedPlayer(
                with: try CHHapticPattern(events: Beat.heartbeat.events,
                                          parameters: [])
            )
            heartbeatPlayer?.loopEnabled = true
            try heartbeatPlayer?.start(atTime: 0)
        } catch {
            heartbeatPlayer = nil
        }
    }
    func stopHeartbeat() {
        try? heartbeatPlayer?.stop(atTime: 0)
        heartbeatPlayer = nil
    }

    /// Compatibility shim — old call sites used `celebrate()`.
    func celebrate() { play(.evolve) }

    // MARK: - Engine

    private var heartbeatPlayer: CHHapticAdvancedPatternPlayer?

    private func prepareEngine() {
        guard supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.playsHapticsOnly = true
            engine?.isAutoShutdownEnabled = true
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            engine?.stoppedHandler = { _ in /* no-op */ }
            try engine?.start()
        } catch {
            engine = nil
        }
    }

    private func play(_ beat: Beat) {
        if !supportsHaptics {
            beat.uikitFallback()
            return
        }
        guard let engine else { return }
        do {
            let pattern = try CHHapticPattern(events: beat.events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try engine.start()
            try player.start(atTime: 0)
        } catch {
            beat.uikitFallback()
        }
    }
}

// MARK: - Beat catalog
// Each beat is a list of CHHapticEvent. Designed to read like a score.

private enum Beat {
    case tap, bump, thunk, success, warning, streakSave, levelUp, evolve,
         petPoke, heartbeat

    var events: [CHHapticEvent] {
        switch self {
        case .tap:
            return [
                .transient(t: 0.0, intensity: 0.55, sharpness: 0.5)
            ]
        case .bump:
            return [
                .transient(t: 0.0, intensity: 0.85, sharpness: 0.7)
            ]
        case .thunk:
            return [
                .transient(t: 0.0, intensity: 1.0, sharpness: 0.3),
                .transient(t: 0.04, intensity: 0.7, sharpness: 0.2)
            ]
        case .success:
            return [
                .transient(t: 0.0,  intensity: 0.7, sharpness: 0.5),
                .transient(t: 0.13, intensity: 1.0, sharpness: 0.9)
            ]
        case .warning:
            return [
                .continuous(t: 0.0, duration: 0.12, intensity: 0.6, sharpness: 0.3)
            ]
        case .streakSave:
            // Crystalline — high sharpness, light intensity, three quick chimes
            return [
                .transient(t: 0.0,  intensity: 0.45, sharpness: 1.0),
                .transient(t: 0.07, intensity: 0.55, sharpness: 1.0),
                .transient(t: 0.16, intensity: 0.7,  sharpness: 0.95)
            ]
        case .levelUp:
            return [
                .transient(t: 0.0,  intensity: 0.65, sharpness: 0.55),
                .transient(t: 0.10, intensity: 0.80, sharpness: 0.70),
                .transient(t: 0.22, intensity: 1.0,  sharpness: 0.85)
            ]
        case .evolve:
            // 6-beat chord: anticipation (3 building taps) → hit → 2 settle pulses
            return [
                .transient(t: 0.00, intensity: 0.35, sharpness: 0.3),
                .transient(t: 0.18, intensity: 0.50, sharpness: 0.4),
                .transient(t: 0.34, intensity: 0.70, sharpness: 0.5),
                .transient(t: 0.52, intensity: 1.00, sharpness: 1.0),    // HIT
                .continuous(t: 0.55, duration: 0.40, intensity: 0.7, sharpness: 0.6),
                .transient(t: 1.05, intensity: 0.50, sharpness: 0.4)
            ]
        case .petPoke:
            // Soft, organic, slightly squishy
            return [
                .continuous(t: 0.0, duration: 0.08, intensity: 0.5, sharpness: 0.15),
                .transient(t: 0.09, intensity: 0.4, sharpness: 0.3)
            ]
        case .heartbeat:
            // lub-dub, repeats
            return [
                .transient(t: 0.0,  intensity: 0.8, sharpness: 0.3),
                .transient(t: 0.16, intensity: 0.55, sharpness: 0.25)
            ]
        }
    }

    /// What to do on devices without CoreHaptics.
    func uikitFallback() {
        switch self {
        case .tap:        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .bump:       UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .thunk:      UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:    UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:    UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .streakSave: UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .levelUp:    UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .evolve:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        case .petPoke:    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .heartbeat:  UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

// MARK: - CHHapticEvent helpers

private extension CHHapticEvent {
    static func transient(t: TimeInterval,
                          intensity: Float,
                          sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient,
                      parameters: [
                        .init(parameterID: .hapticIntensity, value: intensity),
                        .init(parameterID: .hapticSharpness, value: sharpness)
                      ],
                      relativeTime: t)
    }

    static func continuous(t: TimeInterval,
                           duration: TimeInterval,
                           intensity: Float,
                           sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticContinuous,
                      parameters: [
                        .init(parameterID: .hapticIntensity, value: intensity),
                        .init(parameterID: .hapticSharpness, value: sharpness)
                      ],
                      relativeTime: t,
                      duration: duration)
    }
}
