//
//  Components.swift
//  IslandPet
//
//  The reusable visual primitives. Every screen composes from this file.
//  If you find yourself styling a thing inline in a screen file, stop —
//  add it here first, then use it.
//
//  Components in this file:
//    GlassCard            — surface treatment for content blocks
//    PrimaryButton        — the only button users tap to commit
//    SecondaryButton      — alt action, glass-styled
//    PressEvents          — gesture sugar for tactile feedback
//    BackgroundAurora     — living, time-aware backdrop
//    StatPill             — labeled progress bar (mood/hunger/energy)
//    StatBarStyle         — bar-style ProgressView style
//    ToastView            — passive top-of-screen notice
//    XPGainBadge          — the +XP confetti micro-interaction
//
//  Design notes:
//   - Buttons are sized for thumb reach (≥44pt tap targets, HIG)
//   - All shadows go through `.elevated(.X)` from the design system
//   - All radii pull from Tokens.Radius
//   - All animations pull from Animation.iX in Motion.swift
//

import SwiftUI

// MARK: - Background

/// The living backdrop for every screen. Three innovations vs. a static
/// gradient:
///   1. Three drifting "aurora blobs" with different periods so the motion
///      never appears to repeat.
///   2. Hue subtly shifts by hour of day — warmer at sunset, cooler at
///      night. Users feel it without noticing.
///   3. Reduced-motion accessibility-aware: stops drifting when the user
///      has Reduce Motion enabled.
struct BackgroundAurora: View {
    @State private var phase = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            baseGradient.ignoresSafeArea()

            // Three blobs of different sizes, colors, periods.
            blob(color: blob1Color, size: 380, x: -100, y: -270, period: 8)
            blob(color: blob2Color, size: 320, x: 110,  y: -160, period: 11)
            blob(color: blob3Color, size: 360, x: -80,  y: 300,  period: 14)
        }
        .ignoresSafeArea()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                phase = true
            }
        }
    }

    private var baseGradient: LinearGradient {
        scheme == .dark ? Theme.surface.backgroundDark : Theme.surface.background
    }

    private var hour: Int {
        Calendar.current.component(.hour, from: .now)
    }

    /// Time-of-day color shifts. Subtle.
    private var blob1Color: Color {
        switch hour {
        case 5..<10:  return Tokens.Tangerine.amber400.opacity(0.30) // dawn pink
        case 10..<17: return Tokens.Brand.violet400.opacity(0.32)    // bright day
        case 17..<20: return Tokens.Tangerine.amber600.opacity(0.32) // sunset orange
        default:      return Tokens.Brand.violet600.opacity(0.30)    // night violet
        }
    }
    private var blob2Color: Color {
        switch hour {
        case 5..<10:  return Color(red: 0.95, green: 0.65, blue: 0.85).opacity(0.26)
        case 10..<17: return Tokens.Tangerine.amber400.opacity(0.28)
        case 17..<20: return Color(red: 0.95, green: 0.40, blue: 0.55).opacity(0.30)
        default:      return Color(red: 0.32, green: 0.18, blue: 0.55).opacity(0.30)
        }
    }
    private var blob3Color: Color {
        switch hour {
        case 5..<10:  return Color(red: 0.70, green: 0.85, blue: 1.00).opacity(0.20)
        case 10..<17: return Color.pink.opacity(0.18)
        case 17..<20: return Color.purple.opacity(0.22)
        default:      return Color(red: 0.20, green: 0.15, blue: 0.50).opacity(0.30)
        }
    }

    @ViewBuilder
    private func blob(color: Color, size: CGFloat,
                      x: CGFloat, y: CGFloat, period: Double) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 100)
            .offset(x: x + (phase ? 30 : -30),
                    y: y + (phase ? -20 : 20))
    }
}

// MARK: - Glass Card

/// The canonical content surface. Wraps content with the `.glass()` modifier
/// from the design system. `selected` raises elevation + adds a subtle accent
/// outline (used in the species picker, shop grid, etc).
struct GlassCard: View {
    var selected: Bool = false
    var body: some View {
        RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                // top-edge gloss
                RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(selected ? 0.6 : 0.35),
                                     .white.opacity(0.0)],
                            startPoint: .top, endPoint: .center
                        ),
                        lineWidth: Tokens.Stroke.thin
                    )
            )
            .overlay(
                // outer hairline
                RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
                    .strokeBorder(
                        selected ? Theme.accent.opacity(0.55)
                                 : Theme.stroke.glass,
                        lineWidth: selected ? Tokens.Stroke.med : Tokens.Stroke.hair
                    )
            )
            .elevated(selected ? .floating : .raised)
    }
}

extension View {
    /// Sugar: `.glassCard(padding:)` wraps content in padded glass.
    func glassCard(padding: CGFloat = Tokens.Space.m) -> some View {
        self.padding(padding)
            .background(GlassCard())
    }
}

// MARK: - Buttons

/// The primary commit action. ONE per screen at most. Aurora gradient fill,
/// crisp inner highlight, generous tap target, scale-down on press.
///
/// Why this matters:
/// users learn the visual language of "this is the thing to tap" within
/// the first 30 seconds. Make it unmistakable.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var enabled: Bool = true
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            HapticsService.shared.bump()
            action()
        }) {
            HStack(spacing: Tokens.Space.s + 2) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title).font(Theme.title(18))
            }
            .frame(maxWidth: .infinity, minHeight: 28)
            .padding(.vertical, Tokens.Space.m)
            .foregroundStyle(Theme.text.onAccent)
            .background(
                RoundedRectangle(cornerRadius: Tokens.Radius.l, style: .continuous)
                    .fill(Theme.auroraGradient)
            )
            .innerHighlight(radius: Tokens.Radius.l)
            .shadow(color: Theme.accent.opacity(enabled ? 0.40 : 0.0),
                    radius: 18, y: 10)
            .opacity(enabled ? 1 : 0.4)
            .scaleEffect(pressed ? 0.97 : 1)
            .animation(.iSnap, value: pressed)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .pressEvents(onPress: { pressed = true }, onRelease: { pressed = false })
    }
}

/// The alt action — visually quieter, glass-on-glass.
struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            HapticsService.shared.tap()
            action()
        }) {
            HStack(spacing: Tokens.Space.s) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title).font(Theme.title(16))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Tokens.Space.m - 2)
            .foregroundStyle(Theme.accent)
            .background(GlassCard())
            .scaleEffect(pressed ? 0.98 : 1)
            .animation(.iSnap, value: pressed)
        }
        .buttonStyle(.plain)
        .pressEvents(onPress: { pressed = true }, onRelease: { pressed = false })
    }
}

// MARK: - Press tracking

struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded   { _ in onRelease() }
        )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void,
                     onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let icon: String
    let title: String
    let value: Double          // 0…1
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            HStack(spacing: Tokens.Space.xs + 2) {
                Image(systemName: icon).foregroundStyle(tint)
                Text(title).font(Theme.caption()).foregroundStyle(Theme.text.secondary)
            }
            ProgressView(value: value)
                .progressViewStyle(StatBarStyle(tint: tint))
                .frame(height: 8)
        }
        .padding(.horizontal, Tokens.Space.s + 4)
        .padding(.vertical, Tokens.Space.s + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GlassCard())
    }
}

struct StatBarStyle: ProgressViewStyle {
    let tint: Color
    func makeBody(configuration: Configuration) -> some View {
        let p = configuration.fractionCompleted ?? 0
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.gray.opacity(0.15))
                Capsule()
                    .fill(LinearGradient(colors: [tint, tint.opacity(0.7)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(8, geo.size.width * p))
                    .animation(.iSmooth, value: p)
            }
        }
    }
}

// MARK: - Toast

struct ToastView: View {
    let icon: String
    let title: String
    let subtitle: String
    var body: some View {
        HStack(spacing: Tokens.Space.s + 4) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.title(16))
                Text(subtitle).font(Theme.caption()).foregroundStyle(Theme.text.secondary)
            }
            Spacer()
        }
        .padding(Tokens.Space.s + 6)
        .background(GlassCard())
        .padding(.horizontal, Tokens.Space.m)
    }
}

// MARK: - XP Gain Badge (the micro-interaction)

/// Floating "+24 XP" that drifts up and fades, used wherever XP is awarded.
/// This is the kind of detail users notice subliminally and call "polished."
///
/// Usage:
///     .overlay(alignment: .top) {
///         XPGainBadge(amount: lastXPGain, trigger: $xpGainID)
///     }
struct XPGainBadge: View {
    let amount: Int
    @Binding var trigger: UUID?

    @State private var visibleID: UUID?
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.7

    var body: some View {
        Group {
            if visibleID != nil {
                HStack(spacing: 6) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 14, weight: .bold))
                    Text("+\(amount) XP")
                        .font(Theme.title(16))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, Tokens.Space.m)
                .padding(.vertical, Tokens.Space.s)
                .background(
                    Capsule().fill(Theme.auroraGradient)
                )
                .innerHighlight(radius: 999)
                .elevated(.floating)
                .offset(y: offset)
                .opacity(opacity)
                .scaleEffect(scale)
            }
        }
        .onChange(of: trigger) { _, new in
            guard let new else { return }
            visibleID = new
            offset = 0
            opacity = 0
            scale = 0.7
            withAnimation(.iPop) {
                opacity = 1
                scale = 1.0
            }
            withAnimation(.easeOut(duration: 1.2).delay(0.05)) {
                offset = -120
            }
            withAnimation(.easeIn(duration: 0.35).delay(0.85)) {
                opacity = 0
            }
            // clean up
            Task {
                try? await Task.sleep(nanoseconds: 1_300_000_000)
                await MainActor.run {
                    if visibleID == new { visibleID = nil }
                }
            }
        }
    }
}
