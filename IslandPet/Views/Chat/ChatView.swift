//
//  ChatView.swift
//  IslandPet
//

import SwiftUI
import SwiftData

struct ChatView: View {
    @EnvironmentObject private var petVM: PetViewModel
    @Environment(\.modelContext) private var context
    @Query(sort: \ChatMessage.createdAt) private var messages: [ChatMessage]

    @State private var input: String = ""
    @State private var sending: Bool = false
    @FocusState private var inputFocused: Bool

    private let provider: PetChatProvider = LocalPetChatProvider()

    var body: some View {
        ZStack {
            BackgroundAurora()
            VStack(spacing: 0) {
                header
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if messages.isEmpty { greeting }
                            ForEach(messages) { m in
                                MessageBubble(message: m).id(m.id)
                            }
                            if sending { TypingBubble() }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                inputBar
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if let pet = petVM.pet {
                PetSprite(species: pet.species, stage: pet.stage,
                          mood: pet.mood, size: 44)
                    .frame(width: 50, height: 50)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(petVM.pet?.name ?? "Pet").font(Theme.title(18))
                Text("Online · here for you").font(Theme.body(12)).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Say hi to \(petVM.pet?.name ?? "your pet")")
                .font(Theme.title(20))
            Text("Ask how they're feeling, what to do next, or just vent.")
                .font(Theme.body())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 24)
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Message…", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .focused($inputFocused)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(GlassCard())
                .onSubmit(send)

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? Theme.accent : .gray.opacity(0.4))
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var canSend: Bool {
        !input.trimmingCharacters(in: .whitespaces).isEmpty && !sending
    }

    private func send() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let user = ChatMessage(role: "user", content: trimmed)
        context.insert(user)
        input = ""
        try? context.save()
        sending = true

        Task {
            guard let pet = petVM.pet else { sending = false; return }
            let ctx = PetChatContext(
                petName: pet.name,
                species: pet.species,
                stage: pet.stage,
                level: pet.level,
                xp: pet.xp,
                mood: pet.mood,
                streak: petVM.settings?.currentStreak ?? 0,
                lastSessionMinutes: nil
            )
            let reply = await provider.reply(to: trimmed, context: ctx)
            await MainActor.run {
                let petMsg = ChatMessage(role: "pet", content: reply)
                context.insert(petMsg)
                try? context.save()
                sending = false
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            Text(message.content)
                .font(Theme.body(15))
                .padding(.horizontal, 14).padding(.vertical, 10)
                .foregroundStyle(isUser ? .white : .primary)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isUser ? AnyShapeStyle(Theme.auroraGradient)
                                     : AnyShapeStyle(.ultraThinMaterial))
                )
            if !isUser { Spacer(minLength: 60) }
        }
    }
}

struct TypingBubble: View {
    @State private var phase: Int = 0
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(.gray)
                        .frame(width: 6, height: 6)
                        .opacity(phase == i ? 1 : 0.3)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial))
            Spacer()
        }
        .onAppear {
            Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    await MainActor.run { phase = (phase + 1) % 3 }
                }
            }
        }
    }
}
