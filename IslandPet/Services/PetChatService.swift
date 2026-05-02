//
//  PetChatService.swift
//  IslandPet
//
//  MVP uses an on-device rule-based reply generator that draws from pet state.
//  The protocol is designed so you can drop in an LLM provider (Claude, OpenAI, on-device Foundation Models)
//  by implementing `PetChatProvider` without touching the UI.
//

import Foundation

protocol PetChatProvider {
    func reply(to userMessage: String, context: PetChatContext) async -> String
}

struct PetChatContext {
    let petName: String
    let species: PetSpecies
    let stage: EvolutionStage
    let level: Int
    let xp: Int
    let mood: PetActivityAttributes.PetState.Mood
    let streak: Int
    let lastSessionMinutes: Int?
}

/// Lightweight, charming, deterministic-feeling responses.
/// Replace with LLM-backed provider for paid tier.
struct LocalPetChatProvider: PetChatProvider {

    func reply(to userMessage: String, context ctx: PetChatContext) async -> String {
        let msg = userMessage.lowercased()

        // small artificial latency for naturalness
        try? await Task.sleep(nanoseconds: UInt64.random(in: 350_000_000...900_000_000))

        if msg.contains("hi") || msg.contains("hello") || msg.contains("hey") {
            return "Hi! I'm \(ctx.petName) — and I just remembered I'm a \(ctx.species.displayName.lowercased()). 🐾"
        }
        if msg.contains("how are you") {
            return moodLine(ctx)
        }
        if msg.contains("study") || msg.contains("focus") || msg.contains("work") {
            return "Let's lock in. Start a focus session and I'll cheer you on from the Dynamic Island. ✨"
        }
        if msg.contains("tired") || msg.contains("sleep") {
            return "Same. Try a 5-minute break and a glass of water — I'll wait here, promise."
        }
        if msg.contains("level") || msg.contains("xp") {
            return "We're level \(ctx.level) with \(ctx.xp) XP. \(nextStageHint(ctx))"
        }
        if msg.contains("food") || msg.contains("hungry") || msg.contains("eat") {
            return "If you tap the bowl on Home, I get a snack. Berries are my favorite."
        }
        if msg.contains("streak") {
            return ctx.streak > 0
                ? "We're on a \(ctx.streak)-day streak. Don't you dare break it 😤"
                : "We don't have a streak yet — let's start today."
        }
        if msg.contains("?") {
            return "Hmm… I'm a small creature with big opinions. Could you ask that another way?"
        }
        // Default reflection
        return reflect(msg, ctx: ctx)
    }

    private func moodLine(_ ctx: PetChatContext) -> String {
        switch ctx.mood {
        case .happy:        return "Excellent! You showed up — that's the whole game."
        case .focusing:     return "Shh… I'm helping you concentrate."
        case .sleepy:       return "A bit drowsy. Maybe a quick walk?"
        case .sad:          return "Honestly? Lonely. Spend a little time with me?"
        case .celebrating:  return "AMAZING. Look at us go!"
        case .idle:         return "All good. Curious what we'll do next."
        }
    }

    private func nextStageHint(_ ctx: PetChatContext) -> String {
        switch ctx.stage {
        case .egg:   return "I'm still in my egg — keep studying and I'll hatch soon!"
        case .baby:  return "I'll evolve again at 250 XP. Almost there!"
        case .teen:  return "One more big push and I'll reach my final form."
        case .adult: return "I've reached my final form. Now we collect achievements."
        }
    }

    private func reflect(_ msg: String, ctx: PetChatContext) -> String {
        let openers = [
            "Tell me more.",
            "Mm. That's interesting.",
            "I'm listening — keep going.",
            "Got it. What do you want to do about it?",
        ]
        return openers.randomElement()!
    }
}
