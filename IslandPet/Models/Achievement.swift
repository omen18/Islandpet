//
//  Achievement.swift
//  IslandPet
//

import Foundation
import SwiftData

@Model
final class Achievement {
    @Attribute(.unique) var id: String      // stable code, e.g. "streak_7"
    var title: String
    var subtitle: String
    var iconSystemName: String
    var unlockedAt: Date?
    var progress: Double                    // 0…1
    var goal: Int
    var current: Int
    var rewardCoins: Int

    init(id: String, title: String, subtitle: String,
         iconSystemName: String, goal: Int, rewardCoins: Int) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconSystemName = iconSystemName
        self.goal = goal
        self.current = 0
        self.progress = 0
        self.rewardCoins = rewardCoins
    }

    var isUnlocked: Bool { unlockedAt != nil }
}

@Model
final class ShopItem {
    @Attribute(.unique) var id: String
    var name: String
    var category: String        // "hat" | "background" | "food" | "toy"
    var priceCoins: Int
    var iconSystemName: String
    var owned: Bool
    var equipped: Bool

    init(id: String, name: String, category: String,
         priceCoins: Int, iconSystemName: String) {
        self.id = id
        self.name = name
        self.category = category
        self.priceCoins = priceCoins
        self.iconSystemName = iconSystemName
        self.owned = false
        self.equipped = false
    }
}

@Model
final class ChatMessage {
    @Attribute(.unique) var id: UUID
    var role: String            // "user" | "pet"
    var content: String
    var createdAt: Date

    init(role: String, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.createdAt = .now
    }
}
