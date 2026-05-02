//
//  TimerViewModel.swift
//  IslandPet
//

import Foundation
import SwiftData
import SwiftUI
import ActivityKit
import Combine

@MainActor
final class TimerViewModel: ObservableObject {

    enum Phase { case idle, focusing, paused, breakTime, completed }

    @Published var phase: Phase = .idle
    @Published var remaining: TimeInterval = 25 * 60
    @Published var totalDuration: TimeInterval = 25 * 60
    @Published var taskTitle: String = "Deep Work"
    @Published var currentSession: FocusSession?

    private var timer: Timer?
    private var endsAt: Date?
    private var startedAt: Date?
    private weak var petVM: PetViewModel?
    var context: ModelContext

    init(context: ModelContext, petVM: PetViewModel) {
        self.context = context
        self.petVM = petVM
        if let mins = petVM.settings?.preferredPomodoroMinutes {
            self.totalDuration = TimeInterval(mins * 60)
            self.remaining = self.totalDuration
        }
        observeStopIntent()
    }

    /// Listen for the Dynamic Island Stop button (posted via Distributed
    /// Notification by StopFocusIntent in the widget extension).
    private func observeStopIntent() {
        DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("islandpet.stopFocus"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.cancel()
            }
        }
    }

    func setPetVM(_ vm: PetViewModel) { self.petVM = vm }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1 - (remaining / totalDuration)
    }

    var formattedRemaining: String {
        let secs = max(0, Int(remaining))
        return String(format: "%02d:%02d", secs / 60, secs % 60)
    }

    // MARK: Actions

    func start() {
        guard phase != .focusing else { return }
        if phase == .idle || phase == .completed {
            // fresh session
            let session = FocusSession(
                plannedDurationSeconds: Int(totalDuration),
                taskTitle: taskTitle.isEmpty ? "Focus" : taskTitle
            )
            context.insert(session)
            currentSession = session
            startedAt = Date()
            endsAt = Date().addingTimeInterval(remaining)
        } else if phase == .paused {
            endsAt = Date().addingTimeInterval(remaining)
        }
        phase = .focusing
        scheduleTick()
        Task { await LiveActivityService.shared.start(for: petVM?.pet, mood: .focusing,
                                                      sessionStart: startedAt ?? .now,
                                                      sessionEnd: endsAt ?? .now,
                                                      total: Int(totalDuration),
                                                      streak: petVM?.settings?.currentStreak ?? 0) }
        if let endsAt, let petName = petVM?.pet?.name {
            let projectedXP = Int(totalDuration / 60) + 25
            NotificationService.shared.scheduleFocusCompletion(
                at: endsAt, petName: petName, xp: projectedXP
            )
        }
        HapticsService.shared.thunk()
    }

    func pause() {
        timer?.invalidate(); timer = nil
        if let endsAt {
            remaining = max(0, endsAt.timeIntervalSinceNow)
        }
        phase = .paused
        NotificationService.shared.cancelFocusCompletion()
        Task { await LiveActivityService.shared.update(mood: .idle,
                                                       sessionStart: startedAt,
                                                       sessionEnd: nil,
                                                       total: Int(totalDuration),
                                                       pet: petVM?.pet,
                                                       streak: petVM?.settings?.currentStreak ?? 0) }
    }

    func cancel() {
        timer?.invalidate(); timer = nil
        NotificationService.shared.cancelFocusCompletion()
        if let session = currentSession {
            session.endedAt = .now
            session.actualDurationSeconds = Int(Date().timeIntervalSince(session.startedAt))
            session.completed = false
            petVM?.pet?.remember(.focusAbandoned)
            try? context.save()
        }
        phase = .idle
        remaining = totalDuration
        currentSession = nil
        Task { await LiveActivityService.shared.end(.idle, pet: petVM?.pet) }
    }

    private func scheduleTick() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        guard let endsAt else { return }
        remaining = max(0, endsAt.timeIntervalSinceNow)
        if remaining <= 0 {
            complete()
        }
    }

    private func complete() {
        timer?.invalidate(); timer = nil
        NotificationService.shared.cancelFocusCompletion()
        phase = .completed
        if let session = currentSession {
            session.endedAt = .now
            session.actualDurationSeconds = session.plannedDurationSeconds
            session.completed = true
            // XP scales with session length: 1 XP per minute, +25 bonus for completion
            let xp = (session.plannedDurationSeconds / 60) + 25
            session.xpEarned = xp
            petVM?.awardXP(xp, reason: "Pomodoro complete")
            petVM?.recordActivityToday()
            petVM?.settings?.coins += 10
            // Memory: focus completed, with time-of-day flavor
            if let pet = petVM?.pet {
                pet.remember(.focusCompleted)
                let hour = Calendar.current.component(.hour, from: .now)
                if hour >= 23 || hour < 5 { pet.remember(.lateNightSession) }
                if hour >= 5  && hour < 7 { pet.remember(.earlyMorningSession) }
            }
            AchievementService.shared.registerSessionCompletion(in: context)
            try? context.save()
        }
        HapticsService.shared.levelUp()
        Task { await LiveActivityService.shared.update(mood: .celebrating,
                                                       sessionStart: nil,
                                                       sessionEnd: nil,
                                                       total: 0,
                                                       pet: petVM?.pet,
                                                       streak: petVM?.settings?.currentStreak ?? 0) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            Task { await LiveActivityService.shared.end(.idle, pet: self?.petVM?.pet) }
        }
        currentSession = nil
        remaining = totalDuration
    }

    func setMinutes(_ m: Int) {
        guard phase == .idle || phase == .completed else { return }
        totalDuration = TimeInterval(m * 60)
        remaining = totalDuration
        petVM?.settings?.preferredPomodoroMinutes = m
        try? context.save()
    }
}
