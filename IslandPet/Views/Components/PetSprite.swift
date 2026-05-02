//
//  PetSprite.swift
//  IslandPet
//
//  PUBLIC API: PetSprite(species:, stage:, mood:, size:)
//
//  Strategy:
//   • If RiveRuntime is linked AND a matching .riv asset is in the bundle,
//     show the Rive animation. Mood maps to a State Machine input.
//   • Otherwise, fall back to a procedurally drawn SwiftUI sprite that ships
//     with zero asset dependencies. Identical public API in either case.
//
//  Rive asset conventions (drop-in by you when ready):
//     Resources/Animations/<Species>_<Stage>.riv
//     e.g. FlameSprite_baby.riv, OceanDrifter_adult.riv
//  State Machine: "PetMachine"
//  Inputs:
//     - "mood" (Number)  0=idle 1=focusing 2=happy 3=sleepy 4=sad 5=celebrating
//     - "trigger_evolve" (Trigger)
//

import SwiftUI

#if canImport(RiveRuntime)
import RiveRuntime
#endif

struct PetSprite: View {
    let species: PetSpecies
    let stage: EvolutionStage
    let mood: PetActivityAttributes.PetState.Mood
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            // soft ambient glow regardless of renderer
            Circle()
                .fill((Color(hex: species.primaryHex) ?? Theme.accent).opacity(0.30))
                .blur(radius: 28)
                .frame(width: size * 1.3, height: size * 1.3)

            #if canImport(RiveRuntime)
            if let resource = RivePetResource.find(species: species, stage: stage) {
                RivePetView(resource: resource, mood: mood)
                    .frame(width: size, height: size)
            } else if let assetName = PNGPetAsset.find(species: species, stage: stage, mood: mood) {
                PNGPetView(assetName: assetName, size: size, mood: mood)
            } else {
                ProceduralPetSprite(species: species, stage: stage, mood: mood, size: size)
            }
            #else
            if let assetName = PNGPetAsset.find(species: species, stage: stage, mood: mood) {
                PNGPetView(assetName: assetName, size: size, mood: mood)
            } else {
                ProceduralPetSprite(species: species, stage: stage, mood: mood, size: size)
            }
            #endif
        }
    }
}

// MARK: - PNG asset path
//
// When real illustrations arrive from the illustrator, drop them into
// Assets.xcassets with naming pattern:
//
//     pet_<Species>_<stage>_<mood>     e.g. pet_FlameSprite_baby_happy
//     pet_<Species>_<stage>            e.g. pet_FlameSprite_baby   (mood-fallback)
//
// The renderer prefers the per-mood asset; if missing, falls back to the
// stage-level asset; if that's also missing, falls back to procedural.
//
// This means you can ship with one PNG per stage (4 images) and add the
// 6 expressions later without a code change.

enum PNGPetAsset {
    /// Returns the asset name to render, or nil if none exists in the bundle.
    static func find(species: PetSpecies,
                     stage: EvolutionStage,
                     mood: PetActivityAttributes.PetState.Mood) -> String? {
        let perMood = "pet_\(species.rawValue)_\(stage.rawValue)_\(mood.rawValue)"
        if UIImage(named: perMood) != nil { return perMood }
        let stageOnly = "pet_\(species.rawValue)_\(stage.rawValue)"
        if UIImage(named: stageOnly) != nil { return stageOnly }
        return nil
    }
}

private struct PNGPetView: View {
    let assetName: String
    let size: CGFloat
    let mood: PetActivityAttributes.PetState.Mood

    @State private var bob = false

    var body: some View {
        Image(assetName)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            // Subtle motion so static art still feels alive. The illustrator
            // delivers stills; we add the breathing in code.
            .offset(y: bob ? -3 : 3)
            .rotationEffect(.degrees(mood == .focusing ? -2 : 0))
            .animation(.easeInOut(duration: bobDuration).repeatForever(autoreverses: true),
                       value: bob)
            .onAppear { bob = true }
    }

    private var bobDuration: Double {
        switch mood {
        case .focusing:    return 1.0
        case .happy:       return 0.6
        case .sleepy:      return 3.5
        case .sad:         return 2.8
        case .celebrating: return 0.4
        case .idle:        return 1.8
        }
    }
}

// MARK: - Rive integration

#if canImport(RiveRuntime)

struct RivePetResource {
    let resourceName: String        // e.g. "FlameSprite_baby"
    let stateMachine: String

    static func find(species: PetSpecies, stage: EvolutionStage) -> RivePetResource? {
        let name = "\(species.rawValue)_\(stage.rawValue)"
        guard Bundle.main.url(forResource: name, withExtension: "riv") != nil else {
            return nil
        }
        return RivePetResource(resourceName: name, stateMachine: "PetMachine")
    }
}

/// Bridges Rive's UIView into SwiftUI and updates the state-machine input
/// whenever the mood changes.
struct RivePetView: UIViewRepresentable {
    let resource: RivePetResource
    let mood: PetActivityAttributes.PetState.Mood

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> RiveRendererView {
        let vm = RiveViewModel(
            fileName: resource.resourceName,
            stateMachineName: resource.stateMachine
        )
        context.coordinator.viewModel = vm
        let view = vm.createRiveView()
        view.backgroundColor = .clear
        view.contentMode = .scaleAspectFit
        applyMood(mood, to: vm)
        return view
    }

    func updateUIView(_ uiView: RiveRendererView, context: Context) {
        guard let vm = context.coordinator.viewModel else { return }
        applyMood(mood, to: vm)
    }

    private func applyMood(_ mood: PetActivityAttributes.PetState.Mood,
                           to vm: RiveViewModel) {
        let value: Double
        switch mood {
        case .idle:        value = 0
        case .focusing:    value = 1
        case .happy:       value = 2
        case .sleepy:      value = 3
        case .sad:         value = 4
        case .celebrating: value = 5
        }
        vm.setInput("mood", value: value)
    }

    @MainActor final class Coordinator {
        var viewModel: RiveViewModel?
    }
}

#endif

// MARK: - Procedural fallback

struct ProceduralPetSprite: View {
    let species: PetSpecies
    let stage: EvolutionStage
    let mood: PetActivityAttributes.PetState.Mood
    var size: CGFloat = 120

    @State private var bob = false
    @State private var blink = false
    @State private var blinkTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            switch stage {
            case .egg:
                EggBody(color: speciesColor, size: size)
            case .baby:
                CreatureBody(color: speciesColor, size: size,
                             cuteness: 1.0, mood: mood, blink: blink)
            case .teen:
                CreatureBody(color: speciesColor, size: size,
                             cuteness: 0.7, mood: mood, blink: blink)
            case .adult:
                CreatureBody(color: speciesColor, size: size,
                             cuteness: 0.5, mood: mood, blink: blink, hasCrown: true)
            }
        }
        .offset(y: bob ? -4 : 4)
        .rotationEffect(.degrees(mood == .focusing ? -3 : 0))
        .animation(.easeInOut(duration: bobDuration).repeatForever(autoreverses: true),
                   value: bob)
        .onAppear {
            bob = true
            startBlinking()
        }
        .onDisappear {
            blinkTask?.cancel()
            blinkTask = nil
        }
    }

    private var speciesColor: Color {
        Color(hex: species.primaryHex) ?? Theme.accent
    }

    private var bobDuration: Double {
        switch mood {
        case .focusing:    return 1.0
        case .happy:       return 0.6
        case .sleepy:      return 3.5
        case .sad:         return 2.8
        case .celebrating: return 0.4
        case .idle:        return 1.8
        }
    }

    private func startBlinking() {
        blinkTask?.cancel()
        blinkTask = Task { @MainActor in
            while !Task.isCancelled {
                let pause = UInt64.random(in: 2_500_000_000...4_500_000_000)
                try? await Task.sleep(nanoseconds: pause)
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.12)) { blink = true }
                try? await Task.sleep(nanoseconds: 130_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.12)) { blink = false }
            }
        }
    }
}

// MARK: - Egg

private struct EggBody: View {
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            Ellipse()
                .fill(LinearGradient(colors: [color.opacity(0.9), color.opacity(0.5)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size * 0.75, height: size)
                .overlay(
                    Ellipse()
                        .stroke(.white.opacity(0.6), lineWidth: 2)
                        .frame(width: size * 0.75, height: size)
                )
                .shadow(color: color.opacity(0.5), radius: 12, y: 6)

            Circle()
                .fill(.white.opacity(0.7))
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(x: -size * 0.15, y: -size * 0.25)
        }
    }
}

// MARK: - Creature

private struct CreatureBody: View {
    let color: Color
    let size: CGFloat
    let cuteness: Double
    let mood: PetActivityAttributes.PetState.Mood
    let blink: Bool
    var hasCrown: Bool = false

    var body: some View {
        ZStack {
            Ellipse()
                .fill(LinearGradient(colors: [color, color.opacity(0.7)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * (0.95 - cuteness * 0.1),
                       height: size * (0.85 + cuteness * 0.05))
                .shadow(color: color.opacity(0.4), radius: 14, y: 8)

            Ellipse()
                .fill(.white.opacity(0.45))
                .frame(width: size * 0.55, height: size * 0.45)
                .offset(y: size * 0.12)

            HStack(spacing: size * 0.4) {
                Triangle().fill(color)
                    .frame(width: size * 0.18, height: size * 0.22)
                    .rotationEffect(.degrees(-15))
                Triangle().fill(color)
                    .frame(width: size * 0.18, height: size * 0.22)
                    .rotationEffect(.degrees(15))
            }
            .offset(y: -size * 0.4)

            HStack(spacing: size * 0.18) {
                Eye(blink: blink, mood: mood, size: size * 0.11)
                Eye(blink: blink, mood: mood, size: size * 0.11)
            }
            .offset(y: -size * 0.05)

            Mouth(mood: mood, size: size * 0.18)
                .offset(y: size * 0.12)

            HStack(spacing: size * 0.42) {
                Circle().fill(.pink.opacity(0.45))
                    .frame(width: size * 0.08, height: size * 0.08)
                Circle().fill(.pink.opacity(0.45))
                    .frame(width: size * 0.08, height: size * 0.08)
            }
            .offset(y: size * 0.08)

            if hasCrown {
                Image(systemName: "crown.fill")
                    .font(.system(size: size * 0.22))
                    .foregroundStyle(.yellow)
                    .offset(y: -size * 0.55)
                    .shadow(color: .orange.opacity(0.5), radius: 4)
            }

            if mood == .celebrating {
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .foregroundStyle(.yellow)
                        .font(.system(size: size * 0.12))
                        .offset(x: cos(Double(i) * .pi * 0.4) * size * 0.6,
                                y: sin(Double(i) * .pi * 0.4) * size * 0.6)
                }
            }
            if mood == .sleepy {
                Text("z")
                    .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                    .foregroundStyle(.purple.opacity(0.7))
                    .offset(x: size * 0.45, y: -size * 0.4)
            }
        }
    }
}

private struct Eye: View {
    let blink: Bool
    let mood: PetActivityAttributes.PetState.Mood
    let size: CGFloat

    var body: some View {
        ZStack {
            if blink || mood == .sleepy {
                Capsule().fill(.black.opacity(0.85))
                    .frame(width: size * 1.1, height: 2)
            } else if mood == .happy || mood == .celebrating {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: size * 0.6))
                    p.addQuadCurve(to: CGPoint(x: size, y: size * 0.6),
                                   control: CGPoint(x: size * 0.5, y: -size * 0.2))
                }
                .stroke(.black, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .frame(width: size, height: size)
            } else {
                Circle().fill(.black.opacity(0.88))
                    .frame(width: size, height: size)
                Circle().fill(.white)
                    .frame(width: size * 0.35, height: size * 0.35)
                    .offset(x: -size * 0.18, y: -size * 0.2)
            }
            if mood == .sad {
                Capsule().fill(.cyan)
                    .frame(width: size * 0.25, height: size * 0.5)
                    .offset(x: -size * 0.05, y: size * 0.7)
            }
        }
        .frame(width: size, height: size)
    }
}

private struct Mouth: View {
    let mood: PetActivityAttributes.PetState.Mood
    let size: CGFloat
    var body: some View {
        Path { p in
            switch mood {
            case .happy, .celebrating:
                p.move(to: CGPoint(x: 0, y: 0))
                p.addQuadCurve(to: CGPoint(x: size, y: 0),
                               control: CGPoint(x: size * 0.5, y: size * 0.6))
            case .sad:
                p.move(to: CGPoint(x: 0, y: size * 0.4))
                p.addQuadCurve(to: CGPoint(x: size, y: size * 0.4),
                               control: CGPoint(x: size * 0.5, y: -size * 0.2))
            case .sleepy:
                p.addEllipse(in: CGRect(x: size * 0.3, y: 0, width: size * 0.4, height: size * 0.25))
            default:
                p.move(to: CGPoint(x: size * 0.2, y: size * 0.3))
                p.addQuadCurve(to: CGPoint(x: size * 0.8, y: size * 0.3),
                               control: CGPoint(x: size * 0.5, y: size * 0.55))
            }
        }
        .stroke(.black.opacity(0.85),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        .frame(width: size, height: size)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Color hex helper

extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8) & 0xFF) / 255
        let b = Double(v & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
