<div align="center">

<br/>

<img width="120" src="https://raw.githubusercontent.com/yourusername/IslandPet/main/assets/icon.png" alt="IslandPet Icon"/>

<br/>

# IslandPet

**A focus companion that lives in your Dynamic Island.**

<br/>

[![Swift](https://img.shields.io/badge/Swift-5.9-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17%2B-000000?style=flat-square&logo=apple&logoColor=white)](https://developer.apple.com)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-1C6EF2?style=flat-square)](https://developer.apple.com/swiftui/)
[![ActivityKit](https://img.shields.io/badge/ActivityKit-Live_Island-5856D6?style=flat-square)](https://developer.apple.com/documentation/activitykit)
[![License](https://img.shields.io/badge/License-MIT-34C759?style=flat-square)](LICENSE)
[![Status](https://img.shields.io/badge/Status-MVP_Complete-FF9500?style=flat-square)]()

<br/>

> *Your productivity shouldn't feel like a task — it should feel like caring for something.*

<br/>

</div>

---

<br/>

## The Premise

Productivity apps fail because they treat you like a machine. Track hours, hit targets, close the app.

IslandPet treats productivity the way Duolingo treats language learning — as something you come back to because *something is waiting for you.*

Every focus session you complete feeds a virtual companion. It grows, reacts, remembers, and evolves. Miss days and it gets sleepy. Stay consistent and it thrives.

The pet doesn't live in the app. It lives in your **Dynamic Island** — visible during every session, reacting to your work in real time, impossible to ignore.

```
Start Focus  →  Pet appears in Island  →  Session ends  →  XP earned  →  Pet evolves  →  You share it
     ↑                                                                                          ↓
     └──────────────────────────── You come back tomorrow ──────────────────────────────────────┘
```

That loop, made perfect, is the entire product.

<br/>

---

## What's Built

This is a complete, production-structured Xcode project — not a tutorial clone, not a prototype. ~6,500 lines of Swift across 32 files, a real Widget Extension target, a working Live Activity, and a design system built from scratch.

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

### The Systems

**Motion Design System** (`Motion.swift`) — Not animation sprinkled on top. A curated curve library with named easing functions, a `.cascadeIn()` view modifier for staggered reveals, `.breathe()` for the idle pet animation loop, and `.shimmer()` for the evolution buildup. Every animation in the app pulls from this. That's what makes it feel cohesive instead of assembled.

**CoreHaptics Score** (`HapticsService.swift`) — Ten named beats matched to design intent: `petPoke`, `xpGain`, `evolutionChord`, `streakSave`, `heartbeat` (pulses during focus sessions — felt, not heard). Not `UIImpactFeedbackGenerator`. Actual `CHHapticPattern` compositions with millisecond timing control.

**Personality System** (`PetPersonality.swift`) — The pet has stable traits chosen at creation (curiosity, warmth, energy, formality) stored as JSON in SwiftData. A memory ring of recent events (focus completed, evolved, fed, played, streak broken, days away) drives a curated phrase bank with trait-weighted voice selection. The pet greets you differently at 7am vs. 11pm, reacts differently after a 5-day streak vs. returning after a gap. No LLM. Runs offline. Consistent. Deterministic. Charming because it *remembers you specifically.*

**Streak Freeze Logic** — Earns one freeze every 7 sessions, capped at 3. A missed day auto-consumes a freeze and fires a "close call" notification. Loss aversion preserved. Streak survives.

**Evolution Cinematic** (`EvolutionCinematicView.swift`) — Not a toast. A full-screen modal: anticipation shake → white flash → reveal → particle burst → haptic chord → `ImageRenderer`-generated 1080×1920 share card, aspect-ratio-correct for Instagram and TikTok stories.

**Presentation Order Fix** — When XP from session completion triggers an evolution, both the celebration sheet and the evolution cinematic previously fought for presentation. Fixed: `awaitingEvolutionDismiss` state defers the sheet 0.4s after the cinematic dismisses. The loop plays in the right emotional order.

**Art Swap-In Path** — `PetSprite.swift` routes through Rive → PNG → procedural, in priority order. Drop `pet_FlameSprite_baby_idle.png` into `Assets.xcassets` and the procedural sprite is replaced. Zero code changes required when illustrations arrive.

<br/>

---

## Tech Stack

| | Technology | Role |
|---|---|---|
| **UI** | SwiftUI | Declarative views, custom geometry, native animations |
| **Data** | SwiftData | Local persistence, reactive `@Query` |
| **Live Activities** | ActivityKit | Dynamic Island: compact, minimal, expanded |
| **Widgets** | WidgetKit | Lock screen (5 families) + home screen |
| **Haptics** | CoreHaptics | Named `CHHapticPattern` compositions |
| **Intents** | AppIntents | Interactive Stop button inside the Dynamic Island |
| **Architecture** | MVVM | `@StateObject` ownership in `AppShell`, `@EnvironmentObject` in views |
| **Sharing** | ImageRenderer | On-device 1080×1920 story-format share cards |

<br/>

---

## Dynamic Island Integration

During a focus session, your pet moves into the Dynamic Island and stays there.

**Compact leading** — mood-tinted disc behind the pet emoji. Tint changes with pet state: happy → green, sleepy → indigo, evolving → amber.

**Compact trailing** — live `timerInterval` countdown. iOS renders the digits natively; no polling, no refresh budget.

**Expanded** — full layout: pet, mood label, minutes remaining, and an interactive **Stop** button backed by `StopFocusIntent`. The button works without opening the app.

**Minimal** — single pet emoji, centered. Used when two Live Activities compete for the island.

The `StopFocusIntent` fires a Darwin notification (`CFNotificationCenterGetDarwinNotifyCenter`) received by the app on the main actor, routed to `TimerViewModel.cancel()`. No deep link. No URL scheme. The island talks to the app directly.

<br/>

---

## Design Language

```
Emotional Attachment  >  Feature Count
Polish                >  Complexity
Experience            >  Utility
```

**Tokens.Space** — 8-point grid throughout: `xs(4)`, `sm(8)`, `md(16)`, `lg(24)`, `xl(32)`, `xxl(48)`.

**Glass cards** — `.ultraThinMaterial` with layered gradient borders. Background-blur-aware. Not fake glassmorphism.

**Aurora background** — two animating radial gradients drifting slowly behind content. Never static. Never loud.

**Typography** — system SF with tracked small caps for section headers, monospaced `.tabularNumerals` for timer digits, `.largeTitle.weight(.black)` for the pet name. Intentional decisions throughout.

<br/>

---

## Getting Started

### Prerequisites

```
Xcode 15.2+
iOS 17+ device — iPhone 14 Pro or newer for Dynamic Island
Apple Developer Account with Live Activities entitlement
```

### Setup

```bash
# Option A — XcodeGen (recommended)
brew install xcodegen
git clone https://github.com/yourusername/IslandPet.git
cd IslandPet
xcodegen generate
open IslandPet.xcodeproj

# Option B — generated project file
git clone https://github.com/yourusername/IslandPet.git
cd IslandPet
python3 generate_pbxproj.py
open IslandPet.xcodeproj
```

### Configure

```
1. Set your Development Team in both targets (IslandPet + IslandPetWidget)
2. Update App Group ID in AppGroup.swift if needed (default: group.com.islandpet.shared)
3. Deploy to a physical device — Live Activities require hardware
4. Start a focus session and watch the Dynamic Island
```

> ⚠️ The simulator does not support Live Activities or Dynamic Island. A real device is required to experience the core feature.

<br/>

---

## Roadmap

```
v1.0 — MVP  ✓ complete
 ✓  Pomodoro focus engine with pause/resume
 ✓  Pet XP, mood decay, and evolution system
 ✓  Dynamic Island Live Activity with interactive Stop
 ✓  Lock screen widget (5 families)
 ✓  Personality system: stable traits + memory + voice
 ✓  Evolution cinematic with on-device share card
 ✓  Streak + freeze logic with loss-aversion notifications
 ✓  Notification retention loops (streak-saver, sad-pet, completion)
 ✓  Motion design system + CoreHaptics score
 ✓  SwiftData persistence with App Group bridge to widgets

v1.1 — Art & Monetisation
 ○  Commissioned pet illustrations (egg → baby → teen → adult)
 ○  Rive animation integration (idle / happy / sleepy / evolving states)
 ○  StoreKit 2 paywall — placed after second evolution, at peak emotional investment
 ○  iCloud sync via CloudKit

v1.2 — Social
 ○  Co-focus rooms (study together, pets visible to each other)
 ○  Friends + streak comparisons
 ○  Seasonal species drops
 ○  Branching evolution paths per species
```

<br/>

---

## The Honest State of the Project

**What's solid:** Architecture, systems, and design language are production-grade. MVVM is clean. SwiftData is wired correctly with an App Group bridge. The Live Activity integration is real ActivityKit — not a workaround. The personality system ships fully offline. The haptic score uses actual `CHHapticPattern` compositions. The evolution cinematic is demoable today.

**What's missing:** Custom illustrations. The procedural `PetSprite` is the ceiling. Every other improvement is capped at "well-engineered prototype" until there's hand-drawn art. The swap-in path is ready — commissioning the illustrations is the highest-leverage non-code investment before launch.

**What's unverified:** The `project.pbxproj` is programmatically generated and structurally sound, but hasn't been opened in every Xcode version. `xcodegen generate` from `project.yml` is the safer path.

<br/>

---

## Inspiration

| App | What it proved |
|---|---|
| **Duolingo** | Streak fragility drives daily retention better than any feature set |
| **Finch** | Users form genuine emotional bonds with simple digital companions |
| **Forest** | Pairing productivity with something to lose creates habit |
| **Headspace** | Personality and voice are a product layer, not a feature |

IslandPet's thesis: none of them built deep into the operating system. Dynamic Island as the primary demoable surface is technically defensible, instantly readable in a 5-second screen record, and something Apple's editorial team actively rewards. That's the moat.

<br/>

---

## Author

**Yash Raj**  
B.Tech CSE (AI/ML) · SRM Institute of Science and Technology

Building products that feel as considered as they are functional.

[![GitHub](https://img.shields.io/badge/@yourusername-181717?style=flat-square&logo=github)](https://github.com/yourusername)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?style=flat-square&logo=linkedin)](https://linkedin.com/in/yourusername)
[![Twitter](https://img.shields.io/badge/@yourhandle-1DA1F2?style=flat-square&logo=twitter)](https://twitter.com/yourhandle)

<br/>

---

## License

MIT. Build on it, fork it, ship your own version.  
If IslandPet becomes something, open an issue or just say hi.

<br/>

---

<div align="center">

*From discipline → to attachment*  
*From tracking → to caring*

<br/>

**⭐ Star if the concept resonates.**

</div>
