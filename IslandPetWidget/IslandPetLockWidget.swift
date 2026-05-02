//
//  IslandPetLockWidget.swift
//  IslandPetWidgetExtension
//
//  Renders the pet on Lock Screen and Home Screen.
//  Reads cached state from the App Group's UserDefaults so we don't need SwiftData here.
//

import WidgetKit
import SwiftUI

struct PetSnapshotEntry: TimelineEntry {
    let date: Date
    let petName: String
    let level: Int
    let xpInLevel: Int
    let xpForLevel: Int
    let stage: String
    let species: String
    let mood: String
    let streak: Int
    let hunger: Double
}

struct PetSnapshotProvider: TimelineProvider {

    func placeholder(in context: Context) -> PetSnapshotEntry {
        PetSnapshotEntry(date: .now, petName: "Mochi", level: 3, xpInLevel: 60,
                         xpForLevel: 100, stage: "baby", species: "FlameSprite",
                         mood: "happy", streak: 4, hunger: 0.7)
    }

    func getSnapshot(in context: Context, completion: @escaping (PetSnapshotEntry) -> Void) {
        completion(read())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetSnapshotEntry>) -> Void) {
        let entry = read()
        // Refresh every 15 minutes
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func read() -> PetSnapshotEntry {
        let d = UserDefaults(suiteName: "group.com.islandpet.shared")
        return PetSnapshotEntry(
            date: .now,
            petName: d?.string(forKey: "petName") ?? "Buddy",
            level: d?.integer(forKey: "level") ?? 1,
            xpInLevel: d?.integer(forKey: "xpInLevel") ?? 0,
            xpForLevel: d?.integer(forKey: "xpForLevel") ?? 100,
            stage: d?.string(forKey: "stage") ?? "egg",
            species: d?.string(forKey: "species") ?? "FlameSprite",
            mood: d?.string(forKey: "mood") ?? "idle",
            streak: d?.integer(forKey: "streak") ?? 0,
            hunger: d?.double(forKey: "hunger") ?? 0.8
        )
    }
}

struct IslandPetLockWidget: Widget {
    let kind = "IslandPetLockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetSnapshotProvider()) { entry in
            PetWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("IslandPet")
        .description("See your pet at a glance.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .systemSmall,
            .systemMedium
        ])
    }
}

struct PetWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: PetSnapshotEntry

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .accessoryInline: inline
        case .systemSmall: small
        case .systemMedium: medium
        default: small
        }
    }

    private var inline: some View {
        Text("\(emojiForStage(entry.stage)) \(entry.petName) · Lv \(entry.level)")
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text(emojiForStage(entry.stage)).font(.system(size: 22))
                Text("Lv \(entry.level)").font(.system(size: 10, weight: .semibold))
            }
        }
    }

    private var rectangular: some View {
        HStack(spacing: 8) {
            Text(emojiForStage(entry.stage)).font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.petName).font(.system(size: 14, weight: .semibold))
                Text("Lv \(entry.level) · \(entry.mood.capitalized)")
                    .font(.system(size: 11))
                ProgressView(value: Double(entry.xpInLevel),
                             total: Double(entry.xpForLevel))
                    .frame(height: 4)
            }
        }
    }

    private var small: some View {
        VStack(spacing: 8) {
            Text(emojiForStage(entry.stage)).font(.system(size: 50))
            Text(entry.petName).font(.system(size: 14, weight: .semibold))
            HStack(spacing: 4) {
                Text("Lv \(entry.level)")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(.purple.opacity(0.2)))
                Text("🔥\(entry.streak)").font(.system(size: 11))
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var medium: some View {
        HStack(spacing: 14) {
            Text(emojiForStage(entry.stage)).font(.system(size: 56))
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.petName).font(.system(size: 17, weight: .bold))
                Text("Level \(entry.level) · \(entry.stage.capitalized)")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                ProgressView(value: Double(entry.xpInLevel),
                             total: Double(entry.xpForLevel))
                    .tint(.purple)
                HStack(spacing: 12) {
                    Label("\(entry.streak)", systemImage: "flame.fill").foregroundStyle(.orange)
                    Label("\(Int(entry.hunger * 100))%", systemImage: "fork.knife").foregroundStyle(.brown)
                }
                .font(.system(size: 11, weight: .semibold))
            }
            Spacer()
        }
        .padding(12)
    }

    private func emojiForStage(_ s: String) -> String {
        switch s {
        case "egg": return "🥚"
        case "baby": return "🐣"
        case "teen": return "🐥"
        case "adult": return "🐉"
        default: return "🐣"
        }
    }
}
