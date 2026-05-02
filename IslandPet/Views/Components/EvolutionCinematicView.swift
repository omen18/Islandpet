//
//  EvolutionCinematicView.swift
//  IslandPet
//
//  Full-screen take-over when the pet evolves. The single most important
//  retention + virality moment in the app:
//   • dramatic build-up (shake → flash → particle burst → reveal)
//   • haptic chord on the reveal beat
//   • share sheet pre-filled so users can post the moment
//
//  Presented from RootView so it sits above tabs.
//

import SwiftUI

struct EvolutionCinematicView: View {

    let species: PetSpecies
    let oldStage: EvolutionStage
    let newStage: EvolutionStage
    let petName: String
    var pendingTraits: PetTraits? = nil
    let onDismiss: () -> Void

    @State private var phase: Phase = .anticipation
    @State private var shake: CGFloat = 0
    @State private var flashOpacity: Double = 0
    @State private var revealScale: CGFloat = 0.2
    @State private var revealOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var sparkleSeed: Int = 0
    @State private var showShareSheet = false

    enum Phase { case anticipation, flash, reveal, settled }

    var body: some View {
        ZStack {
            // Background dimming + radial pulse
            background

            // Particle burst on reveal
            if phase == .reveal || phase == .settled {
                ParticleBurstView(seed: sparkleSeed,
                                  tint: Color(hex: species.primaryHex) ?? .yellow)
                    .allowsHitTesting(false)
            }

            // The pet itself
            VStack(spacing: 24) {
                Spacer()

                Group {
                    if phase == .anticipation || phase == .flash {
                        // shaking egg
                        PetSprite(species: species, stage: oldStage,
                                  mood: .focusing, size: 220)
                            .offset(x: shake)
                    } else {
                        // revealed new form
                        PetSprite(species: species, stage: newStage,
                                  mood: .celebrating, size: 240)
                            .scaleEffect(revealScale)
                            .opacity(revealOpacity)
                    }
                }
                .frame(height: 280)

                if phase == .reveal || phase == .settled {
                    VStack(spacing: Tokens.Space.s) {
                        Text("\(petName) evolved!")
                            .font(Theme.display(34))
                            .foregroundStyle(.white)
                        Text("\(oldStage.rawValue.capitalized) → \(newStage.rawValue.capitalized)")
                            .font(Theme.title(18))
                            .foregroundStyle(.white.opacity(0.85))

                        // Personality reveal — only on the egg→baby beat,
                        // which is the most emotional evolution because
                        // it's where the pet first gets a "self".
                        if oldStage == .egg, let traits = pendingTraits {
                            Text("a \(traits.summary) \(species.displayName.lowercased())")
                                .font(Theme.body(15))
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.top, Tokens.Space.xs)
                                .transition(.opacity)
                        }
                    }
                    .opacity(titleOpacity)
                    .multilineTextAlignment(.center)
                }

                Spacer()

                if phase == .settled {
                    VStack(spacing: Tokens.Space.s + 4) {
                        Button {
                            HapticsService.shared.bump()
                            showShareSheet = true
                        } label: {
                            Label("Share the moment", systemImage: "square.and.arrow.up")
                                .font(Theme.title(17))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Tokens.Space.m)
                                .background(.white)
                                .foregroundStyle(.black)
                                .clipShape(RoundedRectangle(cornerRadius: Tokens.Radius.l,
                                                            style: .continuous))
                                .innerHighlight(radius: Tokens.Radius.l)
                        }

                        Button("Continue") {
                            HapticsService.shared.tap()
                            onDismiss()
                        }
                        .font(Theme.body(16))
                        .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.horizontal, Tokens.Space.xl)
                    .padding(.bottom, Tokens.Space.xl + 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            // Flash overlay (above pet, below particles)
            Color.white
                .ignoresSafeArea()
                .opacity(flashOpacity)
                .allowsHitTesting(false)
        }
        .background(.black)
        .ignoresSafeArea()
        .onAppear { runSequence() }
        .sheet(isPresented: $showShareSheet) {
            ActivityShareSheet(items: [shareText, shareImage].compactMap { $0 as Any? })
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            RadialGradient(
                colors: [
                    (Color(hex: species.primaryHex) ?? .purple).opacity(0.6),
                    .black
                ],
                center: .center, startRadius: 20,
                endRadius: phase == .reveal || phase == .settled ? 700 : 200
            )
            .animation(.easeOut(duration: 0.8), value: phase)
        }
    }

    // MARK: - Sequence

    private func runSequence() {
        // 1. Anticipation — egg shakes for 1.5s, with haptics
        Task { @MainActor in
            for i in 0..<6 {
                withAnimation(.easeInOut(duration: 0.12)) {
                    shake = i.isMultiple(of: 2) ? -10 : 10
                }
                HapticsService.shared.tap()
                try? await Task.sleep(nanoseconds: 230_000_000)
            }
            withAnimation(.easeOut(duration: 0.15)) { shake = 0 }

            // 2. Flash
            phase = .flash
            HapticsService.shared.thunk()
            withAnimation(.easeIn(duration: 0.08)) { flashOpacity = 1 }
            try? await Task.sleep(nanoseconds: 120_000_000)
            withAnimation(.easeOut(duration: 0.4)) { flashOpacity = 0 }

            // 3. Reveal
            phase = .reveal
            sparkleSeed = Int.random(in: 0..<10_000)
            HapticsService.shared.evolve()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                revealScale = 1.0
                revealOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                titleOpacity = 1
            }
            try? await Task.sleep(nanoseconds: 1_400_000_000)

            // 4. Settle — show CTAs
            withAnimation(.smooth(duration: 0.4)) {
                phase = .settled
            }
        }
    }

    // MARK: - Sharing

    private var shareText: String {
        "My pet just evolved into a \(newStage.rawValue) on IslandPet 🐣✨ #IslandPet"
    }

    /// Renders a snapshot of the pet for sharing. Falls back to nil so we
    /// still send the text-only share if rendering fails.
    @MainActor
    private var shareImage: UIImage? {
        let renderer = ImageRenderer(content:
            ZStack {
                LinearGradient(colors: [
                    Color(hex: species.primaryHex) ?? .purple,
                    .black
                ], startPoint: .top, endPoint: .bottom)
                VStack(spacing: 16) {
                    PetSprite(species: species, stage: newStage,
                              mood: .happy, size: 280)
                    Text("\(petName)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("evolved on IslandPet")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .frame(width: 1080, height: 1920)
        )
        renderer.scale = 1
        return renderer.uiImage
    }
}

// MARK: - Particle Burst

private struct ParticleBurstView: View {
    let seed: Int
    let tint: Color

    var body: some View {
        TimelineView(.animation) { ctx in
            Canvas { context, size in
                let t = ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 5)
                var rng = SeededRNG(seed: seed)
                let count = 60
                for _ in 0..<count {
                    let angle = rng.next() * .pi * 2
                    let speed = 80 + rng.next() * 220
                    let life: Double = 1.6
                    let life01 = min(t / life, 1.0)
                    let x = size.width / 2 + cos(angle) * speed * life01
                    let y = size.height / 2 + sin(angle) * speed * life01
                    let r = 3 + rng.next() * 5
                    let alpha = 1 - life01
                    let dot = Path(ellipseIn: CGRect(x: x - r, y: y - r,
                                                     width: r * 2, height: r * 2))
                    context.fill(dot,
                                 with: .color(tint.opacity(alpha)))
                }
            }
        }
    }
}

private struct SeededRNG {
    var state: UInt64
    init(seed: Int) { self.state = UInt64(bitPattern: Int64(seed &* 2654435761)) | 1 }
    mutating func next() -> Double {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Double(state % 10_000) / 10_000.0
    }
}

// MARK: - Share sheet wrapper

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
