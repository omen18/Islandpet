//
//  OnboardingFlow.swift
//  IslandPet
//
//  5-step onboarding optimized for D1 retention:
//   1. Welcome — emotional hook with bobbing egg
//   2. Promise — three-line value prop ("focus → grow → island")
//   3. Species pick — sets investment ("this pet is mine")
//   4. Name — peak ownership signal
//   5. Notifications — ask in context, with the pet doing the asking
//

import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var context
    @State private var page: Int = 0
    @State private var petName: String = ""
    @State private var selectedSpecies: PetSpecies = .flameSprite

    var body: some View {
        ZStack {
            BackgroundAurora()

            switch page {
            case 0: WelcomePage(next: next).transition(.slide)
            case 1: PromisePage(next: next).transition(.slide)
            case 2: SpeciesPage(selected: $selectedSpecies, next: next).transition(.slide)
            case 3: NamePage(name: $petName, next: next).transition(.slide)
            case 4: NotificationsPage(name: petName.isEmpty ? "your pet" : petName,
                                      species: selectedSpecies,
                                      finish: finish)
                    .transition(.slide)
            default: SummaryPage(name: petName, species: selectedSpecies, finish: finish)
                .transition(.slide)
            }

            // Step indicator
            VStack {
                Spacer()
                StepIndicator(total: 5, current: page).padding(.bottom, 110)
            }
            .allowsHitTesting(false)
        }
        .animation(.smooth(duration: 0.5), value: page)
    }

    private func next() { page = min(page + 1, 4) }

    private func finish() {
        let pet = Pet(name: petName.isEmpty ? "Buddy" : petName, species: selectedSpecies)
        context.insert(pet)

        let existing = try? context.fetch(FetchDescriptor<AppSettings>()).first
        let settings: AppSettings
        if let existing {
            settings = existing
        } else {
            settings = AppSettings()
            context.insert(settings)
        }
        settings.hasCompletedOnboarding = true

        try? context.save()
        AchievementService.shared.seedIfNeeded(in: context)
        WidgetSnapshotService.write(pet: pet, settings: settings)
        NotificationService.shared.scheduleStreakReminderIfNeeded()
        appState.completeOnboarding()
    }
}

// MARK: - Pages

private struct WelcomePage: View {
    let next: () -> Void
    @State private var bob: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🥚")
                .font(.system(size: 140))
                .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                .offset(y: bob ? -8 : 8)
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: bob)
                .onAppear { bob = true }

            VStack(spacing: 12) {
                Text("Meet your IslandPet")
                    .font(Theme.display(36))
                    .multilineTextAlignment(.center)
                Text("A tiny companion that grows when you focus — right inside your Dynamic Island.")
                    .font(Theme.body(18))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            PrimaryButton(title: "Get started", systemImage: "arrow.right") { next() }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
        }
    }
}

private struct PromisePage: View {
    let next: () -> Void

    private let promises: [(icon: String, title: String, body: String)] = [
        ("brain.head.profile", "Focus to grow",
         "Every Pomodoro session feeds your pet XP. They evolve as you build the habit."),
        ("sparkles", "Live in the Island",
         "Your pet appears in the Dynamic Island while you focus — happy, sleepy, or cheering you on."),
        ("flame.fill", "Streaks that feel earned",
         "Show up daily. Watch them grow. Miss a day and they'll miss you back.")
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)
            Text("Here's the deal").font(Theme.display(30))

            VStack(spacing: 18) {
                ForEach(0..<promises.count, id: \.self) { i in
                    let p = promises[i]
                    HStack(spacing: 16) {
                        Image(systemName: p.icon)
                            .font(.system(size: 28))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Theme.accent.opacity(0.15)))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(p.title).font(Theme.title(17))
                            Text(p.body).font(Theme.body(14))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(GlassCard())
                }
            }
            .padding(.horizontal, 20)

            Spacer()
            PrimaryButton(title: "Sounds good", systemImage: "arrow.right") { next() }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
        }
    }
}

private struct SpeciesPage: View {
    @Binding var selected: PetSpecies
    let next: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("Choose your companion")
                    .font(Theme.display(28))
                Text("Each has a different personality.")
                    .font(Theme.body())
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 60)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(PetSpecies.allCases, id: \.self) { sp in
                        SpeciesCard(species: sp, selected: selected == sp) {
                            withAnimation(.smooth) { selected = sp }
                            HapticsService.shared.tap()
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            PrimaryButton(title: "Continue", systemImage: "arrow.right") { next() }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
        }
    }
}

private struct SpeciesCard: View {
    let species: PetSpecies
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                PetSprite(species: species, stage: .baby, mood: .idle, size: 80)
                    .frame(height: 90)
                Text(species.displayName)
                    .font(Theme.title(17))
                Text(species.blurb)
                    .font(Theme.body(13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3, reservesSpace: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(GlassCard(selected: selected))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                    .strokeBorder(selected ? Theme.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(selected ? 1.02 : 1)
        .animation(.smooth, value: selected)
    }
}

private struct NamePage: View {
    @Binding var name: String
    let next: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🐣").font(.system(size: 90))
            Text("Give them a name").font(Theme.display(28))
            TextField("e.g. Mochi", text: $name)
                .textFieldStyle(.plain)
                .font(Theme.title(28))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .background(GlassCard())
                .padding(.horizontal, 24)
                .focused($focused)
                .onSubmit(next)
                .submitLabel(.next)

            Spacer()
            PrimaryButton(title: "Next", systemImage: "arrow.right",
                          enabled: !name.trimmingCharacters(in: .whitespaces).isEmpty) { next() }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
        }
        .onAppear { focused = true }
    }
}

private struct NotificationsPage: View {
    let name: String
    let species: PetSpecies
    let finish: () -> Void
    @State private var asking = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            PetSprite(species: species, stage: .egg, mood: .happy, size: 140)

            VStack(spacing: 10) {
                Text("\(name) wants to stay close")
                    .font(Theme.display(26))
                    .multilineTextAlignment(.center)
                Text("Allow notifications so they can ping you when it's time to focus or when your streak is at risk.")
                    .font(Theme.body())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()

            PrimaryButton(
                title: asking ? "Asking…" : "Allow notifications",
                systemImage: "bell.fill",
                enabled: !asking
            ) {
                Task {
                    asking = true
                    _ = await NotificationService.shared.requestAuthorizationIfNeeded()
                    asking = false
                    finish()
                }
            }
            .padding(.horizontal, 24)

            Button("Maybe later", action: finish)
                .font(Theme.body(15))
                .foregroundStyle(.secondary)
                .padding(.bottom, 50)
        }
    }
}

private struct SummaryPage: View {
    let name: String
    let species: PetSpecies
    let finish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            PetSprite(species: species, stage: .egg, mood: .happy, size: 140)
            Text("Say hi to \(name.isEmpty ? "your pet" : name)")
                .font(Theme.display(28))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Text("Complete focus sessions to hatch your egg and grow.")
                .font(Theme.body())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            PrimaryButton(title: "Begin", systemImage: "sparkles") { finish() }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
        }
    }
}

// MARK: - Step indicator

private struct StepIndicator: View {
    let total: Int
    let current: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? Theme.accent : Color.gray.opacity(0.3))
                    .frame(width: i == current ? 24 : 6, height: 6)
                    .animation(.smooth, value: current)
            }
        }
    }
}
