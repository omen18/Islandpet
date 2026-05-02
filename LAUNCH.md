# IslandPet — Launch Roadmap

## Phase 1 status (this session)

✅ Compile-clean architecture (no force-cast, no Mirror.set, no orphan code)
✅ MVVM with proper @StateObject ownership in `AppShell`
✅ Real today-stats via `@Query` predicate in `HomeView`
✅ NotificationService with three retention loops (streak, sad-pet, focus-complete)
✅ Hardened ModelContainer with graceful fallback
✅ Streak Freeze logic (forgives one missed day, earns one every 7)
✅ EvolutionCinematicView (the one viral moment)
✅ Onboarding upgraded: 5 pages with promise + permission ask
✅ TimerView celebration sheet with XP count-up + "one more session" CTA
✅ Dynamic Island Stop button via `LiveActivityIntent`
✅ Cross-target StopFocusIntent in Shared/
✅ Pbxproj generator updated for new files
✅ Assets.xcassets stub with AppIcon + AccentColor

## Phase 2 (next 2 weeks) — Apple-quality polish

### High leverage
- [ ] **Hire an illustrator.** The procedural sprite is functional, not lovable. Budget: $500–2000 for 4 species × 4 stages × 6 mood states = 96 sprites. Talk to Mighty Bear, Sticker Mule, or freelance via Cara/Are.na.
- [ ] **Add Rive `.riv` files** to `Resources/Animations/` so `RivePetView` activates. State machine input named `mood` (Number 0–5). Ship the procedural fallback for safety.
- [ ] **Sound design.** Royalty-free pack from Soundsnap or commission a 5-effect set: tap, level-up, evolution, sad-coo, hatch. ~$200.
- [ ] **Empty states.** First-launch HomeView still shows "0 sessions" — make it warm: "Tap the egg to begin your first focus session."
- [ ] **Settings screen.** Currently inline on Profile. Break out: app icon switcher (Premium), Pomodoro intervals, focus chimes, time-of-day for streak reminders.
- [ ] **iCloud sync.** Add `cloudKitDatabase: .private(...)` to `ModelConfiguration`. Test on two devices.
- [ ] **Animation polish pass.** Every tab transition should feel intentional. Use `.matchedGeometryEffect` for the pet hand-off between Home → Timer.

### Delight moments
- [ ] **Confetti when streak hits 7/30/100.** Reuse `ParticleBurstView` from cinematic.
- [ ] **Pet reactions to taps.** Tap pet on Home → it bumps + tiny giggle haptic.
- [ ] **First-time tooltips.** On first focus-completion, point at the streak badge.
- [ ] **Time-of-day backgrounds.** Aurora warms at sunset, cools at night.

## Phase 3 — TestFlight checklist

### Before you upload
- [ ] Set **DEVELOPMENT_TEAM** in `project.yml` (or use Xcode UI under Signing & Capabilities)
- [ ] Verify **App Group** `group.com.islandpet.shared` exists in your Apple Developer account, attached to **both** App ID and Widget App ID
- [ ] Add capabilities to both targets in Xcode: Signing & Capabilities → + → App Groups
- [ ] **AppIcon**: replace the placeholder. 1024×1024 PNG, no transparency, no rounded corners
- [ ] **Privacy** — add to `Info.plist`:
  - `NSUserNotificationsUsageDescription` (already implied via UNUserNotificationCenter)
  - No camera, mic, location used → nothing else needed
- [ ] **Privacy nutrition labels** in App Store Connect: "Data not collected" if you don't add analytics yet. Otherwise: Diagnostics → Crash Data, Performance Data
- [ ] **Test on real device**: Live Activities don't work in simulator. You need an iPhone 14 Pro or newer to verify Dynamic Island
- [ ] **Test offline**: airplane mode for 5 min, confirm timer + decay still work
- [ ] **Test backgrounding**: start a 1-minute focus, lock phone, confirm notification fires when timer ends
- [ ] **Test the kill-and-relaunch path**: SwiftData should restore the pet
- [ ] **Test streak freeze**: change device date forward 2 days, complete a focus → freeze should be consumed

### Build settings to verify
- [ ] iOS Deployment Target: **17.0**
- [ ] Swift Language Version: 5.10
- [ ] **Skip Install** = YES on widget target only
- [ ] **Embed App Extensions** build phase exists in app target
- [ ] Bundle IDs follow pattern: `com.islandpet.app` and `com.islandpet.app.widget`

### App Store Connect
- [ ] Create app record with bundle ID `com.islandpet.app`
- [ ] Set primary language, category (**Productivity**, secondary **Education**)
- [ ] Age rating: 4+ (no content concerns)
- [ ] Pricing: Free
- [ ] In-app purchases: defer to after first 100 testers
- [ ] Build expiry: TestFlight builds last 90 days
- [ ] Review notes: "First launch shows onboarding. To test Live Activity, start a focus session of 1 minute (set via the 15m preset and edit duration). Pet appears in Dynamic Island. Tap and hold to expand."

## Phase 3 — Marketing assets

### App icon ideas (commission these)
1. **The egg with a glow** — single hero element on aurora background. Most ownable.
2. **The Dynamic Island as a physical island** — meta-joke, very TikTok-able, Apple editorial bait.
3. **A pet eye peering over a clock face** — competes with Forest's tree

### App Store screenshots (5 panels for iPhone 6.7")
1. **Hero**: Dynamic Island shown larger-than-life with pet inside, headline "Your pet lives in the island."
2. **Pomodoro screen** with the ring + sprite, headline "Focus to grow."
3. **Evolution moment** still frame, headline "Watch them evolve."
4. **Streak/Profile** screen, headline "Don't break the chain."
5. **Lock screen + home widget** mocked together, headline "Always with you."

Use `Mockuuups Studio` or `Rotato` for device frames.

### Subtitle (30 chars)
"A pet that grows when you focus."

### Keywords (100 chars)
`pomodoro,focus,timer,study,pet,tamagotchi,habit,streak,dynamic island,widget`

### Description first paragraph (the one that converts)
> Meet IslandPet — the only focus app where your companion lives inside your Dynamic Island. Start a Pomodoro and they'll cheer you on from the top of your screen. Finish your session and they grow. Skip a day and they'll miss you. The longer you stick with it, the more they evolve.

### Pricing strategy
- **Free** to download
- **IslandPet Plus**: $3.99/mo, $24.99/yr, $49.99 lifetime
  - Unlimited pets (free = 1)
  - Premium species: 4 free + 8 Plus
  - Custom Pomodoro presets
  - iCloud sync
  - All shop items unlocked
- **Paywall placement**: triggered on the *second* evolution (peak emotional investment), never before
- **Lifetime sale**: $29.99 launch-week pricing → drives reviews + lifetime LTV ceiling

## Phase 4 — Growth experiments to run

### Viral loops (rank-ordered)
1. **Evolution share sheet** — already built. Add a watermarked share image with "Hatched on IslandPet — link in bio" framing
2. **Co-focus rooms** — invite a friend; both pets sit in your Dynamic Island during the session. Highest virality, hardest to build (~3 weeks of work)
3. **Pet adoption referral** — refer a friend, both get a rare egg variant. Standard but proven (Duolingo super)
4. **Streak save** — when about to break a streak, prompt "ask a friend to send a 1-minute focus to save your pet?" (very emotional)

### Retention experiments
- **Day 2 push**: "Your pet is sleeping… they hatch tomorrow if you focus today" — use real evolution math
- **Day 7 push**: "Look how much they've grown" — image of before/after
- **Day 30 push**: "Final form unlocked!" — leads to share sheet

### Monetization experiments to run after 1k DAU
- Plus paywall placement: A/B test 2nd evolution vs. 7-day streak vs. shop-tap entry
- Pricing: $3.99/mo vs. $4.99/mo (annual locked at $24.99 to anchor)
- Paywall offer: "Unlock 30% off — your pet brought you a coupon"

## Indie launch playbook (week-by-week)

| Week | Goal | Deliverable |
|------|------|-------------|
| W-3 | Build green on TestFlight | Internal build with team of 5 |
| W-2 | Beta to 50 friends/family via TestFlight Public Link | Collect crash reports, screen recordings |
| W-1 | Press kit + Product Hunt prep | Email 30 indie iOS bloggers, schedule PH launch for Tuesday |
| W0 | Launch day | Product Hunt + Twitter/X thread + r/iosapps + r/iosgaming + 1 TikTok demo |
| W+1 | Iterate on top 3 complaints | Patch release |
| W+2 | First paid acquisition test ($100/day on TikTok ads with the evolution clip) | Measure CPI vs. D7 retention |
| W+4 | Decide: scale, pivot, or kill | Need ≥40% D1, ≥15% D7 to continue |

## What I'd do differently if this were my startup

1. **Don't ship without an illustrator.** The procedural sprite is the single biggest reason people will swipe past your screenshots. Pay $1k. Worth 100x.
2. **Build the Plus paywall, ship it disabled.** Decide tier inclusion after you have data.
3. **Don't build the AI chat.** It's a vanity feature. Replace with a journaling page (huge in this category — see Finch).
4. **Add Apple Watch.** Hatching the egg from your wrist is a stronger moment than Dynamic Island.
5. **Invest in your launch video before code.** The TikTok demo is the product.
