//
//  IslandPetApp.swift
//  IslandPet
//

import SwiftUI
import SwiftData

@main
struct IslandPetApp: App {

    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    /// Build a ModelContainer with the App Group store. If that fails (e.g.
    /// schema migration error on a TestFlight upgrade), fall back to a fresh
    /// store so the app still launches — we'd rather lose data than soft-brick.
    let container: ModelContainer = {
        let schema = Schema([
            Pet.self,
            FocusSession.self,
            Achievement.self,
            ShopItem.self,
            ChatMessage.self,
            AppSettings.self
        ])

        let groupedConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(AppGroup.identifier)
        )
        if let c = try? ModelContainer(for: schema, configurations: [groupedConfig]) {
            return c
        }

        // Fallback 1: default location (no app group)
        let defaultConfig = ModelConfiguration(schema: schema)
        if let c = try? ModelContainer(for: schema, configurations: [defaultConfig]) {
            return c
        }

        // Fallback 2: in-memory so the UI can at least render.
        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: [memory])
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(appState.colorScheme)
                .tint(Theme.accent)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            handleScenePhase(phase)
        }
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // Re-arm any background work
            NotificationService.shared.refreshPetSadnessReminder()
        case .background:
            // Persist & schedule
            NotificationService.shared.scheduleStreakReminderIfNeeded()
        default: break
        }
    }
}

enum AppGroup {
    static let identifier = "group.com.islandpet.shared"
    static var defaults: UserDefaults? { UserDefaults(suiteName: identifier) }
}
