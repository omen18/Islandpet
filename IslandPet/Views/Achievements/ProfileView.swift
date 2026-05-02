//
//  ProfileView.swift
//  IslandPet
//
//  Premium redesign of the Profile screen.
//
//  This is the *emotional payoff* screen. Users come here to see what
//  they've built — not to manage settings. Everything secondary (settings,
//  data) is pushed to the bottom or behind disclosure.
//
//  Design principles:
//   • Identity, not statistics. Personality shows as descriptive labels
//     ("affectionate night owl") never as 0–100 stat bars. Bars feel
//     like a video-game character sheet; labels feel like a description
//     of someone you know.
//   • Consistency, not cumulative. Streak heatmap shows the last 14 days
//     so users see "I show up" at a glance, more powerful than total XP.
//   • One shareable surface. The Personality Card (top-right tap) renders
//     an image users will post. Without this, no virality. With this,
//     every user is a marketing asset.
//
//  Section order (top to bottom is descending emotional weight):
//   1. Identity hero (pet + name + species + traits + level)
//   2. Streak card (current/longest/freezes + 14-day heatmap)
//   3. Achievements (compressed list, unlocked first)
//   4. Recent sessions (last 5)
//   5. Settings (collapsed/secondary)
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @EnvironmentObject private var petVM: PetViewModel
    @Environment(\.modelContext) private var context

    @Query(sort: [SortDescriptor(\Achievement.progress, order: .reverse),
                  SortDescriptor(\Achievement.title)])
    private var achievements: [Achievement]

    @Query(sort: \FocusSession.startedAt, order: .reverse)
    private var sessions: [FocusSession]

    @State private var showShareCard = false

    var body: some View {
        ZStack {
            BackgroundAurora()

            ScrollView {
                VStack(spacing: Tokens.Space.l) {
                    identityHero
                        .cascadeIn(index: 0)
                    streakCard
                        .cascadeIn(index: 1)
                    achievementsSection
                        .cascadeIn(index: 2)
                    sessionsSection
                        .cascadeIn(index: 3)
                    settingsSection
                        .cascadeIn(index: 4)
                    Spacer(minLength: Tokens.Space.xxl)
                }
                .padding(.horizontal, Tokens.Space.m + 2)
                .padding(.top, Tokens.Space.s)
            }
        }
        .sheet(isPresented: $showShareCard) {
            if let pet = petVM.pet, let s = petVM.settings {
                PersonalityShareSheet(
                    pet: pet,
                    streak: s.currentStreak,
                    totalSessions: sessions.filter(\.completed).count
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Identity hero

    private var identityHero: some View {
        VStack(spacing: Tokens.Space.m) {
            // Top row: share button right
            HStack {
                Spacer()
                Button {
                    HapticsService.shared.tap()
                    showShareCard = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(Theme.accent.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share personality card")
            }

            if let pet = petVM.pet {
                PetSprite(species: pet.species,
                          stage: pet.stage,
                          mood: pet.mood,
                          size: 120)
                    .frame(height: 130)
                    .breathing(amplitude: 3, period: 2.6)

                VStack(spacing: 4) {
                    Text(pet.name)
                        .font(Theme.display(28))
                    Text("\(pet.species.displayName) · \(pet.stage.rawValue.capitalized)")
                        .font(Theme.caption())
                        .foregroundStyle(Theme.text.secondary)
                }

                // Personality summary label — single line, descriptive, never numeric
                Text(pet.traits.summary)
                    .font(Theme.body(13, weight: .medium))
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, Tokens.Space.m)
                    .padding(.vertical, Tokens.Space.xs + 2)
                    .background(
                        Capsule().fill(Theme.accent.opacity(0.12))
                    )

                // Level + XP progress
                LevelRow(level: pet.level,
                         xpInLevel: pet.xpIntoLevel,
                         xpForLevel: pet.xpForNextLevel)
                    .padding(.top, Tokens.Space.xs)
            }
        }
        .padding(Tokens.Space.l)
        .frame(maxWidth: .infinity)
        .glass(radius: Tokens.Radius.card, elevation: .raised)
    }

    // MARK: - Streak card

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.m) {
            HStack(spacing: Tokens.Space.l) {
                StreakStat(value: petVM.settings?.currentStreak ?? 0,
                           label: "Current",
                           tint: Tokens.Tangerine.amber600)
                Divider().frame(height: 44)
                StreakStat(value: petVM.settings?.longestStreak ?? 0,
                           label: "Longest",
                           tint: Theme.accent)
                Divider().frame(height: 44)
                StreakStat(value: petVM.settings?.streakFreezesAvailable ?? 0,
                           label: "Freezes",
                           tint: .cyan,
                           icon: "snowflake")
            }

            StreakHeatmap(sessions: sessions)
                .frame(height: 56)
        }
        .padding(Tokens.Space.m + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(radius: Tokens.Radius.card)
    }

    // MARK: - Achievements

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s + 2) {
            HStack {
                Text("Achievements").font(Theme.title(20))
                Spacer()
                Text("\(unlockedCount) / \(achievements.count)")
                    .font(Theme.caption())
                    .foregroundStyle(Theme.text.secondary)
            }

            VStack(spacing: Tokens.Space.s) {
                ForEach(achievements) { a in
                    AchievementRow(achievement: a)
                }
            }
        }
    }

    private var unlockedCount: Int {
        achievements.filter(\.isUnlocked).count
    }

    // MARK: - Sessions

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s + 2) {
            Text("Recent Sessions").font(Theme.title(20))

            if sessions.isEmpty {
                emptySessionState
            } else {
                VStack(spacing: Tokens.Space.s) {
                    ForEach(sessions.prefix(5)) { s in
                        SessionRow(session: s)
                    }
                }
            }
        }
    }

    private var emptySessionState: some View {
        VStack(spacing: Tokens.Space.s) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 26))
                .foregroundStyle(Theme.text.tertiary)
            Text("No sessions yet")
                .font(Theme.body(15, weight: .medium))
            Text("Start your first focus session to see your history.")
                .font(Theme.caption())
                .foregroundStyle(Theme.text.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Tokens.Space.l)
        .frame(maxWidth: .infinity)
        .glass()
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s + 2) {
            Text("Settings").font(Theme.title(20))

            if let s = petVM.settings {
                VStack(spacing: 0) {
                    SettingsToggleRow(
                        title: "Sound effects",
                        icon: "speaker.wave.2.fill",
                        tint: Theme.accent,
                        isOn: Binding(
                            get: { s.soundEnabled },
                            set: { s.soundEnabled = $0; try? context.save() }
                        )
                    )
                    Divider().padding(.leading, 56)
                    SettingsToggleRow(
                        title: "Haptics",
                        icon: "waveform.path",
                        tint: .pink,
                        isOn: Binding(
                            get: { s.hapticsEnabled },
                            set: { s.hapticsEnabled = $0; try? context.save() }
                        )
                    )
                    Divider().padding(.leading, 56)
                    SettingsToggleRow(
                        title: "Notifications",
                        icon: "bell.fill",
                        tint: Theme.secondary,
                        isOn: Binding(
                            get: { s.notificationsEnabled },
                            set: { s.notificationsEnabled = $0; try? context.save() }
                        )
                    )
                }
                .glass()
            }
        }
    }
}

// MARK: - Identity row pieces

private struct LevelRow: View {
    let level: Int
    let xpInLevel: Int
    let xpForLevel: Int

    var body: some View {
        VStack(spacing: Tokens.Space.xs) {
            HStack {
                Text("Level \(level)")
                    .font(Theme.title(15))
                    .foregroundStyle(Theme.accent)
                Spacer()
                Text("\(xpInLevel) / \(xpForLevel) XP")
                    .font(Theme.caption(12))
                    .foregroundStyle(Theme.text.secondary)
                    .monospacedDigit()
            }

            ProgressView(value: Double(xpInLevel),
                         total: Double(xpForLevel))
                .progressViewStyle(StatBarStyle(tint: Theme.accent))
                .frame(height: 8)
        }
        .padding(.horizontal, Tokens.Space.m)
        .padding(.vertical, Tokens.Space.s + 2)
        .background(
            RoundedRectangle(cornerRadius: Tokens.Radius.s, style: .continuous)
                .fill(Theme.accent.opacity(0.06))
        )
    }
}

// MARK: - Streak pieces

private struct StreakStat: View {
    let value: Int
    let label: String
    let tint: Color
    var icon: String = "flame.fill"

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
                Text("\(value)")
                    .font(Theme.display(28))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            Text(label)
                .font(Theme.micro())
                .foregroundStyle(Theme.text.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 14-day grid showing focus consistency. Each cell is one day; saturation
/// reflects total focus minutes that day. Today is rightmost.
private struct StreakHeatmap: View {
    let sessions: [FocusSession]

    private var dailyMinutes: [Int] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<14).reversed().map { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return 0 }
            let next = cal.date(byAdding: .day, value: 1, to: day) ?? day
            return sessions
                .filter { $0.startedAt >= day && $0.startedAt < next && $0.completed }
                .reduce(0) { $0 + ($1.actualDurationSeconds / 60) }
        }
    }

    var body: some View {
        let mins = dailyMinutes
        let maxVal = max(mins.max() ?? 0, 1)
        return VStack(alignment: .leading, spacing: 6) {
            Text("Last 14 days")
                .font(Theme.micro())
                .foregroundStyle(Theme.text.tertiary)
            HStack(spacing: 4) {
                ForEach(0..<mins.count, id: \.self) { i in
                    let intensity = Double(mins[i]) / Double(maxVal)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(cellColor(intensity: intensity, isToday: i == mins.count - 1))
                        .frame(maxWidth: .infinity)
                        .frame(height: 24)
                }
            }
        }
    }

    private func cellColor(intensity: Double, isToday: Bool) -> Color {
        if intensity == 0 {
            return Theme.text.tertiary.opacity(isToday ? 0.35 : 0.18)
        }
        // Map 0…1 to violet from soft to deep.
        return Theme.accent.opacity(0.25 + intensity * 0.65)
    }
}

// MARK: - Achievement row

private struct AchievementRow: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: Tokens.Space.s + 4) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked
                          ? Theme.secondary.opacity(0.18)
                          : Color.gray.opacity(0.12))
                Image(systemName: achievement.iconSystemName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(achievement.isUnlocked
                                     ? Theme.secondary
                                     : Theme.text.tertiary)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(Theme.body(15, weight: .semibold))
                    .foregroundStyle(achievement.isUnlocked ? .primary : Theme.text.tertiary)
                Text(achievement.subtitle)
                    .font(Theme.caption(12))
                    .foregroundStyle(Theme.text.secondary)
                    .lineLimit(1)
                if !achievement.isUnlocked {
                    ProgressView(value: achievement.progress)
                        .progressViewStyle(StatBarStyle(tint: Theme.accent))
                        .frame(height: 4)
                        .padding(.top, 2)
                }
            }

            Spacer()

            if achievement.isUnlocked {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Theme.success)
                    .font(.system(size: 18))
            } else {
                Text("\(achievement.current)/\(achievement.goal)")
                    .font(Theme.micro())
                    .foregroundStyle(Theme.text.tertiary)
                    .monospacedDigit()
            }
        }
        .padding(Tokens.Space.s + 4)
        .glass()
    }
}

// MARK: - Session row

private struct SessionRow: View {
    let session: FocusSession

    var body: some View {
        HStack(spacing: Tokens.Space.s + 4) {
            ZStack {
                Circle()
                    .fill(session.completed ? Theme.success.opacity(0.18) : Color.gray.opacity(0.12))
                Image(systemName: session.completed ? "checkmark" : "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(session.completed ? Theme.success : Theme.text.tertiary)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.taskTitle.isEmpty ? "Focus" : session.taskTitle)
                    .font(Theme.body(15, weight: .semibold))
                    .lineLimit(1)
                Text(session.startedAt, format: .dateTime.day().month().hour().minute())
                    .font(Theme.caption(12))
                    .foregroundStyle(Theme.text.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.actualDurationSeconds / 60)m")
                    .font(Theme.body(15, weight: .semibold))
                    .monospacedDigit()
                if session.completed {
                    Text("+\(session.xpEarned) XP")
                        .font(Theme.micro())
                        .foregroundStyle(Theme.success)
                } else {
                    Text("Cancelled")
                        .font(Theme.micro())
                        .foregroundStyle(Theme.text.tertiary)
                }
            }
        }
        .padding(Tokens.Space.s + 4)
        .glass()
    }
}

// MARK: - Settings toggle row

private struct SettingsToggleRow: View {
    let title: String
    let icon: String
    let tint: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: Tokens.Space.s + 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint.opacity(0.18))
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 32, height: 32)

            Text(title).font(Theme.body(15))

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.accent)
        }
        .padding(.horizontal, Tokens.Space.m)
        .padding(.vertical, Tokens.Space.s + 2)
    }
}

// MARK: - Personality share card

/// A self-contained "trading card" showing the pet's identity, traits, level
/// and streak. Renders to an image for sharing — this is the *one* surface
/// every IslandPet user can post and have it instantly identifiable as
/// IslandPet (visual signature).
struct PersonalityShareSheet: View {
    let pet: Pet
    let streak: Int
    let totalSessions: Int

    @State private var renderedImage: UIImage?
    @State private var showSystemShare = false

    var body: some View {
        VStack(spacing: Tokens.Space.l) {
            Spacer().frame(height: Tokens.Space.s)

            // Preview
            cardContent
                .frame(width: 320, height: 480)
                .background(
                    RoundedRectangle(cornerRadius: Tokens.Radius.l, style: .continuous)
                        .fill(Theme.nightGradient)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Tokens.Radius.l, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.l, style: .continuous))
                .elevated(.hero)
                .padding(.horizontal, Tokens.Space.l)

            Spacer()

            // Actions
            VStack(spacing: Tokens.Space.s + 4) {
                Button {
                    HapticsService.shared.bump()
                    renderAndShare()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(Theme.title(17))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Tokens.Space.m)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: Tokens.Radius.l, style: .continuous)
                                .fill(Theme.auroraGradient)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Tokens.Space.l)

                Text("A snapshot of \(pet.name)'s journey so far.")
                    .font(Theme.caption())
                    .foregroundStyle(Theme.text.secondary)
            }
            .padding(.bottom, Tokens.Space.l)
        }
        .background(BackgroundAurora())
        .sheet(isPresented: $showSystemShare) {
            if let image = renderedImage {
                ActivityShareSheet(items: [
                    image,
                    "Meet \(pet.name) on IslandPet 💜"
                ])
            }
        }
    }

    /// The actual card layout. Used both for on-screen preview and for image
    /// rendering (via ImageRenderer). Keep as a single view so they match.
    private var cardContent: some View {
        VStack(spacing: 0) {
            // Top: brand + species
            HStack {
                Text("ISLANDPET")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
                Text(pet.species.displayName.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)

            Spacer(minLength: 0)

            // Pet
            PetSprite(species: pet.species, stage: pet.stage,
                      mood: .happy, size: 180)
                .frame(width: 180, height: 200)

            Spacer(minLength: 0)

            // Name + traits
            VStack(spacing: 6) {
                Text(pet.name)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(pet.traits.summary)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.white.opacity(0.12)))
            }

            Spacer(minLength: 0)

            // Stats triplet
            HStack(spacing: 0) {
                CardStatColumn(value: "\(pet.level)", label: "Level")
                Divider().frame(height: 32).background(.white.opacity(0.15))
                CardStatColumn(value: "\(streak)", label: "Streak", icon: "flame.fill")
                Divider().frame(height: 32).background(.white.opacity(0.15))
                CardStatColumn(value: "\(totalSessions)", label: "Sessions")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 26)
        }
    }

    @MainActor
    private func renderAndShare() {
        // 9:16 — fits IG/TikTok stories. Pad with the night gradient so the
        // card sits centered in the story frame instead of being cropped.
        let renderer = ImageRenderer(content:
            ZStack {
                Theme.nightGradient
                cardContent
                    .frame(width: 720, height: 1080)
                    .background(
                        RoundedRectangle(cornerRadius: 56, style: .continuous)
                            .fill(Theme.nightGradient)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 56, style: .continuous)
                            .strokeBorder(.white.opacity(0.10), lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 56, style: .continuous))
                    .shadow(color: .black.opacity(0.5), radius: 40, y: 20)
            }
            .frame(width: 1080, height: 1920)
        )
        renderer.scale = 1.0
        renderedImage = renderer.uiImage
        showSystemShare = true
    }
}

private struct CardStatColumn: View {
    let value: String
    let label: String
    var icon: String? = nil

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.orange)
                }
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }
}
