//
//  AchievementService.swift
//  IslandPet
//

import Foundation
import SwiftData

final class AchievementService {

    static let shared = AchievementService()
    private init() {}

    /// Seed default achievements if missing.
    @MainActor
    func seedIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<Achievement>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let existingIDs = Set(existing.map(\.id))

        let defaults: [Achievement] = [
            Achievement(id: "first_session", title: "First Steps",
                        subtitle: "Complete your first focus session",
                        iconSystemName: "sparkles", goal: 1, rewardCoins: 25),
            Achievement(id: "streak_3", title: "Getting Warm",
                        subtitle: "Reach a 3-day streak",
                        iconSystemName: "flame.fill", goal: 3, rewardCoins: 50),
            Achievement(id: "streak_7", title: "On Fire",
                        subtitle: "Reach a 7-day streak",
                        iconSystemName: "flame.fill", goal: 7, rewardCoins: 100),
            Achievement(id: "streak_30", title: "Unstoppable",
                        subtitle: "Reach a 30-day streak",
                        iconSystemName: "crown.fill", goal: 30, rewardCoins: 500),
            Achievement(id: "xp_500", title: "Apprentice",
                        subtitle: "Earn 500 XP",
                        iconSystemName: "star.fill", goal: 500, rewardCoins: 75),
            Achievement(id: "xp_2000", title: "Scholar",
                        subtitle: "Earn 2,000 XP",
                        iconSystemName: "star.circle.fill", goal: 2000, rewardCoins: 200),
            Achievement(id: "evolved_baby", title: "Hatched!",
                        subtitle: "Evolve to baby form",
                        iconSystemName: "leaf.fill", goal: 1, rewardCoins: 50),
            Achievement(id: "evolved_adult", title: "Fully Grown",
                        subtitle: "Reach the final form",
                        iconSystemName: "wand.and.stars", goal: 1, rewardCoins: 1000),
        ]
        for a in defaults where !existingIDs.contains(a.id) {
            context.insert(a)
        }
        try? context.save()
    }

    @MainActor
    func checkXP(_ totalXP: Int, in context: ModelContext) {
        update(id: "xp_500", current: totalXP, in: context)
        update(id: "xp_2000", current: totalXP, in: context)
    }

    @MainActor
    func checkStreak(_ streak: Int, in context: ModelContext) {
        update(id: "streak_3", current: streak, in: context)
        update(id: "streak_7", current: streak, in: context)
        update(id: "streak_30", current: streak, in: context)
    }

    @MainActor
    func registerSessionCompletion(in context: ModelContext) {
        let d = FetchDescriptor<FocusSession>(predicate: #Predicate { $0.completed == true })
        let count = (try? context.fetchCount(d)) ?? 0
        update(id: "first_session", current: count, in: context)
    }

    @MainActor
    func registerEvolution(_ stage: EvolutionStage, in context: ModelContext) {
        switch stage {
        case .baby:  update(id: "evolved_baby", current: 1, in: context)
        case .adult: update(id: "evolved_adult", current: 1, in: context)
        default: break
        }
    }

    @MainActor
    private func update(id: String, current: Int, in context: ModelContext) {
        let d = FetchDescriptor<Achievement>(predicate: #Predicate { $0.id == id })
        guard let a = try? context.fetch(d).first else { return }
        a.current = min(current, a.goal)
        a.progress = Double(a.current) / Double(a.goal)
        if a.current >= a.goal && a.unlockedAt == nil {
            a.unlockedAt = .now
            // grant coins
            let s = try? context.fetch(FetchDescriptor<AppSettings>()).first
            s?.coins += a.rewardCoins
        }
        try? context.save()
    }
}
