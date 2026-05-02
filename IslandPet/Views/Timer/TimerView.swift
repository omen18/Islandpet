//
//  TimerView.swift
//  IslandPet
//
//  Premium redesign of the Pomodoro screen.
//
//  The challenge with focus timers: users stare at this screen for 25 minutes.
//  It needs to feel calming, alive, and not-boring all at once.
//
//  Design choices:
//   • The ring is the hero — dual-stroke (muted base + gradient progress),
//     soft inner glow that intensifies as progress approaches 100%.
//   • The pet sits inside the ring with breathing motion. During focus,
//     it switches to "focusing" mood (subtle posture lean) — visible
//     state change that confirms the session is real.
//   • Ambient particle drift behind the pet during a session, paused at
//     idle. This is the "alive but not overwhelming" balance.
//   • The time digits use `.contentTransition(.numericText())` so seconds
//     don't jump — they blend.
//   • Background subtly dims during focus (`focusDim`), mimicking how
//     the world recedes when you're concentrating.
//

import SwiftUI

struct TimerView: View {
    @EnvironmentObject private var petVM: PetViewModel
    @EnvironmentObject private var timerVM: TimerViewModel

    private let presets = [15, 25, 45, 60]

    @State private var lastCompletedXP: Int = 0
    @State private var showCelebration: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var awaitingEvolutionDismiss: Bool = false
    @State private var ringPulse: CGFloat = 1.0

    var body: some View {
        ZStack {
            BackgroundAurora()

            // Subtle dim during focus — frames the ring as the only bright object.
            Color.black
                .opacity(timerVM.phase == .focusing ? 0.18 : 0)
                .ignoresSafeArea()
                .animation(.iSoft, value: timerVM.phase)

            VStack(spacing: Tokens.Space.l) {
                header
                ringDial
                taskField
                presetRow
                controls
                Spacer()
            }
            .padding(.horizontal, Tokens.Space.l)
            .padding(.top, Tokens.Space.s + 4)
        }
        .onChange(of: timerVM.phase) { _, new in
            if new == .completed {
                let xp = (Int(timerVM.totalDuration) / 60) + 25
                lastCompletedXP = xp
                HapticsService.shared.levelUp()

                // If this XP push triggered an evolution, the cinematic owns the
                // moment. Defer our celebration sheet until the cinematic dismisses.
                // Otherwise show the sheet right away.
                if petVM.pendingEvolution != nil {
                    awaitingEvolutionDismiss = true
                } else {
                    showCelebration = true
                }
            }
        }
        .onChange(of: petVM.pendingEvolution) { _, new in
            // Cinematic just dismissed (became nil) and we were waiting → present
            // the celebration sheet now.
            if new == nil && awaitingEvolutionDismiss {
                awaitingEvolutionDismiss = false
                // Slight delay so the cover-dismiss animation finishes first.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showCelebration = true
                }
            }
        }
        .sheet(isPresented: $showCelebration) {
            CelebrationSheet(
                xp: lastCompletedXP,
                streak: petVM.settings?.currentStreak ?? 0,
                petName: petVM.pet?.name ?? "your pet",
                species: petVM.pet?.species ?? .flameSprite,
                stage: petVM.pet?.stage ?? .egg,
                onAgain: {
                    showCelebration = false
                    timerVM.start()
                },
                onDone: { showCelebration = false },
                onShare: {
                    // Defer the share sheet so the celebration sheet can dismiss
                    // first; iOS gets confused presenting two sheets at once.
                    showCelebration = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showShareSheet = true
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showShareSheet) {
            if let pet = petVM.pet {
                ShareableSessionCard(
                    pet: pet,
                    xp: lastCompletedXP,
                    streak: petVM.settings?.currentStreak ?? 0
                )
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Tokens.Space.xs) {
            Text("Focus")
                .font(Theme.display(28))
            Text(headlineCopy)
                .font(Theme.body())
                .foregroundStyle(Theme.text.secondary)
                .contentTransition(.opacity)
                .animation(.iSmooth, value: timerVM.phase)
        }
        .padding(.top, Tokens.Space.m)
    }

    private var headlineCopy: String {
        switch timerVM.phase {
        case .focusing:  return "Your pet is concentrating with you"
        case .completed: return "Beautiful work — XP awarded"
        case .paused:    return "Paused"
        case .breakTime: return "Take a breath"
        case .idle:
            // Personality-driven idle copy — feels personal
            if let pet = petVM.pet { return PetVoice(pet: pet).idleHint() }
            return "Pick a duration and begin"
        }
    }

    // MARK: - Ring Dial (the centerpiece)

    private var ringDial: some View {
        ZStack {
            // Particle ambient layer (behind pet, in front of ring base)
            if timerVM.phase == .focusing {
                AmbientParticleLayer(
                    tint: Color(hex: petVM.pet?.species.primaryHex ?? "B58BFF") ?? Theme.accent
                )
                .frame(width: 260, height: 260)
                .clipShape(Circle())
                .transition(.opacity)
            }

            // Muted base ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.gray.opacity(0.08), .gray.opacity(0.20)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 18
                )

            // Progress ring (aurora gradient)
            Circle()
                .trim(from: 0, to: timerVM.progress)
                .stroke(Theme.auroraGradient,
                        style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.iSmooth, value: timerVM.progress)

            // Inner glow that intensifies near completion
            Circle()
                .stroke(Theme.accent.opacity(timerVM.progress * 0.35),
                        lineWidth: 3)
                .blur(radius: 14)
                .scaleEffect(0.92)
                .animation(.iSoft, value: timerVM.progress)

            // Pet + clock stack
            VStack(spacing: Tokens.Space.s) {
                if let pet = petVM.pet {
                    PetSprite(species: pet.species,
                              stage: pet.stage,
                              mood: petMoodForPhase(default: pet.mood),
                              size: 90)
                        .frame(height: 110)
                        .breathing(amplitude: timerVM.phase == .focusing ? 3 : 5,
                                   period: timerVM.phase == .focusing ? 1.6 : 2.4)
                }
                Text(timerVM.formattedRemaining)
                    .font(Theme.mono(40))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(Theme.text.primary)
            }
        }
        .frame(width: 280, height: 280)
        .padding(.vertical, Tokens.Space.s)
        .scaleEffect(ringPulse)
        .onAppear {
            // Tiny entrance pulse — sets the tone
            ringPulse = 0.94
            withAnimation(.iBouncy.delay(0.1)) {
                ringPulse = 1.0
            }
        }
    }

    private func petMoodForPhase(
        default fallback: PetActivityAttributes.PetState.Mood
    ) -> PetActivityAttributes.PetState.Mood {
        switch timerVM.phase {
        case .focusing:  return .focusing
        case .paused:    return .sleepy
        case .completed: return .celebrating
        default:         return fallback
        }
    }

    // MARK: - Task Field

    private var taskField: some View {
        TextField("What are you working on?", text: $timerVM.taskTitle)
            .font(Theme.body(16))
            .padding(.horizontal, Tokens.Space.m)
            .padding(.vertical, Tokens.Space.s + 4)
            .background(GlassCard())
            .disabled(timerVM.phase == .focusing)
            .opacity(timerVM.phase == .focusing ? 0.6 : 1.0)
            .animation(.iSmooth, value: timerVM.phase)
    }

    // MARK: - Presets

    private var presetRow: some View {
        HStack(spacing: Tokens.Space.s + 2) {
            ForEach(presets, id: \.self) { mins in
                PresetChip(minutes: mins,
                           selected: isCurrent(mins),
                           disabled: timerVM.phase == .focusing) {
                    timerVM.setMinutes(mins)
                    HapticsService.shared.tap()
                }
            }
        }
    }

    private func isCurrent(_ mins: Int) -> Bool {
        Int(timerVM.totalDuration / 60) == mins
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: Tokens.Space.s + 4) {
            switch timerVM.phase {
            case .idle, .completed:
                PrimaryButton(title: "Start", systemImage: "play.fill") {
                    timerVM.start()
                }
            case .focusing:
                SecondaryButton(title: "Pause", systemImage: "pause.fill") { timerVM.pause() }
                StopButton { timerVM.cancel() }
            case .paused:
                PrimaryButton(title: "Resume", systemImage: "play.fill") { timerVM.start() }
                StopButton { timerVM.cancel() }
            case .breakTime:
                EmptyView()
            }
        }
        .animation(.iSmooth, value: timerVM.phase)
    }
}

// MARK: - Preset Chip

private struct PresetChip: View {
    let minutes: Int
    let selected: Bool
    let disabled: Bool
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            Text("\(minutes)m")
                .font(Theme.title(15))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Tokens.Space.s + 2)
                .foregroundStyle(selected ? Theme.text.onAccent : Theme.accent)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(selected
                              ? AnyShapeStyle(Theme.auroraGradient)
                              : AnyShapeStyle(Theme.accent.opacity(0.12)))
                )
                .scaleEffect(pressed ? 0.95 : 1)
                .animation(.iSnap, value: pressed)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
        .pressEvents(onPress: { pressed = true }, onRelease: { pressed = false })
    }
}

// MARK: - Stop Button

private struct StopButton: View {
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(role: .destructive, action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .padding(Tokens.Space.m)
                .background(Circle().fill(Theme.danger))
                .elevated(.raised)
                .scaleEffect(pressed ? 0.94 : 1)
                .animation(.iSnap, value: pressed)
        }
        .pressEvents(onPress: { pressed = true }, onRelease: { pressed = false })
    }
}

// MARK: - Ambient Particles

/// Slow drifting motes behind the pet during a focus session.
/// Implemented with TimelineView + Canvas — extremely cheap, looks alive.
private struct AmbientParticleLayer: View {
    let tint: Color

    var body: some View {
        TimelineView(.animation) { ctx in
            Canvas { context, size in
                let t = ctx.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 240)
                let count = 18
                for i in 0..<count {
                    let phase = Double(i) / Double(count)
                    let speed = 8 + Double(i % 4) * 4
                    let yProgress = (t * 0.012 + phase).truncatingRemainder(dividingBy: 1)
                    let y = size.height * (1 - yProgress)
                    let x = size.width / 2
                        + cos(t * 0.4 + phase * .pi * 2) * (60 + Double(i % 3) * 18)
                    let r = 2.0 + Double(i % 3)
                    let alpha = sin(yProgress * .pi) * 0.55
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: rect),
                                 with: .color(tint.opacity(alpha)))
                    _ = speed
                }
            }
        }
    }
}

// MARK: - Celebration Sheet

private struct CelebrationSheet: View {
    let xp: Int
    let streak: Int
    let petName: String
    let species: PetSpecies
    let stage: EvolutionStage
    let onAgain: () -> Void
    let onDone: () -> Void
    let onShare: () -> Void

    @State private var displayedXP: Int = 0

    var body: some View {
        VStack(spacing: Tokens.Space.l) {
            Spacer().frame(height: Tokens.Space.s)

            PetSprite(species: species, stage: stage, mood: .celebrating, size: 130)
                .breathing(amplitude: 6, period: 0.9)

            VStack(spacing: Tokens.Space.s) {
                Text("+\(displayedXP) XP")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.auroraGradient)
                    .contentTransition(.numericText())
                Text("\(petName) is thrilled.")
                    .font(Theme.title(17))
                    .foregroundStyle(Theme.text.secondary)
            }
            .onAppear { animateXP() }

            HStack(spacing: Tokens.Space.s + 4) {
                Label("\(streak)-day streak", systemImage: "flame.fill")
                    .pill(Theme.secondary)
                Label("+10 coins", systemImage: "circle.hexagongrid.fill")
                    .pill(Theme.secondary)
            }

            Spacer()

            VStack(spacing: Tokens.Space.s + 2) {
                PrimaryButton(title: "One more session",
                              systemImage: "arrow.clockwise") { onAgain() }
                HStack(spacing: Tokens.Space.l) {
                    Button("Done", action: onDone)
                        .font(Theme.body(16))
                        .foregroundStyle(Theme.text.secondary)

                    // Share button only appears once the streak is meaningful.
                    // Asking users to share their first session reads as desperate.
                    if streak >= 3 {
                        Button {
                            HapticsService.shared.tap()
                            onShare()
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(Theme.body(16))
                                .foregroundStyle(Theme.text.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, Tokens.Space.l)
            .padding(.bottom, Tokens.Space.xl)
        }
        .padding(.top, Tokens.Space.m)
        .background(BackgroundAurora())
        .confetti(on: xp)
    }

    private func animateXP() {
        let steps = 30
        let step = max(1, xp / steps)
        Task { @MainActor in
            var current = 0
            while current < xp {
                current = min(current + step, xp)
                withAnimation(.linear(duration: 1.0 / Double(steps))) {
                    displayedXP = current
                }
                try? await Task.sleep(nanoseconds: 33_000_000)
            }
        }
    }
}

// MARK: - Shareable session card
//
// Presented after a successful session when the user has a meaningful streak.
// Renders a 1080×1920 image suitable for IG / TikTok stories. Users posting
// these is the entire organic-growth strategy.

private struct ShareableSessionCard: View {
    let pet: Pet
    let xp: Int
    let streak: Int

    @State private var renderedImage: UIImage?
    @State private var showSystemShare = false

    var body: some View {
        VStack(spacing: Tokens.Space.l) {
            Spacer().frame(height: Tokens.Space.s)

            cardContent
                .frame(width: 320, height: 480)
                .background(
                    RoundedRectangle(cornerRadius: Tokens.Radius.l, style: .continuous)
                        .fill(Theme.nightGradient)
                )
                .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.l, style: .continuous))
                .elevated(.hero)
                .padding(.horizontal, Tokens.Space.l)

            Spacer()

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
            .padding(.bottom, Tokens.Space.l)
        }
        .background(BackgroundAurora())
        .sheet(isPresented: $showSystemShare) {
            if let image = renderedImage {
                ActivityShareSheet(items: [
                    image,
                    "Day \(streak) on IslandPet 💜"
                ])
            }
        }
    }

    private var cardContent: some View {
        VStack(spacing: 0) {
            HStack {
                Text("ISLANDPET")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
                Label("\(streak)", systemImage: "flame.fill")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)

            Spacer(minLength: 0)

            PetSprite(species: pet.species, stage: pet.stage,
                      mood: .celebrating, size: 160)
                .frame(width: 180, height: 200)

            Spacer(minLength: 0)

            VStack(spacing: 6) {
                Text("+\(xp) XP")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text("\(pet.name) · Day \(streak)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(.bottom, 36)
        }
    }

    @MainActor
    private func renderAndShare() {
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
