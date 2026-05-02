//
//  PetViewModel.swift
//  IslandPet
//

import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
final class PetViewModel: ObservableObject {

    @Published var pet: Pet?
    @Published var settings: AppSettings?
    @Published var showLevelUpToast: Bool = false
    @Published var pendingEvolution: PendingEvolution?    // drives full-screen cinematic

    struct PendingEvolution: Equatable, Identifiable {
        let id = UUID()
        let from: EvolutionStage
        let to: EvolutionStage
        let species: PetSpecies
        let petName: String
    }

    // Legacy toast triggers (kept for HomeView fallback / unit tests)
    @Published var showEvolutionToast: Bool = false

    var context: ModelContext
    private var decayTimer: Timer?

    init(context: ModelContext) {
        self.context = context
        loadOrCreate()
        startDecayLoop()
    }

    // MARK: - Loading

    private func loadOrCreate() {
        let petDescriptor = FetchDescriptor<Pet>()
        let settingsDescriptor = FetchDescriptor<AppSettings>()

        if let existing = try? context.fetch(petDescriptor).first {
            self.pet = existing
        }
        if let existing = try? context.fetch(settingsDescriptor).first {
            self.settings = existing
        } else {
            let s = AppSettings()
            context.insert(s)
            self.settings = s
        }
    }

    func createPet(name: String, species: PetSpecies) {
        let new = Pet(name: name, species: species)
        context.insert(new)
        try? context.save()
        self.pet = new
    }

    // MARK: - XP / Mood

    /// Award XP. Handles level up + evolution + persistence.
    func awardXP(_ amount: Int, reason: String = "") {
        guard let pet else { return }
        let oldLevel = pet.level
        let oldStage = pet.stage
        pet.xp += amount
        pet.happiness = min(1.0, pet.happiness + Double(amount) / 200)
        pet.lastInteractedAt = .now

        pet.evolveIfNeeded()

        if pet.level > oldLevel {
            HapticsService.shared.success()
            showLevelUpToast = true
            settings?.coins += 25
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                self?.showLevelUpToast = false
            }
        }

        if pet.stage != oldStage {
            HapticsService.shared.evolve()
            pet.remember(.evolved)
            pendingEvolution = PendingEvolution(
                from: oldStage,
                to: pet.stage,
                species: pet.species,
                petName: pet.name
            )
            showEvolutionToast = true
            settings?.coins += 100
            AchievementService.shared.registerEvolution(pet.stage, in: context)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
                self?.showEvolutionToast = false
            }
        }

        AchievementService.shared.checkXP(pet.xp, in: context)
        try? context.save()
        WidgetSnapshotService.write(pet: pet, settings: settings)
    }

    func feed() {
        guard let pet else { return }
        pet.hunger = min(1.0, pet.hunger + 0.35)
        pet.happiness = min(1.0, pet.happiness + 0.1)
        pet.lastFedAt = .now
        pet.remember(.fed)
        HapticsService.shared.petPoke()
        try? context.save()
        WidgetSnapshotService.write(pet: pet, settings: settings)
    }

    func play() {
        guard let pet else { return }
        pet.happiness = min(1.0, pet.happiness + 0.2)
        pet.energy = max(0.1, pet.energy - 0.05)
        pet.lastInteractedAt = .now
        pet.remember(.played)
        HapticsService.shared.petPoke()
        try? context.save()
        WidgetSnapshotService.write(pet: pet, settings: settings)
    }

    func rest() {
        guard let pet else { return }
        pet.energy = min(1.0, pet.energy + 0.4)
        try? context.save()
        WidgetSnapshotService.write(pet: pet, settings: settings)
    }

    // MARK: - Decay loop

    private func startDecayLoop() {
        decayTimer?.invalidate()
        decayTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickDecay() }
        }
    }

    private func tickDecay() {
        guard let pet else { return }
        // Slow decay: 1% hunger/min, 0.5% happiness/min if not interacted in >30m
        pet.hunger = max(0, pet.hunger - 0.01)
        if Date().timeIntervalSince(pet.lastInteractedAt) > 1800 {
            pet.happiness = max(0, pet.happiness - 0.005)
        }
        pet.energy = min(1.0, pet.energy + 0.005)
        try? context.save()
        WidgetSnapshotService.write(pet: pet, settings: settings)
    }

    // MARK: - Streaks

    func recordActivityToday() {
        guard let s = settings else { return }
        let cal = Calendar.current
        if cal.isDateInToday(s.lastStreakUpdate) { return }

        let daysGap = cal.dateComponents([.day],
                                         from: cal.startOfDay(for: s.lastStreakUpdate),
                                         to: cal.startOfDay(for: .now)).day ?? 0

        if cal.isDateInYesterday(s.lastStreakUpdate) || daysGap == 1 {
            s.currentStreak += 1
        } else if daysGap == 2 && s.streakFreezesAvailable > 0 && s.currentStreak > 0 {
            // Spend a streak freeze: gap of one missed day is forgiven.
            s.streakFreezesAvailable -= 1
            s.currentStreak += 1
            HapticsService.shared.streakSave()
        } else {
            if s.currentStreak > 0 {
                pet?.remember(.streakBroken)
            }
            s.currentStreak = 1
        }
        s.longestStreak = max(s.longestStreak, s.currentStreak)
        s.lastStreakUpdate = .now

        // Earn a streak freeze every 7 days, capped at 3.
        if s.currentStreak.isMultiple(of: 7) && s.streakFreezesAvailable < 3 {
            s.streakFreezesAvailable += 1
        }

        try? context.save()
        AchievementService.shared.checkStreak(s.currentStreak, in: context)
    }
}
