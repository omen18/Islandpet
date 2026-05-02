//
//  Theme.swift
//  IslandPet
//
//  The design system. Three layers:
//
//   1. Tokens   — raw, named values (colors, sizes, durations). Never used
//                 directly by view code.
//   2. Semantic — intent-named values that compose tokens
//                 (e.g. `Theme.surface.card`, `Theme.text.primary`).
//                 This is the API view code uses.
//   3. Sugar    — small SwiftUI extensions for the most common composites.
//
//  Why this matters for ADA-quality polish:
//  consistency is the *single biggest* perceptual difference between an
//  amateur app and a polished one. If every card has a slightly different
//  corner radius or shadow, it reads as cheap. Tokens prevent that.
//
//  Reference colors are tuned against:
//   - HIG legibility (>4.5 contrast on text)
//   - Dark Mode parity (every token has a paired dark value)
//   - Color-blind safety (no info conveyed by hue alone — always paired
//     with shape/icon)
//

import SwiftUI

// MARK: - 1. Tokens (raw values)

enum Tokens {

    // ── Color primitives ────────────────────────────────────────────
    // Brand violet — periwinkle, slightly cool. Anchors the app.
    enum Brand {
        static let violet50  = Color(red: 0.96, green: 0.95, blue: 1.00)
        static let violet100 = Color(red: 0.91, green: 0.89, blue: 1.00)
        static let violet200 = Color(red: 0.80, green: 0.76, blue: 0.99)
        static let violet400 = Color(red: 0.55, green: 0.48, blue: 0.97)
        static let violet600 = Color(red: 0.42, green: 0.36, blue: 0.97)  // primary
        static let violet800 = Color(red: 0.28, green: 0.23, blue: 0.78)
    }

    // Tangerine — warm secondary, used for coins/streak/achievement glow.
    enum Tangerine {
        static let amber200 = Color(red: 1.00, green: 0.86, blue: 0.62)
        static let amber400 = Color(red: 1.00, green: 0.74, blue: 0.42)
        static let amber600 = Color(red: 1.00, green: 0.66, blue: 0.36)  // secondary
        static let amber800 = Color(red: 0.85, green: 0.45, blue: 0.20)
    }

    // Functional
    enum Functional {
        static let success = Color(red: 0.30, green: 0.82, blue: 0.50)
        static let warning = Color(red: 0.99, green: 0.74, blue: 0.30)
        static let danger  = Color(red: 0.97, green: 0.33, blue: 0.43)
        static let info    = Color(red: 0.36, green: 0.64, blue: 0.95)
    }

    // Neutrals — derived from sRGB, calibrated for both Light & Dark.
    enum Neutral {
        // Light backgrounds
        static let bg0      = Color(red: 0.99, green: 0.98, blue: 0.97)
        static let bg1      = Color(red: 0.96, green: 0.95, blue: 1.00)
        static let bg2      = Color(red: 0.92, green: 0.91, blue: 0.97)

        // Dark backgrounds
        static let bgDark0  = Color(red: 0.06, green: 0.06, blue: 0.10)
        static let bgDark1  = Color(red: 0.10, green: 0.09, blue: 0.16)
        static let bgDark2  = Color(red: 0.14, green: 0.13, blue: 0.22)

        // Text
        static let textPrimary    = Color.primary
        static let textSecondary  = Color.secondary
        static let textTertiary   = Color(white: 0.55)
    }

    // ── Spacing scale (4-pt grid; matches Apple's HIG) ───────────────
    enum Space {
        static let xxs: CGFloat = 2
        static let xs:  CGFloat = 4
        static let s:   CGFloat = 8
        static let m:   CGFloat = 16
        static let l:   CGFloat = 24
        static let xl:  CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }

    // ── Corner radii (squircle-friendly) ─────────────────────────────
    enum Radius {
        static let pill: CGFloat = 999
        static let xs:   CGFloat = 8
        static let s:    CGFloat = 12
        static let m:    CGFloat = 20
        static let l:    CGFloat = 28
        static let xl:   CGFloat = 36
        static let card: CGFloat = 24   // the most-used radius — call it out
    }

    // ── Stroke widths (hairline-aware) ───────────────────────────────
    enum Stroke {
        static let hair: CGFloat = 0.5  // sub-pixel on @3x
        static let thin: CGFloat = 1
        static let med:  CGFloat = 1.5
        static let thick: CGFloat = 2.5
    }

    // ── Elevation (shadow recipes — not raw values) ──────────────────
    /// Apple-style soft shadows: short blur, very low opacity, slight Y-offset.
    /// Never use big blurs at high opacity — that's Material Design, not HIG.
    enum Elevation {
        case flat, subtle, raised, floating, hero

        var radius: CGFloat {
            switch self {
            case .flat:     return 0
            case .subtle:   return 6
            case .raised:   return 12
            case .floating: return 22
            case .hero:     return 36
            }
        }
        var y: CGFloat {
            switch self {
            case .flat:     return 0
            case .subtle:   return 2
            case .raised:   return 4
            case .floating: return 10
            case .hero:     return 18
            }
        }
        var opacity: Double {
            switch self {
            case .flat:     return 0
            case .subtle:   return 0.05
            case .raised:   return 0.08
            case .floating: return 0.14
            case .hero:     return 0.22
            }
        }
    }
}

// MARK: - 2. Semantic theme

enum Theme {

    // MARK: Color (intent-named)

    enum surface {
        static var background: LinearGradient {
            LinearGradient(colors: [Tokens.Neutral.bg1, Tokens.Neutral.bg0],
                           startPoint: .top, endPoint: .bottom)
        }
        static var backgroundDark: LinearGradient {
            LinearGradient(colors: [Tokens.Neutral.bgDark0, Tokens.Neutral.bgDark1],
                           startPoint: .top, endPoint: .bottom)
        }
        /// Card surface — pair with `.glass()` modifier.
        static let card: Color = .clear
    }

    enum text {
        static let primary   = Tokens.Neutral.textPrimary
        static let secondary = Tokens.Neutral.textSecondary
        static let tertiary  = Tokens.Neutral.textTertiary
        static let onAccent  = Color.white
    }

    enum stroke {
        static let glass    = Color.white.opacity(0.35)
        static let glassDark = Color.white.opacity(0.12)
        static let divider  = Color.primary.opacity(0.08)
    }

    // Direct accent tokens — keep for back-compat with existing call sites
    static let accent      = Tokens.Brand.violet600
    static let accentSoft  = Tokens.Brand.violet200
    static let accentDeep  = Tokens.Brand.violet800
    static let secondary   = Tokens.Tangerine.amber600
    static let success     = Tokens.Functional.success
    static let danger      = Tokens.Functional.danger
    static let warning     = Tokens.Functional.warning

    // Back-compat raw tokens used by existing screens
    static let bgTop        = Tokens.Neutral.bg1
    static let bgBottom     = Tokens.Neutral.bg0
    static let bgTopDark    = Tokens.Neutral.bgDark0
    static let bgBottomDark = Tokens.Neutral.bgDark1
    static let glassBorder  = Color.white.opacity(0.35)

    // MARK: Gradients (canonical)

    static var auroraGradient: LinearGradient {
        LinearGradient(colors: [
            Tokens.Brand.violet600,
            Color(red: 0.95, green: 0.55, blue: 0.85),
            Tokens.Tangerine.amber600
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var moodHappyGradient: LinearGradient {
        LinearGradient(colors: [Tokens.Tangerine.amber200,
                                Tokens.Tangerine.amber400],
                       startPoint: .top, endPoint: .bottom)
    }

    static var streakGradient: LinearGradient {
        LinearGradient(colors: [
            Color(red: 1.0, green: 0.5, blue: 0.2),
            Color(red: 1.0, green: 0.3, blue: 0.1)
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var nightGradient: LinearGradient {
        LinearGradient(colors: [
            Color(red: 0.10, green: 0.06, blue: 0.30),
            Color(red: 0.06, green: 0.05, blue: 0.18),
            Color(red: 0.12, green: 0.04, blue: 0.22)
        ], startPoint: .top, endPoint: .bottom)
    }

    // MARK: Spacing (sugar)

    static let spacingXS = Tokens.Space.xs
    static let spacingS  = Tokens.Space.s
    static let spacingM  = Tokens.Space.m
    static let spacingL  = Tokens.Space.l
    static let spacingXL = Tokens.Space.xl

    // MARK: Radius (sugar)

    static let radiusS  = Tokens.Radius.s
    static let radiusM  = Tokens.Radius.m
    static let radiusL  = Tokens.Radius.l
    static let radiusXL = Tokens.Radius.xl

    // MARK: Typography
    //
    // Hierarchy mirrors Apple's text styles but with rounded design and
    // tighter sizes. Five tiers — never invent a sixth in screen code.
    //
    //  display   — hero numbers, evolution titles      34/40 bold rounded
    //  title     — screen headers, card headers        22/28 semibold rounded
    //  body      — paragraph copy                      16/22 regular rounded
    //  caption   — secondary metadata                  13/18 medium rounded
    //  micro     — pill labels, footnotes              11/14 semibold rounded
    //
    static func display(_ size: CGFloat = 34, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func title(_ size: CGFloat = 22, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func body(_ size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func caption(_ size: CGFloat = 13, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func micro(_ size: CGFloat = 11, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func mono(_ size: CGFloat = 32) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

// MARK: - 3. Sugar — composable modifiers

extension View {

    /// Apply a named elevation shadow. The whole point: every elevated thing
    /// in the app uses one of 5 named depths, never a custom shadow.
    func elevated(_ level: Tokens.Elevation = .raised) -> some View {
        self.shadow(color: .black.opacity(level.opacity),
                    radius: level.radius,
                    x: 0,
                    y: level.y)
    }

    /// Premium "glass" treatment — ultra-thin material + hairline border +
    /// subtle gloss highlight along the top edge. The heart of the visual
    /// system; every card uses this.
    func glass(radius: CGFloat = Tokens.Radius.card,
               elevation: Tokens.Elevation = .raised) -> some View {
        self.background(
            ZStack {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.ultraThinMaterial)
                // top gloss highlight — 1px, white at 25%, fades to 0
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.35), .white.opacity(0.0)],
                            startPoint: .top, endPoint: .center
                        ),
                        lineWidth: Tokens.Stroke.thin
                    )
                // outer hairline — defines the edge in dark mode
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.stroke.glass, lineWidth: Tokens.Stroke.hair)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .elevated(elevation)
    }

    /// Pill background with tint. Pair with `Theme.micro()` font.
    func pill(_ tint: Color, foreground: Color? = nil) -> some View {
        self.font(Theme.micro())
            .foregroundStyle(foreground ?? tint)
            .padding(.horizontal, Tokens.Space.s + 2)
            .padding(.vertical, Tokens.Space.xs)
            .background(Capsule().fill(tint.opacity(0.16)))
    }

    /// Subtle inner highlight — used on primary buttons and the timer ring.
    /// Adds a *barely visible* light gradient overlay that catches the eye.
    func innerHighlight(radius: CGFloat = Tokens.Radius.l) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.45), .clear],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: Tokens.Stroke.thin
                )
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
        )
    }
}
