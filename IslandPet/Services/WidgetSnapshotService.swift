//
//  WidgetSnapshotService.swift
//  IslandPet
//

import Foundation
import WidgetKit

enum WidgetSnapshotService {

    @MainActor
    static func write(pet: Pet, settings: AppSettings?) {
        guard let d = AppGroup.defaults else { return }
        d.set(pet.name,           forKey: "petName")
        d.set(pet.level,          forKey: "level")
        d.set(pet.xpIntoLevel,    forKey: "xpInLevel")
        d.set(pet.xpForNextLevel, forKey: "xpForLevel")
        d.set(pet.stage.rawValue, forKey: "stage")
        d.set(pet.species.rawValue, forKey: "species")
        d.set(pet.mood.rawValue,  forKey: "mood")
        d.set(settings?.currentStreak ?? 0, forKey: "streak")
        d.set(pet.hunger,         forKey: "hunger")
        d.set(pet.happiness,      forKey: "happiness")
        d.set(Date().timeIntervalSince1970, forKey: "lastWriteAt")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
