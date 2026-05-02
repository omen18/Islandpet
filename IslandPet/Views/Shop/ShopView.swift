//
//  ShopView.swift
//  IslandPet
//

import SwiftUI
import SwiftData

struct ShopView: View {
    @EnvironmentObject private var petVM: PetViewModel
    @Environment(\.modelContext) private var context
    @Query(sort: \ShopItem.priceCoins) private var items: [ShopItem]

    @State private var category: String = "hat"

    private let categories: [(id: String, label: String, icon: String)] = [
        ("hat", "Hats", "graduationcap.fill"),
        ("background", "Scenes", "mountain.2.fill"),
        ("food", "Snacks", "leaf.fill"),
        ("toy", "Toys", "gamecontroller.fill"),
    ]

    var body: some View {
        ZStack {
            BackgroundAurora()
            VStack(alignment: .leading, spacing: 16) {
                headerRow
                categoryRow
                grid
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
        }
    }

    private var headerRow: some View {
        HStack {
            Text("Shop").font(Theme.display(28))
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "circle.hexagongrid.fill")
                    .foregroundStyle(Theme.secondary)
                Text("\(petVM.settings?.coins ?? 0)").font(Theme.title(16))
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(GlassCard())
        }
        .padding(.top, 8)
    }

    private var categoryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.id) { c in
                    Button {
                        withAnimation(.smooth) { category = c.id }
                        HapticsService.shared.tap()
                    } label: {
                        Label(c.label, systemImage: c.icon)
                            .font(Theme.body(14))
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(
                                Capsule().fill(category == c.id ? Theme.accent : Theme.accent.opacity(0.12))
                            )
                            .foregroundStyle(category == c.id ? .white : Theme.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(items.filter { $0.category == category }) { item in
                    ShopItemCard(item: item, coins: petVM.settings?.coins ?? 0) {
                        purchase(item)
                    }
                }
            }
        }
    }

    private func purchase(_ item: ShopItem) {
        guard let s = petVM.settings else { return }
        if item.owned {
            // toggle equip — only one per category at a time
            for sibling in items where sibling.category == item.category && sibling.id != item.id {
                sibling.equipped = false
            }
            item.equipped.toggle()
            // mirror into Pet so widgets / live activity could show it later
            if let pet = petVM.pet {
                let equippedID = item.equipped ? item.id : nil
                switch item.category {
                case "hat":        pet.equippedHatID = equippedID
                case "background": pet.equippedBackgroundID = equippedID
                default: break
                }
            }
            HapticsService.shared.tap()
        } else if s.coins >= item.priceCoins {
            s.coins -= item.priceCoins
            item.owned = true
            HapticsService.shared.success()
        } else {
            HapticsService.shared.warning()
        }
        try? context.save()
        if let pet = petVM.pet {
            WidgetSnapshotService.write(pet: pet, settings: s)
        }
    }
}

struct ShopItemCard: View {
    let item: ShopItem
    let coins: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: item.iconSystemName)
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.accent)
                    .frame(height: 60)
                Text(item.name).font(Theme.title(15)).lineLimit(1)
                if item.equipped {
                    Label("Equipped", systemImage: "checkmark.seal.fill")
                        .font(Theme.body(12))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(Theme.success.opacity(0.2)))
                        .foregroundStyle(Theme.success)
                } else if item.owned {
                    Text("Tap to equip")
                        .font(Theme.body(12)).foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "circle.hexagongrid.fill")
                        Text("\(item.priceCoins)")
                    }
                    .font(Theme.title(13))
                    .foregroundStyle(coins >= item.priceCoins ? Theme.secondary : .gray)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(GlassCard())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Seeder

enum ShopSeeder {
    @MainActor
    static func seedIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<ShopItem>()
        if let count = try? context.fetchCount(descriptor), count > 0 { return }

        let defaults: [ShopItem] = [
            // Hats
            ShopItem(id: "hat_grad", name: "Scholar Cap", category: "hat",
                     priceCoins: 100, iconSystemName: "graduationcap.fill"),
            ShopItem(id: "hat_party", name: "Party Hat", category: "hat",
                     priceCoins: 150, iconSystemName: "party.popper.fill"),
            ShopItem(id: "hat_crown", name: "Royal Crown", category: "hat",
                     priceCoins: 500, iconSystemName: "crown.fill"),
            // Backgrounds
            ShopItem(id: "bg_forest", name: "Forest Glade", category: "background",
                     priceCoins: 200, iconSystemName: "tree.fill"),
            ShopItem(id: "bg_ocean", name: "Ocean Cove", category: "background",
                     priceCoins: 200, iconSystemName: "water.waves"),
            ShopItem(id: "bg_space", name: "Starfield", category: "background",
                     priceCoins: 400, iconSystemName: "moon.stars.fill"),
            // Food
            ShopItem(id: "food_berry", name: "Berries", category: "food",
                     priceCoins: 25, iconSystemName: "leaf.fill"),
            ShopItem(id: "food_cake", name: "Birthday Cake", category: "food",
                     priceCoins: 80, iconSystemName: "birthday.cake.fill"),
            // Toys
            ShopItem(id: "toy_ball", name: "Bouncy Ball", category: "toy",
                     priceCoins: 50, iconSystemName: "circle.fill"),
            ShopItem(id: "toy_book", name: "Storybook", category: "toy",
                     priceCoins: 100, iconSystemName: "book.fill"),
        ]
        for d in defaults { context.insert(d) }
        try? context.save()
    }
}
