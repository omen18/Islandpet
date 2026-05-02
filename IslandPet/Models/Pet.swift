//
//  Pet.swift
//  IslandPet
//

import Foundation
import SwiftData

@Model
final class Pet {
    @Attribute(.unique) var id: UUID
    var name: String
    var speciesRaw: String
    var stageRaw: String
    var xp: Int
    var hunger: Double          // 0…1, lower = hungrier
    var happiness: Double       // 0…1
    var energy: Double          // 0…1
    var createdAt: Date
    var lastFedAt: Date
    var lastInteractedAt: Date
    var equippedHatID: String?
    var equippedBackgroundID: String?

    /// JSON-encoded PetTraits, sampled at birth.
    var traitsData: Data
    /// JSON-encoded ring buffer of last 30 PetMemory entries.
    var memoriesData: Data

    init(name: String,
         species: PetSpecies,
         stage: EvolutionStage = .egg,
         xp: Int = 0) {
        self.id = UUID()
        self.name = name
        self.speciesRaw = species.rawValue
        self.stageRaw = stage.rawValue
        self.xp = xp
        self.hunger = 0.8
        self.happiness = 0.9
        self.energy = 1.0
        self.createdAt = .now
        self.lastFedAt = .now
        self.lastInteractedAt = .now
        self.traitsData = (try? JSONEncoder().encode(PetTraits.random(for: species)))
            ?? Data()
        self.memoriesData = Data()
    }

    // MARK: Computed
    var species: PetSpecies { PetSpecies(rawValue: speciesRaw) ?? .flameSprite }
    var stage: EvolutionStage {
        get { EvolutionStage(rawValue: stageRaw) ?? .egg }
        set { stageRaw = newValue.rawValue }
    }

    var level: Int { max(1, xp / 100 + 1) }
    var xpIntoLevel: Int { xp % 100 }
    var xpForNextLevel: Int { 100 }

    var mood: PetActivityAttributes.PetState.Mood {
        if happiness < 0.25 || hunger < 0.2 { return .sad }
        if energy < 0.3 { return .sleepy }
        if happiness > 0.8 { return .happy }
        return .idle
    }

    /// Required XP thresholds for the next stage transition.
    static let stageThresholds: [EvolutionStage: Int] = [
        .egg: 50,
        .baby: 250,
        .teen: 700,
        .adult: Int.max
    ]

    func evolveIfNeeded() {
        let threshold = Pet.stageThresholds[stage] ?? Int.max
        if xp >= threshold {
            switch stage {
            case .egg:   stage = .baby
            case .baby:  stage = .teen
            case .teen:  stage = .adult
            case .adult: break
            }
        }
    }
}

enum PetSpecies: String, CaseIterable, Codable {
    case flameSprite     = "FlameSprite"
    case oceanDrifter    = "OceanDrifter"
    case forestKit       = "ForestKit"
    case crystalCub      = "CrystalCub"

    var displayName: String {
        switch self {
        case .flameSprite:  return "Flame Sprite"
        case .oceanDrifter: return "Ocean Drifter"
        case .forestKit:    return "Forest Kit"
        case .crystalCub:   return "Crystal Cub"
        }
    }

    var primaryHex: String {
        switch self {
        case .flameSprite:  return "FF7A45"
        case .oceanDrifter: return "4FB6FF"
        case .forestKit:    return "63C97A"
        case .crystalCub:   return "B58BFF"
        }
    }

    var blurb: String {
        switch self {
        case .flameSprite:  return "Bright, eager, and impatient. Loves short sprints."
        case .oceanDrifter: return "Calm and patient. Thrives on deep work."
        case .forestKit:    return "Curious and grounded. A balanced companion."
        case .crystalCub:   return "Mysterious and rare. Rewards consistency."
        }
    }
}

enum EvolutionStage: String, Codable, CaseIterable {
    case egg, baby, teen, adult

    var emoji: String {
        switch self {
        case .egg:   return "🥚"
        case .baby:  return "🐣"
        case .teen:  return "🐥"
        case .adult: return "🐉"
        }
    }
}
