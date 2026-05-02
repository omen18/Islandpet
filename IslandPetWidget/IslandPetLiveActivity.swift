//
//  IslandPetLiveActivity.swift
//  IslandPetWidgetExtension
//
//  Dynamic Island + Lock Screen Live Activity for active focus sessions.
//  Visualizes the pet's mood, XP, hunger, and a live countdown.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct IslandPetLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PetActivityAttributes.self) { ctx in
            // Lock Screen / Banner UI
            LockScreenLiveView(attributes: ctx.attributes, state: ctx.state)
                .activityBackgroundTint(Color(white: 0.05))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { ctx in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        StageBadge(stage: ctx.attributes.evolutionStage,
                                   mood: ctx.state.mood)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ctx.attributes.petName)
                                .font(.system(size: 14, weight: .bold))
                            Text("Lv \(ctx.state.level)")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let end = ctx.state.sessionEndsAt {
                        Text(timerInterval: Date()...end, countsDown: true)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    } else {
                        Text(moodTitle(ctx.state.mood))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    if ctx.state.sessionEndsAt != nil {
                        Text(moodTitle(ctx.state.mood))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let start = ctx.state.sessionStartedAt,
                       let end = ctx.state.sessionEndsAt {
                        VStack(spacing: 6) {
                            ProgressView(timerInterval: start...end, countsDown: false)
                                .tint(moodColor(ctx.state.mood))
                            Button(intent: StopFocusIntent()) {
                                Label("Stop", systemImage: "stop.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red.opacity(0.85))
                            .controlSize(.small)
                        }
                    } else {
                        HStack {
                            Label("\(ctx.state.streakDays)", systemImage: "flame.fill")
                                .foregroundStyle(.orange)
                            Spacer()
                            Label("\(Int(ctx.state.hunger * 100))%", systemImage: "fork.knife")
                                .foregroundStyle(.brown)
                            Spacer()
                            Label("\(ctx.state.xp) XP", systemImage: "star.fill")
                                .foregroundStyle(.yellow)
                        }
                        .font(.system(size: 11, weight: .semibold))
                    }
                }
            } compactLeading: {
                ZStack {
                    Circle()
                        .fill(moodColor(ctx.state.mood).opacity(0.30))
                        .frame(width: 22, height: 22)
                    Text(emojiForStage(ctx.attributes.evolutionStage))
                        .font(.system(size: 14))
                }
            } compactTrailing: {
                if let end = ctx.state.sessionEndsAt {
                    Text(timerInterval: Date()...end, countsDown: true)
                        .monospacedDigit()
                        .frame(width: 44)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(moodColor(ctx.state.mood))
                } else {
                    Text(shortMood(ctx.state.mood))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(moodColor(ctx.state.mood))
                }
            } minimal: {
                Text(emojiForStage(ctx.attributes.evolutionStage))
                    .font(.system(size: 14))
            }
            .keylineTint(moodColor(ctx.state.mood))
        }
    }
}

// MARK: - Lock screen banner

struct LockScreenLiveView: View {
    let attributes: PetActivityAttributes
    let state: PetActivityAttributes.PetState

    var body: some View {
        HStack(spacing: 14) {
            StageBadge(stage: attributes.evolutionStage, mood: state.mood, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(attributes.petName).font(.system(size: 16, weight: .bold))
                Text(captionText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                if let start = state.sessionStartedAt,
                   let end = state.sessionEndsAt {
                    ProgressView(timerInterval: start...end, countsDown: false)
                        .tint(moodColor(state.mood))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let end = state.sessionEndsAt {
                    Text(timerInterval: Date()...end, countsDown: true)
                        .monospacedDigit()
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                }
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill").foregroundStyle(.orange)
                    Text("\(state.streakDays)")
                }
                .font(.system(size: 11, weight: .semibold))
            }
        }
        .padding(14)
    }

    private var captionText: String {
        switch state.mood {
        case .focusing:    return "Focusing with you"
        case .happy:       return "Feeling great"
        case .sleepy:      return "A little sleepy"
        case .sad:         return "Could use some attention"
        case .celebrating: return "Session complete!"
        case .idle:        return "Hanging out"
        }
    }
}

// MARK: - Stage Badge

struct StageBadge: View {
    let stage: String
    let mood: PetActivityAttributes.PetState.Mood
    var size: CGFloat = 36
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [moodColor(mood), moodColor(mood).opacity(0.5)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size, height: size)
                .shadow(color: moodColor(mood).opacity(0.4), radius: 6)
            Text(emojiForStage(stage))
                .font(.system(size: size * 0.6))
        }
    }
}

// MARK: - Helpers (file-private)

func emojiForStage(_ s: String) -> String {
    switch s {
    case "egg": return "🥚"
    case "baby": return "🐣"
    case "teen": return "🐥"
    case "adult": return "🐉"
    default: return "🐣"
    }
}

func moodColor(_ m: PetActivityAttributes.PetState.Mood) -> Color {
    switch m {
    case .focusing:    return .purple
    case .happy:       return .pink
    case .sleepy:      return .indigo
    case .sad:         return .blue
    case .celebrating: return .yellow
    case .idle:        return .mint
    }
}

func moodTitle(_ m: PetActivityAttributes.PetState.Mood) -> String {
    switch m {
    case .focusing:    return "Focusing"
    case .happy:       return "Happy"
    case .sleepy:      return "Sleepy"
    case .sad:         return "Sad"
    case .celebrating: return "Done!"
    case .idle:        return "Idle"
    }
}

func shortMood(_ m: PetActivityAttributes.PetState.Mood) -> String {
    switch m {
    case .focusing:    return "🎯"
    case .happy:       return "✨"
    case .sleepy:      return "💤"
    case .sad:         return "💧"
    case .celebrating: return "🎉"
    case .idle:        return "•"
    }
}
