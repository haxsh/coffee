# Session Handoff — Grind (coffee app for iOS)

**Written:** 2026-09-02 · **Repo:** `haxsh/coffee` · **Branch:** `claude/coffee-learning-recipe-app-rtyv9s` · **HEAD:** `27fa0f7`
**Owner:** Harsh (harsh@mind-alliance.com) — product designer / BA at Mind-Alliance
**CI:** green (GitHub Actions, `.github/workflows/ios.yml`) — app + widgets compile, 95 domain tests pass

This document exists so another model can pick this project up cold. It records
what was decided, what was built, **why** the non-obvious decisions were made, and
which invariants must not be broken. Read §1, §3 and §11 before changing anything.

---

## 1. Orientation — what this is, in one page

**Grind** is an iOS app (SwiftUI, iOS 18+) for home coffee brewing, aimed at the
**Indian metro market** (Mumbai, Bangalore, Pune). Working name only — "Grind" is a
placeholder and almost certainly taken.

It is built around **two loops**, and the app's central job is escorting a user from
the first into the second:

```
   EXPLORATION LOOP                          MASTERY LOOP
   months 0–1 · acquisition                  month 2+ · retention

   discover ──▶ try ──▶ compare              brew ──▶ taste ──▶ diagnose
      ▲                    │                   ▲                    │
      └──── prefer ◀───────┘                   └──── adjust ◀───────┘
                  │                                      ▲
                  └──────── "this is my method" ─────────┘
                                    ↑
                        the handoff — the whole bet
```

**North star:** % of users who reach 5 logged brews on a *single* method within 30
days. It measures the handoff, which neither loop measures alone.

**The differentiator** is the diagnosis engine: after a brew you answer two
questions in under 30 seconds, and the app names one cause and **exactly one**
change, in your own grinder's units, with a concept card explaining why.

**Breadth is affordable** because methods are supported at three tiers — full
diagnosis, guided timer only, or an honest reference card. The rule that everything
else serves: **a method never implies precision the engine doesn't have.**

### Current state in one line

Design complete (8 docs), code complete for v1 scope, CI green, **and nobody has
ever run the app or seen a single screen.**

---

## 2. Session history — what the user asked for, in order

Chronological, because several decisions supersede earlier ones.

| # | User's request | Outcome |
|---|---|---|
| 1 | *"I want to create a coffee learning and recipe app for ios."* | Asked scope. User chose **design/spec first** (not code yet) and **all four pillars**: brew recipes + timer, learning lessons, brew journal, bean library. → 8 spec docs written (`docs/00`–`06`). |
| 2 | *"what do you want me to do to actually build it? I need an ios app and it needs to support widgets."* | User answered: **Mac but no Xcode yet**, **iOS 18 floor**, **all four widgets**. → Full SwiftUI app + widget extension + CI built. |
| 3 | Pasted a **repositioning brief** (now `docs/07`) and asked for three passes, stopping after each. | The product changed from *mastery of one method (V60)* to *guided exploration across many methods, for Indian metros*. Three passes executed. |
| 4 | Feedback on three arguments I raised: **1. milk is confirmed. 2. don't put too much emphasis on water. 3. the app should change what it will say when user tells they have pre-ground coffee, or a grinder.** | All three implemented. #3 became the largest single change in Pass 2 — see §5.4. |
| 5 | *"now I want to test this app? how can I do so?"* | Offered four routes; user chose **finish Pass 3 first**. |
| 6 | *"are we good for the v1 of this app or is there anything major to fix before?"* | Audit found and fixed 2 bugs (§9). Answer: code is sound, but two non-code blockers remain (§10). |
| 7 | *"cool so we are good for xcode run... I am not publishing now."* | Confirmed. Publishing concerns parked. |

### Standing user preferences observed

- Terse, decisive. Answers in fragments; expects you to fill in the rest competently.
- **Wants to be argued with.** Explicitly instructed: *"If anything in the brief
  conflicts with something in the code you think is better reasoned, stop and argue
  with me rather than silently picking one."* This produced the three best decisions
  in the project (§5.2–5.4). Do not just implement — push back when warranted.
- Values honesty about what is and isn't verified.
- Not publishing yet. App Store / paid-account concerns are parked.

---

## 3. Invariants — do not break these

These are load-bearing product decisions, several of them argued for at length in
the docs. Violating one silently would undo the reasoning behind the whole product.

| # | Invariant | Why |
|---|---|---|
| I1 | **Exactly one suggested change per diagnosis. Never a ranked list.** | Two variables moving at once makes the result uninterpretable, and users pick the easiest option. This is the entire premise. |
| I2 | **A tier 2 method must never look like it diagnosed you.** `MethodNotes` shares no layout component with `NextTimeView` — no single-change card, no from→to numbers, "Got it" not "Save for next time". | The app claims precision on 2 of 12 methods. If tier 2 borrows tier 1's clothes, it claims it on all of them. |
| I3 | **Tier gating is enforced in the engine, not the UI.** `evaluate()` returns `DiagnosisOutcome`; there is no path through the type that lets a `.guided` method produce a `Diagnosis`. | A screen cannot promote a method by accident, because the value it would need doesn't exist. |
| I4 | **Milk swaps the taste axis; it does not suppress rules.** | Milk makes sour↔bitter *unanswerable*. Suppressing rules downstream still asks a question and discards the answer. Anything reading a `TasteRecord` must consult `withMilk` first. |
| I5 | **A pre-ground user is never told to grind.** | Grind is the primary lever, and a large share of this market buys pre-ground. |
| I6 | **The water rule fires once, then steps aside** (`hasSeenWaterAdvice`). | Without the gate, an RO user who is *also* grinding badly is told "it's your water" forever and the mastery loop never advances. |
| I7 | **No beginner/advanced mode selector.** Progressive disclosure driven by logged brew count only. | A mode toggle doubles every screen and string, and is very hard to remove later. See `docs/07` §6. |
| I8 | **Cold brew never enters the guided timer flow.** | 12-hour feedback loop; the daily brew→taste→adjust cycle cannot run. Tier 3 forever, unless the model changes. |
| I9 | **Post-brew log median ≤ 30 seconds.** No feature gets a budget increase — the milk toggle was scoped and defaulted specifically to cost zero taps in steady state. | Logging is the single point of failure; everything downstream assumes it happened. |
| I10 | **Export is never paywalled, never restricted, works offline.** | The product's premise is trust. A journal you can't get out isn't yours. |
| I11 | **Offline-first, local-only. No accounts, no network calls.** | No spinner is acceptable mid-pour. |
| I12 | **Vocabulary lock** (code, copy, docs): **Brew** (never session/log/entry/cup) · **Bean** (never coffee/bag/roast) · **Recipe** (never preset/profile) · **Method** (never brewer/device) · **Concept** (never term/tip/card) · **Step** (never stage/phase) · **Grind setting** (never grind size, for the user's dial). | Drift here shows up as inconsistent UI copy that nobody can trace back. |
| I13 | **Pointing outward at gear/roasters is allowed only at a triggered moment** (bag going stale, lesson ending). Never a browsable directory, never a persistent surface. | A directory makes us a shop, and a shop can't be trusted to teach. Changed from "never" during the repositioning — the rule is about *when*, not *whether*. |

---

## 4. Repository layout

```
coffee/
├── HANDOFF.md            ← this file
├── README.md             overview + verification status
├── BUILD.md              how to build, what to test first, what's still needed
├── project.yml           XcodeGen source of truth (the .xcodeproj is NOT committed)
├── .github/workflows/ios.yml
├── docs/                 00–07, the full design record (see §12)
├── Packages/CoffeeKit/   domain layer — pure Foundation, no UI, no ActivityKit
│   ├── Sources/CoffeeKit/
│   │   ├── Models/       BrewMethod, Recipe, Brew, Bean, Grinder, TasteRecord,
│   │   │                 BrewParameters, BrewContext (WaterSource, GrindControl), Concept
│   │   ├── Brewing/      BrewMath
│   │   ├── Diagnosis/    Diagnosis, DiagnosisEngine, MethodNotesContent
│   │   ├── Content/      BuiltInContent (methods), BuiltInRecipes, Concepts
│   │   └── Shared/       WidgetSnapshot, SharedStore
│   └── Tests/            95 tests
├── Grind/                the app (SwiftUI, iOS 18+)
│   ├── Model/            AppData, AppModel, BrewFlow, BrewSession
│   ├── Views/            Brew/, Beans/, Journal/, Learn/, Profile/, Components/
│   ├── Design/Theme.swift
│   └── Resources/        Assets.xcassets, Sounds/ (3 generated WAV cues)
├── GrindWidgets/         widget extension (4 widgets)
└── Shared/               compiled into BOTH iOS targets:
                          BrewActivityAttributes (ActivityKit), BrewIntents (AppIntents)
```

**~3,300 lines domain · ~1,100 lines tests · ~4,100 lines app · ~500 lines widgets · ~2,600 lines docs.**

### Why the structure is like this

- **CoffeeKit is pure Foundation on purpose.** No SwiftUI, no ActivityKit, no UIKit.
  That is what lets `swift test --package-path Packages/CoffeeKit` verify the whole
  diagnosis engine on any machine with no Xcode and no simulator. This mattered
  enormously: the entire project was authored in a Linux container with **no Swift
  toolchain** (swift.org is blocked by the environment's network policy), so CI was
  the only compiler. Keep it pure.
- **`Shared/` exists** because ActivityKit and AppIntents types must be in both the
  app and the widget extension, but putting them in CoffeeKit would poison its
  portability.
- **`project.yml` is the source of truth**, `.xcodeproj` is git-ignored. A pbxproj is
  unreviewable in a diff and a merge-conflict machine. Run `xcodegen generate` after
  pulling or after adding a top-level folder.
- **Persistence is a single Codable JSON document**, not SwiftData. Deliberate: the
  journal is small, v1 has no sync, export is a hard requirement, and the widget
  extension (a second process) reads the same App Group container. SwiftData +
  CloudKit is the right answer when sync arrives in v1.1; it was the wrong answer
  for shipping the loop. Documented in `docs/02` §5.

---

## 5. The diagnosis engine — the most important subsystem

`Packages/CoffeeKit/Sources/CoffeeKit/Diagnosis/DiagnosisEngine.swift`

### 5.1 The model

Two axes the user answers, which map to two independent things beginners conflate:

- **Extraction** — how much was pulled out. Sour/thin ↔ bitter/drying. Moved by grind.
- **Strength** — how much is dissolved per sip. Watery ↔ muddy. Moved by ratio.

`DiagnosisThresholds` holds **every tunable number in one struct**, specifically so a
roaster who doesn't code can read it end to end and argue with it. Keep it that way.

### 5.2 Rule order (first match wins)

Four gates run before the table: **tier**, **milk**, **water**, **grind control**.

| ID | Condition | Change |
|---|---|---|
| 1 | Bean still resting (roast-level aware) & cup not balanced | Nothing — degassing |
| 2 | Bean stale + staling descriptor | Nothing — it's the bag |
| 3 | RO water + sour/thin/flat + advice not yet seen | Blend 70:30 RO:tap |
| 4 | Under-extracted **and** water below 88 °C | Hotter water |
| 5 | Under-extracted (pour-over) | Grind finer |
| 6 | Over-extracted + drawdown ran long | Grind coarser |
| 7 | Over-extracted (pour-over) | Grind coarser |
| 8 | Extraction fine, cup dilute | Less water |
| 9 | Extraction fine, cup concentrated | More water |
| 10 | Balanced + rated ≥4 | Nothing — save as your recipe |
| 11 | Balanced + rated ≤3 | Bean or water, not technique |
| 12 | Fallback | Brew it the same way once more |
| **20** | French press + grit descriptor | Coarser + press gently (fines, *not* over-extraction) |
| **21** | Under-extracted (immersion) | **Steep longer** — time before grind |
| **22** | Over-extracted (immersion) | **Steep less** |
| **30** | Milk drink, harsh/burnt | Back off heat or time |
| **31** | Milk drink, flat/washed out | Stronger ratio (strength, not extraction) |

**Rules 20–22 are the French press table.** They exist to prove the tier model
generalises: immersion is *time-dominant* where pour-over is *grind-dominant*. If the
second table had merely been the first with different numbers, that would have been
evidence the model was shaped around V60. It wasn't.

> **Correction made to the original spec:** rule 4 (temperature) was originally
> listed last, which made it **unreachable** behind the generic under-extraction rule
> — and it gave the wrong advice besides, since water well below range swamps grind.
> Moved to position 4 with a regression test.

### 5.3 Milk — the axis swap

`TasteRecord.milkCharacter` (−2 harsh/burnt … 0 smooth … +2 flat/dull) is a separate
field from `extraction`. The log screen asks **one or the other**, same position, same
one tap. `Brew.withMilk` decides which.

This was argued rather than transcribed. The brief said *"suppress acidity-driven
rules"*; implemented literally that still asks a question, takes the tap, and
discards the answer. Milk fat and protein bind to exactly the compounds that read as
acidity and bitterness — a milk drinker **cannot** place a cup on sour↔bitter.

**This is also why South Indian filter and moka cannot be tier 1 yet.** Promoting a
milk-first method needs a second *diagnosis model* for the milk axis pair, not just a
second rule table — a materially bigger piece of work. That is the substantive answer
to the brief's open question about filter coffee's tier. Tracked as **OQ-9**.

### 5.4 Grind control — the pre-ground path

`GrindControl` models grind as a **capability**, not an assumption:

```swift
case calibrated(Grinder, setting: Double)  // "18 → 16 clicks on your Encore"
case uncalibrated                           // "one step finer than last time"
case preGround                              // grind is NOT a lever
```

For `.preGround` the engine spends the levers the user actually has, in order:
**temperature → contact time → ratio** — and when those run out it says the true
thing and names a brewer that suits the coffee they bought:

> **Try a moka pot** · Pre-ground this fine suits a moka pot better than a V60

That fallback only works *because* the app knows twelve methods, so the repositioning
quietly became a diagnosis feature. It also routes a stuck mastery-loop user back
into the exploration loop, which is the handoff running in reverse when it should.

This came directly from the user's third piece of feedback and is the single largest
change in Pass 2.

### 5.5 Water — deliberately small

Per the user's *"don't put too much emphasis on water"*: one profile field, one rule
(3), one paragraph appended to the existing water concept card. No calculator, no
mineral profiles, no TDS. The rule interrupts **once** and then steps aside (I6).

---

## 6. Content inventory

### Methods — 12, at three tiers

| Method | ID | Tier | Notes |
|---|---|---|---|
| V60 | `v60` | **full** | 3 recipes. Grind-dominant. |
| French press | `frenchpress` | **full** | 2 recipes. Time-dominant. The generalisation test. |
| AeroPress | `aeropress` | guided | 1 recipe |
| Moka pot | `moka` | guided | 1 recipe · takesMilk |
| South Indian filter | `southindianfilter` | guided | 1 recipe · takesMilk · the strongest differentiator; no competitor models it |
| Kalita Wave | `kalita` | guided | 1 recipe |
| Cold brew | `coldbrew` | reference | 12h loop — never in the timer (I8) |
| Espresso | `espresso` | reference | Own diagnosis model needed; own initiative |
| Instant | `instant` | reference | Where most beginners start; honest "why step up" card |
| Chemex / Siphon / Cezve | — | reference | Browse value |

`MethodProfile` carries the five Explorer axes: **effort, time, gearCost, fussiness,
tastesLike** — plus `worksWithPreGround`.

> `fussiness` was originally named `forgiveness`, but the values run *1 = hard to get
> wrong, 5 = punishes every mistake* — so V60's `4` would have rendered a nearly-full
> "forgiving" meter on the least forgiving brewer. Renamed before it reached a pixel.

### Concepts — 27

Includes: extraction, strength, under/over-extraction, brew-ratio, grind-size,
burr-grinder, bloom, degassing, staling, agitation, channeling, drawdown,
water-temperature, water-chemistry, roast-level, **milk, immersion, fines, chicory,
pre-ground**, and six `about-*` overview cards for the reference methods.

`ContentIntegrityTests` asserts every concept link resolves — from rules, recipes,
methods, descriptors and method notes. A dangling link would fail in the exact moment
a user asked for help.

### Lessons — none, deliberately

The Learn tab ships as the concept library and says so. Lessons are a **writing
project** needing someone who knows coffee (**OQ-7**), not a build task. Shipping
empty course shells would be worse than shipping none.

---

## 7. The app layer

**Four tabs**: Brew · Learn · Beans · Journal. Profile lives behind an avatar button
on every tab root, not a fifth tab.

**The Brew tab is one root with two states**, not two screens: a user with no history
opens onto the **Method Explorer** (nothing to continue); one with history opens onto
**Continue**, with Explore one tap away and always visible. That is the two-loop model
expressed as navigation. Giving exploration its own tab was considered and rejected —
they are the same mode of engagement at two moments in one person's life.

| Screen | File | Notes |
|---|---|---|
| Onboarding | `OnboardingView` | 5 pages. Pre-ground is a **first-class answer**, not an escape hatch. Water is one question. Ends at the Explorer, not at a recipe. |
| Method Explorer (S29) | `MethodExplorerView` | Comparable rows + 4 meters. Sorted by *what you can make today*, deliberately **not** tier-first (that would read as a paywall). Includes the shelf. |
| Method Detail | `MethodDetailView` | Three shapes. Reference methods are leaves that say so **in words** — never a disabled Start button — and offer two brewable methods onward. |
| Brew Setup | `BrewSetupView` | Everything pre-filled. Applies pending adjustments through a switch **exhaustive over `BrewParamKey`**. |
| Guided Brew (S05) | `GuidedBrewView` | The hero. 90pt clock, cumulative water target, ≥88pt controls, audio + haptic cues, Live Activity, auto-advances into the log. |
| Log Brew (S06) | `LogBrewView` | ≤30s. Rating + two axes = 3 taps above the fold. Milk toggle only where milk is normal. |
| Next Time (S07) | `NextTimeView` | The payoff. One change, in the user's units. Tier 1 only. |
| Method Notes (S30) | `MethodNotesView` | Tier 2. **Shares no component with Next Time** (I2). |
| Learn / Beans / Journal / Profile | — | Concept library · bean shelf with roast-aware freshness · journal with planned-vs-actual · export + gear |

**The shelf** (methods tried) is `Set(brews.map(\.methodID))` — **derived, never
stored**. A stored copy could disagree with the journal after a deleted brew, and
*"it says I tried Chemex and I never did"* is a trust bug in the one surface built to
feel like a record of your own doing. It cannot lapse or break — that's what separates
it from a streak.

### The design system

`Theme.swift`. Palette is grounded in *measurement*, not the beverage — deliberately
avoiding the cream/serif/terracotta coffee cliché. Two accents carry meaning:
**water** (teal) for changes that pull extraction *up* out of sourness, **heat**
(amber-rust) for ones that pull it *back* from bitterness, **target** (green) for
balance. The same mapping is used on the taste axes, so colour teaches the scale.

---

## 8. Widgets

`GrindWidgets/` — all four the user asked for:

1. **Brew Again** (small/medium, interactive via `StartBrewIntent`) — last recipe,
   bean, and any pending adjustment; one tap into the brew.
2. **Bean Freshness** (small + Lock Screen circular/rectangular/inline).
3. **Brew Live Activity + Dynamic Island** — the clock renders via
   `Text(timerInterval:)` off a date, so the system animates it: **no push updates,
   no background execution, no drift**, and it survives a locked screen.
4. **Start a brew** — Control Centre / Lock Screen `ControlWidget` (iOS 18).

Widgets read a **small JSON projection** (`WidgetSnapshot`) the app writes to the App
Group on every mutation — never the app's own document. This keeps the widget process
out of schema migrations and file contention; a widget that crashes shows as a blank
tile, which users read as a broken app.

**App Group:** `group.com.haxsh.grind`. It appears in **four** places that must match
— `project.yml`, both `.entitlements`, and `AppGroup.identifier`. Listed in `BUILD.md`.

> App Groups require a **paid** Apple Developer account on a physical device. The
> Simulator works with a free Apple ID.

---

## 9. Bugs found and fixed — and the pattern behind them

Five real bugs were found. **Four share one root cause**, which is the most useful
thing in this document for whoever continues:

> **A value that is meaningful in one context, read in another where it isn't —
> because the engine and the UI have a contract that nothing was checking.**

| # | Bug | Found by |
|---|---|---|
| 1 | Temperature rule ordered last → **unreachable**, and wrong advice | Writing the engine from the spec |
| 2 | `SharedStore` resolved its own path → untestable, and the fallback doubled as a test seam | CI |
| 3 | New `Adjustment.Kind` cases left a colour switch non-exhaustive | CI |
| 4 | Descriptor vocabulary excluded `silty` from black coffee → **the French press silt rule could never fire**, because the log could never offer its trigger | Wiring Pass 3 |
| 5 | `MethodProfile.forgiveness` named opposite to its own values | Wiring Pass 3 |
| 6 | **`steepTime` stored but never honoured** — correct advice ("Steep longer, 4:00 → 4:45"), user taps "save for next time", brew is identical. Broken on *every* immersion method. | v1 audit |
| 7 | **CSV export wrote a milk brew's unanswered `extraction` as `0`** — which reads as "balanced" to anyone analysing their journal. Not a missing column, a *wrong* one. | v1 audit |

Bugs 4, 6 and 7 are the same class. Two generalised guards now exist:

- `ContentIntegrityTests.testEveryDescriptorTriggerIsReachable` — every
  descriptor-keyed rule must be selectable from some method's offered vocabulary.
- `BrewParamKey.userAdjustable` + `testEveryAdjustableParameterIsOneTheAppCanApply` —
  sweeps both rule tables across every recipe, water source and grind capability,
  asserting the engine never returns a lever the setup screen cannot apply.

**If you add a rule, a descriptor, or a parameter, check the third leg too.** Silently
ineffective advice is worse than no advice, because it looks like it worked.

---

## 10. What is verified, and what is not

### Verified
- App and widget extension **compile** for the iOS Simulator (macOS runner, Xcode 26.x).
- **95 domain tests pass**: both rule tables, the full extraction×strength grid, tier
  gating, milk suppression, the pre-ground path, grinder mapping, brew maths, steep
  scaling, journal migration, content integrity, the two contract guards.

### NOT verified — be honest about this
- **Nobody has ever run the app.** Not one screen has been seen by a human.
- Live Activity *behaviour* (real call mid-brew, Low Power Mode, Focus) — compiles,
  untested at runtime.
- Audio/haptic cues at an actual sink with wet hands.
- **No coffee professional has reviewed the rule tables.**

### The two real blockers before anyone else uses it

1. **OQ-1 — expert review of the rule tables.** Two full tables plus the 70:30 water
   claim. Thresholds are a designer's educated guesses. This audience can taste when
   advice is wrong and they talk to each other. An afternoon of a roaster's time.
   Everything tunable is in `DiagnosisThresholds` to make this reviewable.
2. **Somebody running the app.** Three bugs were found by reading; each was invisible
   to the test suite until someone went looking. The next one is probably visible in
   ten seconds on a screen.

Neither blocks the user running it themselves in the Simulator, which is where they
left it.

---

## 11. Open questions

| # | Question | Status |
|---|---|---|
| **OQ-1** | Who reviews the rule tables? | **Blocking before other users** |
| **OQ-9** | Can South Indian filter ever be tier 1? | Needs a second diagnosis model for milk-first drinks (§5.3). Would unlock filter + moka + espresso together. |
| **OQ-10** | Does the pre-ground user get a real product? | Largely answered in Pass 2, but unvalidated |
| OQ-2 | Free vs Pro line | Recommendation: journal, export and the engine are **never** paid |
| OQ-3 | Segments vs sliders for the taste axes | Segments shipped |
| OQ-4 | Roast-level freshness windows | Implemented roast-aware; thresholds unreviewed |
| OQ-5 | The name | "Grind" is a placeholder |
| OQ-7 | Who writes the lessons | Real authorial work, not a build task |
| OQ-8 | Analytics, and how to say so honestly | Every metric needs instrumentation |

### Highest-risk assumptions (full log in `docs/05`)

- **A14 — people explore, then settle.** The entire two-loop framing, the north star
  and the app's central job rest on it. **The app cannot test this.** Needs a 30-day
  diary study.
- **A5 — grinder ownership in Indian metros.** Grind is the primary lever, and the
  repositioning moved the market toward people less likely to own a grinder *and*
  made the engine the destination. The pre-ground path is the mitigation; nobody has
  checked whether four dials instead of five is enough.
- **A8 — the rule tables are professionally sound.** See OQ-1.

---

## 12. The documents

`docs/07` is the **source of truth** and supersedes `00`–`06` where they conflict.
All of `00`–`06` were reconciled to it in Pass 1, so conflicts should be rare.

| Doc | Contents |
|---|---|
| `00-product-brief.md` | Problem, two loops, Indian metro personas, north star, scope by tier |
| `01-ia-and-navigation.md` | Sitemap, 4 tabs, naming decisions, hierarchy re-run at 12 methods, edge cases, IA risks |
| `02-content-model.md` | Entities, tiers, the Concept layer, **the full diagnosis rule table**, the milk-axis argument |
| `03-screen-specs.md` | 31 screens; S05/S06/S07 specced deep; S29/S30 added in Pass 1 |
| `04-user-stories.md` | 8 epics with testable acceptance criteria; story map around the handoff |
| `05-assumptions-and-open-questions.md` | Assumption log, open questions, ranked risks |
| `06-roadmap.md` | Evidence-gated phasing |
| `07-repositioning-brief.md` | **Source of truth.** Two loops, tiers, India positioning, water, milk |

There is also a published artifact summarising the product:
`https://claude.ai/code/artifact/e446f613-68fe-4f40-b8c4-cae21cff754a`
⚠️ **It predates the repositioning** and describes the single-method V60 product.
Either regenerate it or ignore it.

---

## 13. How to build and continue

```bash
git clone https://github.com/haxsh/coffee.git && cd coffee
git checkout claude/coffee-learning-recipe-app-rtyv9s

# Domain layer only — no Xcode needed, works on Linux/macOS
swift test --package-path Packages/CoffeeKit

# Full app (macOS + Xcode 16+ required)
brew install xcodegen
xcodegen generate && open Grind.xcodeproj     # ⌘R
```

Set **Team** on both `Grind` and `GrindWidgets` targets before first run. Free Apple
ID is enough for the Simulator.

### Conventions
- Commit to `claude/coffee-learning-recipe-app-rtyv9s`. **No PR has been opened**, and
  the user has not asked for one.
- Run `xcodegen generate` after adding a top-level source folder.
- **CI is the compiler** if you have no Mac. The build step prints only `error:` lines
  and uploads the full log as an artifact on failure.
- Keep CoffeeKit free of SwiftUI/UIKit/ActivityKit.
- Swift language mode 5 (`project.yml`), iOS 18 deployment target.

### Suggested next steps, in order
1. **Get the app run once** — the highest-value hour available.
2. **OQ-1**: put `DiagnosisEngine.swift` in front of a roaster or Q-grader.
3. App icon and a real name (OQ-5).
4. Then, per `docs/06`: promote a tier 2 method, or build the milk diagnosis model
   (OQ-9), or start the A14 diary study. **Do not add more methods** until the
   Explorer's tier-3 dead-end rate says breadth is working.

### Things explicitly NOT to build
Lessons (OQ-7 first) · insights/charts (needs data density) · recipe editor · sync ·
social/feed · gear marketplace · streak gamification · a mode selector (I7) · cold
brew in the timer (I8).

---

*Authored by Claude Opus 5 in a Linux container with no Swift toolchain; every
compile and test result cited above came from GitHub Actions on a macOS runner.*
