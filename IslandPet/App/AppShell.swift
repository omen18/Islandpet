//
//  AppShell.swift
//  IslandPet
//
//  Owns the long-lived view models. Created once after onboarding completes.
//  The trick: @StateObject needs an initial value at view-init time, but the
//  ModelContext only exists in the SwiftUI environment. We use a thin two-stage
//  pattern: create the VMs lazily in `task`, then render the real UI when ready.
//

import SwiftUI
import SwiftData

struct AppShell: View {
    @Environment(\.modelContext) private var context
    @StateObject private var loader = VMLoader()

    var body: some View {
        Group {
            if let petVM = loader.petVM, let timerVM = loader.timerVM {
                MainTabView()
                    .environmentObject(petVM)
                    .environmentObject(timerVM)
                    .fullScreenCover(item: Binding(
                        get: { petVM.pendingEvolution },
                        set: { petVM.pendingEvolution = $0 }
                    )) { evo in
                        EvolutionCinematicView(
                            species: evo.species,
                            oldStage: evo.from,
                            newStage: evo.to,
                            petName: evo.petName,
                            pendingTraits: petVM.pet?.traits,
                            onDismiss: { petVM.pendingEvolution = nil }
                        )
                    }
            } else {
                ZStack {
                    BackgroundAurora()
                    ProgressView().controlSize(.large)
                }
            }
        }
        .task(id: loader.bootstrapped) {
            guard !loader.bootstrapped else { return }
            await loader.bootstrap(context: context)
        }
    }
}

/// Holds the view models and exposes them once initialized.
/// Using a single ObservableObject as the owner sidesteps the
/// "@StateObject needs synchronous init" constraint cleanly.
@MainActor
final class VMLoader: ObservableObject {
    @Published private(set) var petVM: PetViewModel?
    @Published private(set) var timerVM: TimerViewModel?
    @Published private(set) var bootstrapped: Bool = false

    func bootstrap(context: ModelContext) async {
        // Seed reference data
        AchievementService.shared.seedIfNeeded(in: context)
        ShopSeeder.seedIfNeeded(in: context)

        let pet = PetViewModel(context: context)
        let timer = TimerViewModel(context: context, petVM: pet)
        self.petVM = pet
        self.timerVM = timer
        self.bootstrapped = true
    }
}

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var petVM: PetViewModel
    @EnvironmentObject private var timerVM: TimerViewModel

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)

            TimerView()
                .tabItem { Label("Focus", systemImage: "timer") }
                .tag(AppTab.timer)

            ShopView()
                .tabItem { Label("Shop", systemImage: "bag.fill") }
                .tag(AppTab.shop)

            ChatView()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(AppTab.chat)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(AppTab.profile)
        }
        .tint(Theme.accent)
    }
}
