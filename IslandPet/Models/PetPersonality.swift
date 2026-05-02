//
//  PetPersonality.swift
//  IslandPet
//
//  The personality system. Designed to make the pet feel like a *specific*
//  companion rather than a mascot, without LLMs or per-user inference.
//
//  Three layers:
//
//   1. Traits (stable, set at birth)
//      Five values 0…1 sampled when the pet is created, biased by species.
//      Drives idle behaviors, dialogue tone, evolution path nudges.
//
//   2. Memory (ephemeral, last 30 events)
//      Fixed-size ring buffer of {kind, timestamp} events. The pet "remembers"
//      things like recent late-night sessions, missed days, peak focus times.
//      Stored on the Pet record as JSON.
//
//   3. State (computed)
//      Derived from traits + memory + current pet stats. Used by the dialogue
//      engine and the Dynamic Island composition selector.
//
//  This is ~200 lines of Swift and produces results that *feel* like an
//  AI companion to users, because consistency over time is what humans
//  pattern-match for personality.
//

import Foundation

// MARK: - Traits (stable)

struct PetTraits: Codable, Equatable {
    /// 0 = wallflower, 1 = exuberant. Affects greeting style and idle
    /// animation amplitude.
    var energy: Double
    /// 0 = stoic, 1 = expressive. Affects emoji density in dialogue.
    var warmth: Double
    /// 0 = chill, 1 = anxious-attached. Affects how strongly missed days hit.
    var attachment: Double
    /// 0 = night owl, 1 = early bird. Drives time-of-day reactions.
    var chronotype: Double
    /// 0 = silly, 1 = thoughtful. Affects which phrase pool is preferred.
    var sagacity: Double

    static func random(for species: PetSpecies) -> PetTraits {
        // Each species gets bias on certain traits; rest is rolled.
        var rng = SystemRandomNumberGenerator()
        func roll(_ bias: Double, spread: Double = 0.25) -> Double {
            let n = Double.random(in: 0...1, using: &rng)
            // skew toward bias with a triangular-ish blend
            return max(0, min(1, bias * 0.6 + n * 0.4 + (n - 0.5) * spread))
        }
        switch species {
        case .flameSprite:   // bright, eager
            return .init(energy: roll(0.85), warmth: roll(0.70),
                         attachment: roll(0.55), chronotype: roll(0.65),
                         sagacity: roll(0.30))
        case .oceanDrifter:  // calm, patient
            return .init(energy: roll(0.30), warmth: roll(0.60),
                         attachment: roll(0.45), chronotype: roll(0.40),
                         sagacity: roll(0.80))
        case .forestKit:     // balanced, curious
            return .init(energy: roll(0.55), warmth: roll(0.75),
                         attachment: roll(0.60), chronotype: roll(0.60),
                         sagacity: roll(0.55))
        case .crystalCub:    // mysterious, rare
            return .init(energy: roll(0.40), warmth: roll(0.40),
                         attachment: roll(0.75), chronotype: roll(0.30),
                         sagacity: roll(0.85))
        }
    }

    /// Human-readable summary used on the Profile screen and in shareable
    /// "personality cards." Important: shows as 1-2 traits picked, never all 5.
    /// Reading "all 5 stats" feels like a video game character sheet; reading
    /// "anxiously affectionate night owl" feels like a description of someone.
    var summary: String {
        var traits: [(score: Double, label: String)] = []
        if abs(energy - 0.5) > 0.2 {
            traits.append((abs(energy - 0.5), energy > 0.5 ? "exuberant" : "calm"))
        }
        if abs(warmth - 0.5) > 0.2 {
            traits.append((abs(warmth - 0.5), warmth > 0.5 ? "warm" : "reserved"))
        }
        if abs(attachment - 0.5) > 0.2 {
            traits.append((abs(attachment - 0.5),
                          attachment > 0.5 ? "affectionate" : "independent"))
        }
        if abs(chronotype - 0.5) > 0.2 {
            traits.append((abs(chronotype - 0.5),
                          chronotype > 0.5 ? "early bird" : "night owl"))
        }
        if abs(sagacity - 0.5) > 0.25 {
            traits.append((abs(sagacity - 0.5),
                          sagacity > 0.5 ? "thoughtful" : "playful"))
        }
        traits.sort { $0.score > $1.score }
        let top = traits.prefix(2).map(\.label)
        return top.isEmpty ? "balanced" : top.joined(separator: ", ")
    }
}

// MARK: - Memory (ephemeral)

enum PetMemoryKind: String, Codable {
    case focusCompleted          // session finished
    case focusAbandoned          // canceled mid-session
    case lateNightSession        // completed past midnight
    case earlyMorningSession     // completed before 7am
    case streakSaved             // freeze used
    case streakBroken
    case fed
    case played
    case daysAway                // user returned after >24h gap
    case evolved
}

struct PetMemory: Codable, Equatable {
    let kind: PetMemoryKind
    let at: Date
}

extension Pet {
    /// Append a memory; keep only the last 30. Persists via JSON on `memoriesData`.
    func remember(_ kind: PetMemoryKind, at date: Date = .now) {
        var current = decodedMemories()
        current.append(.init(kind: kind, at: date))
        if current.count > 30 {
            current.removeFirst(current.count - 30)
        }
        memoriesData = (try? JSONEncoder().encode(current)) ?? Data()
    }

    func decodedMemories() -> [PetMemory] {
        guard !memoriesData.isEmpty else { return [] }
        return (try? JSONDecoder().decode([PetMemory].self, from: memoriesData)) ?? []
    }

    var traits: PetTraits {
        get {
            if traitsData.isEmpty {
                return .random(for: species)
            }
            return (try? JSONDecoder().decode(PetTraits.self, from: traitsData))
                ?? .random(for: species)
        }
        set {
            traitsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    /// Convenience: count of a given memory kind in the last N hours.
    func recentCount(_ kind: PetMemoryKind, hours: Double) -> Int {
        let cutoff = Date().addingTimeInterval(-hours * 3600)
        return decodedMemories().filter { $0.kind == kind && $0.at > cutoff }.count
    }
}

// MARK: - Dialogue engine

/// Produces phrase choices based on traits + memory + state.
/// The pet's "voice" — used in the chat tab, the Dynamic Island taps,
/// onboarding, and notification copy.
struct PetVoice {
    let pet: Pet

    /// Greet the user when they open the app.
    func greeting(now: Date = .now) -> String {
        let hour = Calendar.current.component(.hour, from: now)
        let memories = pet.decodedMemories()
        let last = memories.last

        // Returning after a long absence? That comes first.
        if let last, Date().timeIntervalSince(last.at) > 86_400 * 2 {
            return phrase(from: pool(.afterAbsence))
        }
        // Streak broken recently?
        if memories.last(where: { $0.kind == .streakBroken })
            .map({ Date().timeIntervalSince($0.at) < 86_400 }) == true {
            return phrase(from: pool(.afterStreakBreak))
        }
        // Time of day greetings, biased by chronotype
        if hour < 6 || hour >= 23 {
            return phrase(from: pool(.lateNight))
        }
        if hour < 11 {
            return phrase(from: pool(.morning))
        }
        if hour < 17 {
            return phrase(from: pool(.afternoon))
        }
        return phrase(from: pool(.evening))
    }

    /// Reaction the moment a focus session starts.
    func sessionStart() -> String {
        return phrase(from: pool(.sessionStart))
    }

    /// Reaction to session completion.
    func sessionComplete() -> String {
        // If the user has done multiple sessions today, escalate.
        let todayCount = pet.recentCount(.focusCompleted, hours: 14)
        if todayCount >= 4 {
            return phrase(from: pool(.sessionRepeated))
        }
        return phrase(from: pool(.sessionComplete))
    }

    /// Reaction when a session is abandoned.
    func sessionAbandoned() -> String {
        if pet.traits.attachment > 0.7 {
            return phrase(from: pool(.abandonAttached))
        }
        return phrase(from: pool(.abandonChill))
    }

    /// Idle ambient line, used in the Dynamic Island when no session is
    /// running. These should be very short — they appear in the compact
    /// trailing region.
    func idleHint() -> String {
        let mood = pet.mood
        switch mood {
        case .happy:       return phrase(from: pool(.idleHappy))
        case .sad:         return phrase(from: pool(.idleSad))
        case .sleepy:      return phrase(from: pool(.idleSleepy))
        default:           return phrase(from: pool(.idleNeutral))
        }
    }

    // MARK: - Phrase selection

    private func phrase(from list: [String]) -> String {
        // Use date-of-day as seed so the same greeting doesn't repeat
        // session-to-session, but isn't obviously random either.
        let day = Int(Date().timeIntervalSince1970 / 60) // changes per minute
        let mix = (day &* 2654435761) ^ Int(pet.id.uuidString.hashValue)
        let idx = abs(mix) % list.count
        return decorate(list[idx])
    }

    /// Add or strip emoji density based on warmth.
    private func decorate(_ s: String) -> String {
        let warmth = pet.traits.warmth
        if warmth > 0.7 {
            return s
        } else if warmth < 0.3 {
            // Strip trailing emoji
            return s.unicodeScalars
                .filter { !$0.properties.isEmoji || $0.value < 0x2700 }
                .reduce("") { $0 + String($1) }
                .trimmingCharacters(in: .whitespaces)
        }
        return s
    }
}

// MARK: - Phrase pools

private enum PoolKind {
    case morning, afternoon, evening, lateNight
    case afterAbsence, afterStreakBreak
    case sessionStart, sessionComplete, sessionRepeated
    case abandonAttached, abandonChill
    case idleHappy, idleSad, idleSleepy, idleNeutral
}

private func pool(_ kind: PoolKind) -> [String] {
    switch kind {
    case .morning: return [
        "Morning. Ready when you are.",
        "Good morning ☀️ shall we begin?",
        "Hi. The day is wide open.",
        "Up early — I like it."
    ]
    case .afternoon: return [
        "Welcome back. One more block?",
        "Afternoon focus is the best focus.",
        "Hi 👋 let's pick up where we left off.",
        "The middle of the day is yours."
    ]
    case .evening: return [
        "Evening. Just a small one?",
        "I've been waiting all day 🌙",
        "Welcome home. Coffee or tea?",
        "Quiet hours suit us."
    ]
    case .lateNight: return [
        "We're up late again 🌙",
        "Burning the midnight oil — easy on yourself.",
        "Just one more, then sleep?",
        "Late again. I'm here."
    ]
    case .afterAbsence: return [
        "You're back!! 🥹",
        "I missed you.",
        "It's been a while. No hard feelings — let's just begin.",
        "Welcome home 💜"
    ]
    case .afterStreakBreak: return [
        "Hey. Streak gone, but we're not.",
        "It's okay. We start again.",
        "Streaks come back. Let's just focus today.",
        "Today is a perfectly fine day to begin."
    ]
    case .sessionStart: return [
        "Locked in 🎯",
        "Ssh — focusing.",
        "Eyes forward. I've got you.",
        "Let's go."
    ]
    case .sessionComplete: return [
        "We did it!",
        "Beautiful work ✨",
        "That counted. I felt it.",
        "+XP earned. +mood earned. +everything."
    ]
    case .sessionRepeated: return [
        "Another?? Okay 👀 I'm proud of you.",
        "You're on fire today 🔥",
        "Look at us go.",
        "Diminishing returns are real but I won't say it."
    ]
    case .abandonAttached: return [
        "Oh — okay. Whenever you're ready 🥺",
        "I'll be right here.",
        "Tough one? I get it."
    ]
    case .abandonChill: return [
        "All good. Next time.",
        "No streak here for cancelling. Whenever.",
        "We move on."
    ]
    case .idleHappy: return ["✨", "💜", "yay", "hi"]
    case .idleSad: return ["…", "hm", "👀"]
    case .idleSleepy: return ["zzz", "💤", "drowsy"]
    case .idleNeutral: return ["•", "hm", "ok", "👋"]
    }
}
