//
//  LiveActivityService.swift
//  IslandPet
//
//  Wraps ActivityKit. Single active activity at a time. iOS 17+.
//

import Foundation
import ActivityKit

@MainActor
final class LiveActivityService {

    static let shared = LiveActivityService()
    private init() {}

    private var current: Activity<PetActivityAttributes>?

    var isAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func start(for pet: Pet?,
               mood: PetActivityAttributes.PetState.Mood,
               sessionStart: Date?,
               sessionEnd: Date?,
               total: Int,
               streak: Int) async {
        guard isAvailable, let pet = pet else { return }
        await endAll()

        let attributes = PetActivityAttributes(
            petName: pet.name,
            petSpecies: pet.species.rawValue,
            evolutionStage: pet.stage.rawValue
        )
        let state = PetActivityAttributes.PetState(
            mood: mood,
            sessionEndsAt: sessionEnd,
            sessionStartedAt: sessionStart,
            totalDurationSeconds: total,
            xp: pet.xp,
            level: pet.level,
            hunger: pet.hunger,
            streakDays: streak
        )
        do {
            let content = ActivityContent(
                state: state,
                staleDate: sessionEnd?.addingTimeInterval(60)
            )
            current = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("LiveActivity start failed: \(error)")
        }
    }

    func update(mood: PetActivityAttributes.PetState.Mood,
                sessionStart: Date?,
                sessionEnd: Date?,
                total: Int,
                pet: Pet?,
                streak: Int) async {
        guard let activity = current, let pet = pet else { return }
        let state = PetActivityAttributes.PetState(
            mood: mood,
            sessionEndsAt: sessionEnd,
            sessionStartedAt: sessionStart,
            totalDurationSeconds: total,
            xp: pet.xp,
            level: pet.level,
            hunger: pet.hunger,
            streakDays: streak
        )
        let content = ActivityContent(
            state: state,
            staleDate: sessionEnd?.addingTimeInterval(60)
        )
        await activity.update(content)
    }

    func end(_ finalMood: PetActivityAttributes.PetState.Mood, pet: Pet?) async {
        guard let activity = current else { return }
        if let pet {
            let state = PetActivityAttributes.PetState(
                mood: finalMood,
                sessionEndsAt: nil,
                sessionStartedAt: nil,
                totalDurationSeconds: 0,
                xp: pet.xp, level: pet.level,
                hunger: pet.hunger, streakDays: 0
            )
            await activity.end(
                ActivityContent(state: state, staleDate: nil),
                dismissalPolicy: .after(.now + 3)
            )
        } else {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        current = nil
    }

    func endAll() async {
        for activity in Activity<PetActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        current = nil
    }
}
