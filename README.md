<div align="center">

<br/>

```
██╗███████╗██╗      █████╗ ███╗   ██╗██████╗ ██████╗ ███████╗████████╗
██║██╔════╝██║     ██╔══██╗████╗  ██║██╔══██╗██╔══██╗██╔════╝╚══██╔══╝
██║███████╗██║     ███████║██╔██╗ ██║██║  ██║██████╔╝█████╗     ██║   
██║╚════██║██║     ██╔══██║██║╚██╗██║██║  ██║██╔═══╝ ██╔══╝     ██║   
██║███████║███████╗██║  ██║██║ ╚████║██████╔╝██║     ███████╗   ██║   
╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝     ╚══════╝   ╚═╝   
```

<br/>

### 🐾 *Your productivity shouldn't feel like a task — it should feel like caring for something.*

<br/>

[![iOS](https://img.shields.io/badge/iOS-17%2B-black?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com)
[![Swift](https://img.shields.io/badge/Swift-5.9-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-blue?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/swiftui/)
[![Xcode](https://img.shields.io/badge/Xcode-15%2B-1575F9?style=for-the-badge&logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

<br/>

> **IslandPet** is a focus-driven virtual companion that lives inside your Dynamic Island.  
> It grows. It reacts. It remembers. And it makes you actually want to show up every day.

<br/>

---

</div>

<br/>

## ✦ What is IslandPet?

Most productivity apps treat you like a machine — track hours, hit targets, move on. **IslandPet flips that entirely.**

At its core, IslandPet is a **virtual companion system** woven into your iPhone's Dynamic Island. Every Pomodoro session you complete feeds your pet — giving it XP, unlocking new traits, triggering evolutions. Skip sessions and your companion gets sleepy. Stay consistent and it thrives.

It's not gamification for the sake of it. It's **emotional design as productivity infrastructure.**

```
Focus Session → XP Earned → Pet Reacts → Streak Grows → Evolution Unlocked
     ↑                                                           ↓
     └─────────────────── You come back again ──────────────────┘
```

<br/>

---

## ✦ Core Features

<br/>

### 🧠 Focus Engine

| Feature | Details |
|--------|---------|
| **Session Style** | Pomodoro-based (customizable durations) |
| **XP System** | Every minute of focus = earned growth |
| **Progression** | Long-arc evolution mechanics, not just daily resets |
| **Streak Logic** | Freeze protection, daily continuity tracking |

<br/>

### 🐾 The Pet System

Your companion isn't static — it's a **living state machine** with memory.

```
States:         😄 Happy  →  😴 Sleepy  →  💤 Idle  →  ✨ Evolving
Triggers:       Focus     →  Rest       →  Neglect  →  Milestone
Personality:    Trait-based, deterministic, consistent across sessions
Memory:         Responds differently based on your history with it
```

No AI black boxes. No randomness. Just a **well-designed personality engine** that feels alive because it was *designed* to feel alive.

<br/>

### Architecture

```
IslandPet/
├── App/
│   ├── IslandPetApp.swift          # ModelContainer with App Group, graceful DB fallback
│   ├── RootView.swift              # Onboarding gate, environment injection
│   └── AppShell.swift             # VM ownership via VMLoader, EnvironmentObject injection
│
├── Models/                         # SwiftData @Model types
│   ├── Pet.swift                   # Core entity: stage, XP, mood, traits, memories
│   ├── FocusSession.swift          # Session records with duration, completion, XP delta
│   ├── Achievement.swift           # Unlock conditions + progress tracking
│   ├── ShopItem.swift              # Soft-currency cosmetic items
│   ├── ChatMessage.swift           # Local chat history
│   └── AppSettings.swift          # Singleton: streak, freezes, onboarding state
│
├── ViewModels/
│   ├── PetViewModel.swift          # XP system, mood decay loop, evolution triggers
│   └── TimerViewModel.swift        # Pomodoro engine + Live Activity lifecycle
│
├── Services/
│   ├── LiveActivityService.swift   # ActivityKit: start/update/end Dynamic Island
│   ├── WidgetSnapshotService.swift # App Group bridge — syncs state to widgets
│   ├── AchievementService.swift    # Tracks unlock conditions across all event types
│   ├── HapticsService.swift        # 10-beat CoreHaptics score (named CHHapticPatterns)
│   ├── PetPersonality.swift        # Traits + memory + voice — offline, deterministic
│   ├── NotificationService.swift   # 3 retention loops: streak-saver, sad-pet, completion
│   └── TodayStatsService.swift     # Real @Query-driven daily metrics
│
├── Views/
│   ├── Onboarding/                 # 5-page flow with notification ask, species picker
│   ├── Home/                       # Redesigned: pet hero, stats bar, personality greeting
│   ├── Timer/                      # Redesigned: dual-ring, floating pet, digit transitions
│   ├── Profile/                    # Redesigned: traits, heatmap, shareable personality card
│   ├── Shop/                       # Soft currency cosmetics store
│   ├── Chat/                       # Local rule-driven pet dialogue
│   └── Components/                 # Glass cards, stat pills, aurora background, animations
│
├── Motion/
│   ├── Motion.swift                # Named curves, cascade modifier, breathe, shimmer
│   └── Theme.swift                 # Design tokens: Tokens.Space, colors, gradients
│
├── Intents/
│   └── StopFocusIntent.swift       # LiveActivityIntent: stop session from Dynamic Island
│
└── EvolutionCinematicView.swift    # Full-screen moment: particles, haptics, share card

IslandPetWidget/
├── IslandPetWidgetBundle.swift
├── IslandPetLockWidget.swift       # 5 lock screen families
└── IslandPetLiveActivity.swift     # Dynamic Island: compact / minimal / expanded

Shared/
└── PetActivityAttributes.swift     # In both targets — the bridge between app and island
```

<br/>

### 📍 Dynamic Island Integration

This is where IslandPet gets wild.

> **Your pet doesn't just live in the app — it lives in your phone.**

During focus sessions, your companion takes up residence in the Dynamic Island:

- 🟢 **Compact view** — pet animation + session timer
- 🔔 **Notification view** — pet reaction to your action
- 📲 **Expanded view** — full session controls + pet mood
- ⏹️ **Quick stop** — tap to end session right from the island

Built with **ActivityKit** + **WidgetKit**. Real system-level integration, not a workaround.

<br/>

### 🎬 Evolution Cinematic

When your pet evolves, it doesn't just level up silently.

It gets a **full-screen cinematic moment:**

- Particle burst effects
- Layered motion animations
- Haptic feedback choreography
- **Shareable 1080×1920 story-ready export**

Because milestones should *feel* like milestones.

<br/>

### 📊 Streak & Retention Intelligence

```
Daily Heatmap      →  See your consistency at a glance
Smart Notifications →  Pet-driven reminders ("I miss you...")  
Freeze Logic       →  Life happens — your streak is protected
Reaction System    →  Pet responds to patterns, not just sessions
```

<br/>

---

## ✦ Tech Stack

```
┌─────────────────────────────────────────────┐
│                  IslandPet                  │
├──────────────┬──────────────────────────────┤
│  UI Layer    │  SwiftUI (declarative, fluid) │
│  Data Layer  │  SwiftData (local-first)      │
│  Live Layer  │  ActivityKit + WidgetKit      │
│  Feel Layer  │  Core Haptics                 │
│  Arch        │  MVVM (clean separation)      │
└──────────────┴──────────────────────────────┘
```

| Layer | Technology | Why |
|-------|-----------|-----|
| **UI** | SwiftUI | Declarative, animation-native, Apple-first |
| **Persistence** | SwiftData | Lightweight, reactive, no boilerplate |
| **Live Activities** | ActivityKit | Real Dynamic Island integration |
| **Widgets** | WidgetKit | Lock screen + home screen presence |
| **Haptics** | Core Haptics | Cinematic tactile moments |
| **Architecture** | MVVM | Scalable, testable, maintainable |

<br/>

---

## ✦ Design Philosophy

IslandPet is built on three principles — and they aren't negotiable:

<br/>

```
1. Emotional Attachment  >  Feature Count
   ─────────────────────────────────────
   One thing that makes you feel something beats ten things
   that do nothing. Every feature earns its place.

2. Polish  >  Complexity
   ─────────────────────────────────────
   The animation that runs at 120fps matters.
   The haptic that fires at exactly the right moment matters.
   Details are the product.

3. Experience  >  Utility
   ─────────────────────────────────────
   IslandPet doesn't just help you focus.
   It makes you want to.
```

<br/>

The design language — **glassmorphism + gradient-based surfaces + custom motion system** — is built to feel like it belongs on an Apple product page. Because if it doesn't look like it belongs there, it's not done yet.

<br/>

---

## ✦ Screenshots

<br/>

> *Screenshots / demo GIFs coming soon*

| Home Screen | Focus Session | Dynamic Island | Evolution |
|:-----------:|:-------------:|:--------------:|:---------:|
| 📸 | 📸 | 📸 | 📸 |
| Pet idle state | Live timer + mood | Island companion | Cinematic moment |

<br/>

---

## ✦ Getting Started

### Prerequisites

```bash
# You'll need:
Xcode 15+
iOS 17+ device or simulator
Apple Developer Account (required for Live Activities)
```

### Installation

```bash
git clone https://github.com/yourusername/IslandPet.git
cd IslandPet
open IslandPet.xcodeproj
```

### Run

```
1. Select a target device (iPhone 14 Pro or newer for Dynamic Island)
2. Sign with your Apple Developer team
3. Build & Run (⌘R)
```

> ⚠️ **Live Activities and Dynamic Island require a physical device.** The simulator won't cut it for the full experience.

<br/>

---

## ✦ Roadmap

<br/>

```
v1.0 — MVP (Current)
├── ✅ Core focus & Pomodoro engine
├── ✅ Pet state + personality system  
├── ✅ Dynamic Island live integration
├── ✅ XP & streak tracking
└── ✅ Evolution cinematic

v1.1 — Polish Arc
├── 🎨 Custom pet illustrations (replacing procedural sprites)
├── 💳 StoreKit 2 (cosmetics + premium features)
└── ☁️  iCloud sync across devices

v1.2 — Social Arc
├── 👥 Co-focus sessions (focus with friends)
├── 🎭 Advanced pet personalization
└── 🎞️  Rive animation integration (fluid, interactive sprites)
```

<br/>

---

## ✦ Inspiration

IslandPet stands on the shoulders of apps that proved emotional design works:

| App | What It Proved |
|-----|---------------|
| **Duolingo** | Streak psychology is incredibly powerful |
| **Finch** | Users form real emotional bonds with digital companions |
| **Forest** | Productivity + a reason to care = habit formation |

But none of them combined **habit formation + emotional design + system-level iOS integration.**

That's the gap IslandPet fills.

<br/>

---

## ✦ Author

<div align="center">

<br/>

**Yash Raj**  
B.Tech CSE (AI/ML) — SRM Institute of Science and Technology  

*Aspiring software engineer obsessed with building products that feel as good as they work.*

<br/>

[![GitHub](https://img.shields.io/badge/GitHub-@yourusername-181717?style=for-the-badge&logo=github)](https://github.com/yourusername)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?style=for-the-badge&logo=linkedin)](https://linkedin.com)
[![Twitter](https://img.shields.io/badge/Twitter-@yourhandle-1DA1F2?style=for-the-badge&logo=twitter)](https://twitter.com)

</div>

<br/>

---

## ✦ Vision

<div align="center">

<br/>

*IslandPet is not just an app.*  
*It's an attempt to redefine what productivity feels like.*

<br/>

```
From  discipline  →  to  attachment
From  tracking    →  to  caring
From  streaks     →  to  stories
```

<br/>

**The goal isn't to make you more productive.**  
**It's to make you someone who shows up — because something is waiting for you.**

<br/>

---

*Built with obsession by Yash Raj · MIT License · Open Source*

<br/>

**⭐ Star this repo if IslandPet resonates with you.**  
*Every star tells me someone gets it.*

</div>
