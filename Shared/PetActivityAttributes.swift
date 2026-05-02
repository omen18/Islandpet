//
//  PetActivityAttributes.swift
//  IslandPet (Shared)
//
//  Live Activity + Dynamic Island state shared between the app and the widget extension.
//  Keep this file in BOTH targets: IslandPet & IslandPetWidgetExtension.
//

import Foundation
import ActivityKit

public struct PetActivityAttributes: ActivityAttributes {

    public typealias ContentState = PetState

    // Static across the activity
    public let petName: String
    public let petSpecies: String       // e.g. "FlameSprite"
    public let evolutionStage: String   // egg | baby | teen | adult

    public init(petName: String, petSpecies: String, evolutionStage: String) {
        self.petName = petName
        self.petSpecies = petSpecies
        self.evolutionStage = evolutionStage
    }

    public struct PetState: Codable, Hashable {
        public enum Mood: String, Codable {
            case idle, focusing, happy, sleepy, sad, celebrating
        }

        public var mood: Mood
        public var sessionEndsAt: Date?         // nil if no active focus session
        public var sessionStartedAt: Date?
        public var totalDurationSeconds: Int    // length of the current pomodoro
        public var xp: Int
        public var level: Int
        public var hunger: Double               // 0…1
        public var streakDays: Int

        public init(mood: Mood,
                    sessionEndsAt: Date?,
                    sessionStartedAt: Date?,
                    totalDurationSeconds: Int,
                    xp: Int,
                    level: Int,
                    hunger: Double,
                    streakDays: Int) {
            self.mood = mood
            self.sessionEndsAt = sessionEndsAt
            self.sessionStartedAt = sessionStartedAt
            self.totalDurationSeconds = totalDurationSeconds
            self.xp = xp
            self.level = level
            self.hunger = hunger
            self.streakDays = streakDays
        }

        public var progress: Double {
            guard let start = sessionStartedAt,
                  let end = sessionEndsAt,
                  end > start else { return 0 }
            let total = end.timeIntervalSince(start)
            let elapsed = Date().timeIntervalSince(start)
            return min(max(elapsed / total, 0), 1)
        }
    }
}
