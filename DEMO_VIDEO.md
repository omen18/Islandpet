# IslandPet — 30-Second Demo Video

**The single most important marketing asset before launch.**

This is the video that goes on:
- Your App Store preview (mp4, ≤30s, vertical 1080×1920)
- Your TikTok / Reels / Shorts launch post
- Your Product Hunt header
- Your investor / illustrator outreach DMs
- Your press kit

If this video is 🔥 you win. If it's average no one cares. Treat it that way.

---

## The hook problem

You have 1.5 seconds before someone swipes. The first frame must answer:
**"Why is this different from every other study timer?"**

Your differentiator is the Dynamic Island. So the first frame must show it.
Not the app. Not the egg. **The island.**

Most demo videos lead with the splash screen. That's a mistake — splashes are
for users, not viewers. Lead with the magic.

---

## Final cut — 27 seconds, 7 shots

| # | Time | Shot | What's on screen | Audio |
|---|------|------|------------------|-------|
| 1 | 0.0–2.0s | **Hook** | iPhone, status bar visible, finger taps "Start Focus". The pet pops out of the Dynamic Island with a tiny bounce. Camera is close — the island fills 60% of the frame. | Soft pop sfx + heartbeat starts low |
| 2 | 2.0–5.0s | **The promise** | Long-press the island to expand it. Pet is bouncing inside, mood "focusing", progress ring filling. Lift finger — collapses smoothly. | Heartbeat continues |
| 3 | 5.0–11.0s | **The grind** | Time-lapse: phone on a desk, person studying in the background (out of focus). Island ticks down 25:00 → 00:00 (sped 50×). Pet idles, blinks, occasionally bobs. | Heartbeat, ambient room tone |
| 4 | 11.0–14.0s | **Completion** | Timer hits 00:00. Pet jumps. Confetti bursts from the island. Notification banner slides down: "+50 XP". | Level-up chime, haptic visual cue (subtle screen flash) |
| 5 | 14.0–18.0s | **Open the app** | User opens IslandPet. Home screen. The pet is now glowing — egg cracking. Camera zooms into the cinematic. | Music swells |
| 6 | 18.0–24.0s | **The wow** | Full evolution cinematic plays. Egg shakes → flash → reveal of the baby pet. Particle burst. "Mochi evolved!" label. | Evolution chord, full music |
| 7 | 24.0–27.0s | **The pitch** | Cut to title card: "**IslandPet** — A focus pet that lives in your Dynamic Island." App icon, "On the App Store." End. | Music tail |

**Total runtime: 27s** (App Store preview limit is 30s — leave headroom).

---

## What to shoot

You need exactly **two real recordings**, plus the App Store card overlay.

### Recording A: The Dynamic Island (shots 1, 2, 3, 4)

Use **iOS Screen Recording** (Settings → Control Center → Screen Recording).

You need a phone with Dynamic Island: **iPhone 14 Pro or later, on iOS 17+.**
The simulator does *not* render the island correctly for video.

Setup:
- Charge phone to >50% (no battery indicator weirdness).
- Enable Do Not Disturb (no random notification banners ruining the take).
- Set time to 9:41 (the Apple convention — yes, do this, it looks Apple-shot).
- Make the wallpaper plain — solid dark gray (#0F0F12). Removes distraction.

Take:
1. Start screen recording.
2. From Home Screen, open IslandPet → Focus tab.
3. Tap a 25-minute preset. Tap **Start**.
4. Once the island animation completes, hold the island to expand it, hold for 1.5s, release.
5. Lock the phone. (We'll cut between locked and unlocked in editing.)
6. Wait. Or don't — we'll time-lapse this in post.
7. When the timer ends, capture the completion banner.
8. Stop recording.

You only need one good take of each beat. Capture multiple of beat 1 (the
hook) — that's the most important frame in the whole video.

### Recording B: The cinematic (shots 5, 6)

Same recording setup. Force the evolution by:
- Either: temporarily lower the egg→baby threshold to 1 XP in `Pet.stageThresholds`,
  complete a 1-minute focus session.
- Or: in a debug menu, call `petVM.awardXP(50)`. (You should add a debug menu
  before TestFlight anyway — see Part 2 below.)

Capture: home screen → tap into pet → cinematic plays end-to-end → share
sheet appears → dismiss.

### Title card (shot 7)

Make in Figma or Canva. 1080×1920 vertical. Black background. Centered:

```
        IslandPet
        ─────────
   A focus pet that lives
  in your Dynamic Island.

       [App Icon]
     On the App Store
```

Use SF Pro Rounded Bold for the wordmark, SF Pro Rounded Medium for the tag.

---

## Editing

Use **CapCut** (free, mobile, fast) or **Final Cut Pro**.

### The pacing rule

- Shots 1–4: tight cuts, 1–3 seconds each. Don't dwell.
- Shot 3 (the grind): aggressive speed-up. People scrolling don't want to
  watch a 25-minute focus session. They want to feel one. 50× is right.
- Shot 6 (the cinematic): **let it breathe.** This is the moment. 6 full
  seconds. No cuts, no zoom, no overlay. Just the cinematic doing its thing.

### Audio

You need **three audio elements**, layered:

1. **A heartbeat ambient track** during shots 1–4. Free option: search
   "ambient heartbeat" on Pixabay or Freesound, CC0. Loop it. Quiet —
   this is felt more than heard.
2. **Three sound effects**: the pop (shot 1), the level-up chime (shot 4),
   the evolution chord (shot 6). Free: zapsplat.com (sign-up required) or
   pixabay.com/sound-effects.
3. **A music swell** that builds through shots 5–7. Free: search "uplifting
   ambient" on Pixabay Music. License-free, attribution-free.

**Critical:** the App Store preview policy requires you own the music license.
Pixabay Music is safe; YouTube Audio Library is safe; anything from a popular
song is not.

### On-screen text

Don't add captions explaining what's happening. The product should be
self-evident. The only text on screen is the title card at the end.

If you must, add ONE caption — at the very start, top of frame:
**"Tap to start focusing →"**
Hold for 1 second, fade out as the user taps. That's it.

### Color grading

A subtle warm grade (slight orange in highlights, slight teal in shadows)
makes everything feel more cinematic. CapCut → Adjust → Tone. Five seconds
of work. Don't overdo it — Apple's preview review will reject videos that
look color-shifted from reality.

---

## The two-second test

Before posting: send the video to one friend who doesn't know what IslandPet is.
Watch them watch it. Note where their eyes go.

- Did they understand it's a focus app within 5 seconds? If no → the hook isn't working.
- Did they laugh, smile, or "oh!" at the cinematic? If no → the cinematic isn't strong enough yet (likely because the sprite is procedural).
- Would they show this to a friend? If no → don't ship the video. Keep iterating.

Pass the test → post it. Don't pass → fix the weakest beat and reshoot. The
video is the product before the product is the product.

---

## Where to post (launch week sequence)

1. **Day -1 (Sunday night IST / Monday morning PST):** Post to your personal
   X/Twitter as a quote-thread. Tag @AppStore (they read these).
2. **Day 0 morning:** Product Hunt launch post uses this video as the hero.
3. **Day 0 afternoon:** Post to TikTok. Caption: "I built a focus app where
   your pet lives in the Dynamic Island. been working on it for [N] weeks".
   Add hashtags: #buildinpublic #ios #indiedev #focus #studytok.
4. **Day 0 evening:** Reels/Shorts cross-post.
5. **Day +1:** Email 20 indie iOS bloggers (NickenSoft, BasicAppleGuy,
   Federico Viticci at MacStories, Ryan Christoffel) with the video embedded.

Do not post the same video to all four platforms simultaneously — TikTok's
algorithm penalizes content it has already seen on Reels/Shorts. Stagger by
a few hours.

---

## What this is *not*

- Not a feature tour. No screenshots of the shop, achievements, settings,
  chat. Those go in the App Store screenshot grid, not the video.
- Not a tutorial. The video is for people who haven't installed yet.
- Not a vlog. No face cam, no voiceover, no "hey guys today we're looking
  at IslandPet." The product speaks for itself or it doesn't.
