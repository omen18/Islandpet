//
//  RootView.swift
//  IslandPet
//

import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var context

    var body: some View {
        ZStack {
            if appState.hasOnboarded {
                // The shell owns the VMs as @StateObjects and is created
                // exactly once per onboarded session.
                AppShell()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 1.05)),
                        removal: .opacity
                    ))
            } else {
                OnboardingFlow()
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.6), value: appState.hasOnboarded)
        .task { bootstrap() }
    }

    /// Make sure an AppSettings row exists so child views can rely on it.
    private func bootstrap() {
        let descriptor = FetchDescriptor<AppSettings>()
        if (try? context.fetch(descriptor).first) == nil {
            context.insert(AppSettings())
            try? context.save()
        }
    }
}

/// Top-level UI state that doesn't belong in SwiftData.
@MainActor
final class AppState: ObservableObject {
    @Published var hasOnboarded: Bool = UserDefaults.standard.bool(forKey: "hasOnboarded")
    @Published var colorScheme: ColorScheme? = nil
    @Published var selectedTab: AppTab = .home

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasOnboarded")
        withAnimation(.smooth) { hasOnboarded = true }
    }

    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: "hasOnboarded")
        hasOnboarded = false
    }
}

enum AppTab: Hashable {
    case home, timer, shop, chat, profile
}
