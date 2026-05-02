//
//  FocusSession.swift
//  IslandPet
//

import Foundation
import SwiftData

@Model
final class FocusSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var plannedDurationSeconds: Int
    var actualDurationSeconds: Int
    var completed: Bool
    var taskTitle: String
    var xpEarned: Int

    init(plannedDurationSeconds: Int, taskTitle: String) {
        self.id = UUID()
        self.startedAt = .now
        self.plannedDurationSeconds = plannedDurationSeconds
        self.actualDurationSeconds = 0
        self.completed = false
        self.taskTitle = taskTitle
        self.xpEarned = 0
    }
}

@Model
final class AppSettings {
    var hasCompletedOnboarding: Bool
    var preferredPomodoroMinutes: Int
    var preferredBreakMinutes: Int
    var soundEnabled: Bool
    var hapticsEnabled: Bool
    var notificationsEnabled: Bool
    var lastStreakUpdate: Date
    var currentStreak: Int
    var longestStreak: Int
    var coins: Int                          // soft currency
    var streakFreezesAvailable: Int         // earned weekly; protects streak after 1 missed day

    init() {
        self.hasCompletedOnboarding = false
        self.preferredPomodoroMinutes = 25
        self.preferredBreakMinutes = 5
        self.soundEnabled = true
        self.hapticsEnabled = true
        self.notificationsEnabled = true
        self.lastStreakUpdate = .distantPast
        self.currentStreak = 0
        self.longestStreak = 0
        self.coins = 0
        self.streakFreezesAvailable = 1
    }
}
