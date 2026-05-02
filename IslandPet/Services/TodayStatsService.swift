//
//  TodayStatsService.swift
//  IslandPet
//
//  Computes today's focus stats from SwiftData. Pure functions where possible
//  so views can call them inside `.task`/`.onAppear` without owning state.
//

import Foundation
import SwiftData

struct TodayStats: Equatable {
    var sessionsCompleted: Int = 0
    var sessionsAttempted: Int = 0
    var focusMinutes: Int = 0
    var xpEarned: Int = 0
    var bestSessionMinutes: Int = 0

    static let zero = TodayStats()
}

enum TodayStatsService {

    /// Returns aggregated stats for sessions started today (in the current calendar).
    @MainActor
    static func today(in context: ModelContext) -> TodayStats {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: .now)
        guard let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay) else {
            return .zero
        }

        let predicate = #Predicate<FocusSession> { session in
            session.startedAt >= startOfDay && session.startedAt < endOfDay
        }
        var descriptor = FetchDescriptor<FocusSession>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.startedAt)]

        guard let sessions = try? context.fetch(descriptor) else { return .zero }

        var stats = TodayStats()
        stats.sessionsAttempted = sessions.count
        for s in sessions {
            if s.completed {
                stats.sessionsCompleted += 1
                stats.xpEarned += s.xpEarned
            }
            let mins = s.actualDurationSeconds / 60
            stats.focusMinutes += mins
            stats.bestSessionMinutes = max(stats.bestSessionMinutes, mins)
        }
        return stats
    }
}
