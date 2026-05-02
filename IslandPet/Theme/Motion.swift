//
//  Motion.swift
//  IslandPet
//
//  The motion design system. Every animation in IslandPet pulls from this
//  file. The goal is consistency: a button press, a card slide, and a pet
//  bounce should all feel like they came from the same designer's hand.
//
//  Each curve is named after its emotional intent — not its math — so view
//  code reads as design intent: `.animation(.iceland(.warm), …)`.
//
//  Reference: Apple's HIG Motion guidelines + The Illusion of Life (Disney
//  animation principles, esp. anticipation & follow-through).
//

import SwiftUI

extension Animation {

    /// Snap with a tiny overshoot. For taps, toggles, button presses.
    /// Fast enough that it never makes the user wait.
    static let iSnap = Animation.spring(response: 0.32, dampingFraction: 0.72)

    /// Smooth, settled. For cards entering, sheets dragging, list reorders.
    /// The "default" motion of the app.
    static let iSmooth = Animation.spring(response: 0.48, dampingFraction: 0.86)

    /// Soft, generous. For full-screen transitions, modal reveals, evolution
    /// reveals. Gives the user time to register the change.
    static let iSoft = Animation.spring(response: 0.65, dampingFraction: 0.82)

    /// Bouncy, playful. For celebrations, level-ups, the pet itself.
    /// Use sparingly — it's the "loud" voice in the system.
    static let iBouncy = Animation.spring(response: 0.42, dampingFraction: 0.58)

    /// Hard pop with overshoot. For evolution flash, achievement unlocks,
    /// the rare moment the app needs to interrupt the user with joy.
    static let iPop = Animation.spring(response: 0.38, dampingFraction: 0.50)

    /// Slow, breathing. For ambient idle motion (pet bobbing, background
    /// aurora drift, "alive" feel). Uses a long ease, not a spring.
    static let iBreath = Animation.easeInOut(duration: 2.4)

    /// Tense, restrained. For pet-sad states, paused timers, "something
    /// is wrong" feedback. Slower than iSmooth, narrower amplitude.
    static let iTense = Animation.easeInOut(duration: 0.55)
}

// MARK: - Reusable choreographies

/// A staggered cascade animation. Apply to a list to make children fade-and-rise
/// in sequence — used on Home cards, Shop items, and Profile sections.
struct CascadeIn: ViewModifier {
    let index: Int
    let baseDelay: Double
    let perItemDelay: Double
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 12)
            .animation(.iSmooth.delay(baseDelay + Double(index) * perItemDelay),
                       value: visible)
            .onAppear { visible = true }
    }
}

extension View {
    /// `.cascadeIn(index: i)` on each child of a stack produces a polished
    /// staggered entrance. Index drives the per-item delay.
    func cascadeIn(index: Int,
                   baseDelay: Double = 0.05,
                   perItemDelay: Double = 0.06) -> some View {
        modifier(CascadeIn(index: index,
                           baseDelay: baseDelay,
                           perItemDelay: perItemDelay))
    }
}

/// Applies a subtle "breathing" scale + offset to a view. Used on the home
/// pet, the egg in onboarding, and the evolution preview.
struct BreathingMotion: ViewModifier {
    var amplitude: CGFloat = 4
    var period: Double = 2.4
    @State private var phase = false

    func body(content: Content) -> some View {
        content
            .offset(y: phase ? -amplitude : amplitude)
            .scaleEffect(phase ? 1.012 : 0.988)
            .animation(.easeInOut(duration: period).repeatForever(autoreverses: true),
                       value: phase)
            .onAppear { phase = true }
    }
}

extension View {
    func breathing(amplitude: CGFloat = 4, period: Double = 2.4) -> some View {
        modifier(BreathingMotion(amplitude: amplitude, period: period))
    }
}

/// One-shot "press down" feedback. Composes with PressEventsModifier from
/// Components.swift; this version is the visual half (a scale + tiny drop).
struct PressFeedback: ViewModifier {
    @State private var pressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(pressed ? 0.96 : 1.0)
            .animation(.iSnap, value: pressed)
            .pressEvents(
                onPress: { pressed = true },
                onRelease: { pressed = false }
            )
    }
}

extension View {
    /// Drop-in tactile feedback for any tappable view that isn't already a
    /// styled Button.
    func pressFeedback() -> some View {
        modifier(PressFeedback())
    }
}

/// A "shimmer" sweep used on locked items, evolution previews, and rare-drop
/// affordances. Hint of the premium without leaving HIG territory.
struct ShimmerOverlay: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear,
                                 .white.opacity(0.35),
                                 .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blendMode(.plusLighter)
                    .mask(content)
                    .offset(x: phase * geo.size.width * 1.5)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    func shimmer() -> some View { modifier(ShimmerOverlay()) }
}

/// Confetti-on-event modifier. Triggers a one-shot particle burst when the
/// observed value changes. Intentionally lightweight (Canvas, not SpriteKit)
/// so it composes anywhere.
struct ConfettiBurst<T: Equatable>: ViewModifier {
    let trigger: T
    @State private var burstID: UUID?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .center) {
                if let id = burstID {
                    ConfettiCanvas()
                        .id(id)
                        .allowsHitTesting(false)
                }
            }
            .onChange(of: trigger) { _, _ in
                burstID = UUID()
                Task {
                    try? await Task.sleep(nanoseconds: 1_400_000_000)
                    await MainActor.run { burstID = nil }
                }
            }
    }
}

extension View {
    /// Fires confetti when `value` changes. Use sparingly — confetti is the
    /// loudest visual the app owns.
    func confetti<T: Equatable>(on value: T) -> some View {
        modifier(ConfettiBurst(trigger: value))
    }
}

private struct ConfettiCanvas: View {
    var body: some View {
        TimelineView(.animation) { ctx in
            Canvas { context, size in
                let t = ctx.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 60)
                var rng = StableRNG(seed: 1)
                let count = 80
                let life = 1.4
                let elapsed = t.truncatingRemainder(dividingBy: life)
                let life01 = elapsed / life

                for _ in 0..<count {
                    let angle = rng.next() * .pi * 2
                    let speed = 140 + rng.next() * 220
                    let gravity = 380 * life01 * life01
                    let cx = size.width / 2 + cos(angle) * speed * life01
                    let cy = size.height / 2 + sin(angle) * speed * life01 + gravity
                    let r = 3.0 + rng.next() * 4.0
                    let alpha = max(0, 1 - life01)
                    let hue = rng.next()
                    let color = Color(hue: hue, saturation: 0.85, brightness: 1.0)
                    let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: rect),
                                 with: .color(color.opacity(alpha)))
                }
            }
        }
    }
}

private struct StableRNG {
    var state: UInt64
    init(seed: Int) {
        // Mixed enough not to look striped at low counts.
        let s = UInt64(bitPattern: Int64(seed &* 2654435761))
        self.state = (s == 0 ? 0xDEADBEEF : s)
    }
    mutating func next() -> Double {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Double(state % 10_000) / 10_000.0
    }
}
