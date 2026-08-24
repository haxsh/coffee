# Content Model & the Diagnosis Engine

> Updated by [`07-repositioning-brief.md`](07-repositioning-brief.md): `supportTier`
> on Method, `waterSource` and `withMilk` on Brew, and two new gating rules near the
> top of the diagnosis order.

The systems-analyst layer. This is the part that, if got wrong, costs a migration
rather than a redesign.

---

## 1. Object map

```
Grinder ──┐
          │
Method ───┼──▶ Recipe ──▶ Brew ◀── Bean
   │      │                 │
   │      └── (params)      ├──▶ TasteRecord ──▶ Diagnosis ──▶ Adjustment
   │                        │                        │
   └──▶ DiagnosisRuleSet ───┘                        ▼
                                                 Concept ◀── Lesson ◀── Course
```

**Concept is referenced by almost everything** — recipe steps, diagnoses, tasting
descriptors, lessons, and gear. It is the spine.

---

## 2. Entities

### Method
The brewing device/technique. Ships with the app; users don't create these.

| Field | Type | Notes |
|---|---|---|
| `id` | string | `v60`, `aeropress`, `espresso` … |
| `name`, `blurb`, `iconAsset` | | |
| `supportTier` | `.full` / `.guided` / `.reference` | **The field that makes breadth affordable.** Decides whether a method gets a rule table, a timer, or a paragraph. Gates the UI *and* the engine — it is what stops a described method from implying a diagnosed one. |
| `takesMilk` | Bool | Whether milk is a normal part of this drink. Scopes the milk flag to moka, South Indian filter and espresso rather than asking about it on a V60. |
| `paramSchema` | `[ParamDef]` | **The critical field.** Declares which variables this method has, their units, ranges and defaults. Pour-over has dose/ratio/grind/temp/bloom/pours; espresso has dose/yield/time/pressure/basket. Empty for `.reference` methods — there is no brew to parameterise. |
| `expectedTotalTime` | range | Used for drawdown-time diagnosis |
| `diagnosisRuleSetId` | ref | Each method reasons differently |
| `conceptIds` | `[ref]` | Concepts a user should know for this method |

> ⚠️ **`paramSchema` must exist in v1 even though v1 ships one method.** Hard-coding
> pour-over columns onto `Brew` is the single most expensive shortcut available here.
> See IA Risk #1. This has now been vindicated rather than merely argued: a dozen
> methods at three tiers landed on top of it without a migration.

### What each tier may claim

`supportTier` is an honesty constraint expressed as a type. It is enforced in the
engine, not only in the UI — a `.guided` method physically cannot produce a
per-symptom diagnosis, because the engine will not run a rule table for it.

| Tier | Timer | Log | Engine output | Needs |
|---|---|---|---|---|
| `.full` | ✅ | ✅ | Hypothesis + **one adjustment**, in the user's own units | Its own rule table, expert-reviewed |
| `.guided` | ✅ | ✅ | **Method-level advice only** — what usually goes wrong with this brewer | Recipes and timings |
| `.reference` | ❌ | ❌ | Nothing. There is no brew to reason about. | An overview card |

**Promotion is a content decision, not a code change.** Moving a method up a tier
means authoring a rule table and having it reviewed; the model, the UI and the engine
already handle all three states.

### Recipe
A parameterised plan for a Method.

| Field | Type | Notes |
|---|---|---|
| `id`, `methodId`, `name`, `author` | | `author` = `builtIn` \| `user` (\| `community`, later) |
| `defaultDose` | grams | |
| `ratio` | 1:N | Water is *derived*, never stored as a primary. Store the ratio; compute water from the dose the user actually weighed. |
| `grindTarget` | normalised 0–100 | Not "18 clicks" — see Grinder |
| `waterTempC` | | |
| `steps` | `[Step]` | ordered |
| `notes`, `conceptIds` | | |
| `isLocked` | bool | Free/Pro |

**Step**: `{ atSeconds, durationSeconds, kind: bloom|pour|swirl|wait|press|drawdown, targetWaterG (cumulative), instruction, conceptId? }`

Steps carry **cumulative** water targets, not per-pour amounts. Scales are cumulative;
asking a user to do mental arithmetic mid-pour is a design failure.

### Brew
One execution. **The irreplaceable object** — everything else can be re-downloaded.

| Field | Type | Notes |
|---|---|---|
| `id`, `startedAt`, `methodId` | | |
| `recipeId` | ref, nullable | Null = freestyle brew |
| `beanId` | ref, nullable | **Nullable by design.** Never block a brew on inventory. |
| `params` | `[key: value]` | Validated against `Method.paramSchema`. Stores *actuals*, not the recipe's plan. |
| `plannedParams` | `[key: value]` | Snapshot of the recipe at brew time, so later recipe edits don't rewrite history |
| `actualTotalTimeS` | int | From the timer |
| `grinderId`, `grinderSetting` | | Raw setting as the user knows it, plus normalised value |
| `beanRestDays` | int, derived at brew time | Frozen, because roast-date age changes daily |
| `waterSource` | `.ro` / `.tap` / `.bottled` / `.roTapMix` / `.unknown` | Frozen at brew time from the user's profile — they may change their water later, and history must not be rewritten. Gates the RO rule. |
| `withMilk` | Bool | Only set on methods where `takesMilk` is true. **Gates every acidity-driven rule** — see below. |
| `taste` | TasteRecord? | Null until logged |
| `diagnosisId` | ref? | |
| `appliedAdjustmentFrom` | ref to prior Brew? | **The loop metric lives here.** |
| `photoAssetId`, `note` | | |

### TasteRecord
Deliberately tiny. Every field added here costs seconds against the 30-second
counter-metric.

| Field | Type | Notes |
|---|---|---|
| `rating` | 1–5 | |
| `extractionAxis` | −2 … +2 | −2 very sour/sharp → 0 balanced → +2 bitter/drying |
| `strengthAxis` | −2 … +2 | −2 thin/watery → 0 right → +2 heavy/muddy |
| `descriptors` | `[DescriptorId]` | Optional. Fixed vocabulary, max 3. |
| `freeNote` | string? | Optional, always last, never required |

### Bean

| Field | Notes |
|---|---|
| `name`, `roaster`, `origin`, `region`, `producer`, `varietal`, `process`, `altitude` | All optional except `name` |
| `roastDate` | **The one field we push hard for** — it drives the rest indicator and feeds diagnosis |
| `roastLevel` | light / medium / dark |
| `bagWeightG`, `pricePaid`, `purchasedAt` | |
| `roasterNotes` | as printed on the bag |
| `isArchived` | derived-suggested when estimated remaining ≈ 0 |

**Derived:** `restDays`, `freshnessState` (resting / peak / fading / stale),
`estimatedRemainingG` (bag weight − sum of doses brewed).

### Concept
The learning atom.

| Field | Notes |
|---|---|
| `id`, `term`, `aliases` | Aliases power inline auto-linking and search |
| `shortDef` | ≤ 200 chars — the one-line answer |
| `card` | ~60 seconds of reading. Illustration optional. |
| `lessonId` | ref? — "go deeper" |
| `relatedConceptIds` | |

**One record, three presentations:** inline underline → tap → sheet (shortDef +
card + go deeper). Also browsable A–Z in the Concept Library. Never duplicated,
never reworded per location.

### Course / Lesson

Course: `{ id, title, blurb, level, lessonIds[], estMinutes }`
Lesson: `{ id, title, estMinutes, blocks[], conceptIds[], quiz?, tryItRecipeId? }`

`blocks` are typed (`prose | illustration | callout | comparison | conceptRef |
tryIt`) rather than raw HTML, so the reader can be restyled, made accessible, and
support Dynamic Type without re-authoring content.

`tryItRecipeId` is what makes Learn feed the loop: a lesson about bloom ends with
*"Try it — brew this with a 45s bloom"* and deep-links into Brew Setup.

### Grinder
Why this exists: **"grind one step finer" is meaningless without a mapping.**

| Field | Notes |
|---|---|
| `brand`, `model`, `burrType` | |
| `settingType` | clicks / numbered dial / stepless |
| `settingRange` | e.g. 0–40 clicks |
| `calibration` | user-anchored: "where do you grind for V60?" → maps that setting to normalised 50 |
| `stepSizeMicrons` | estimated per model, for known grinders |

Recipes store a **normalised 0–100 coarseness**; the app translates to *your*
grinder's units. A recipe says "medium-fine"; your screen says **"18 clicks"**.

### Descriptor
Fixed vocabulary for taste input. ~14 terms, each with an axis contribution and a
linked Concept. Never free-text-first — free text is unusable for diagnosis, and
a blank box is intimidating to the exact beginner we're serving.

---

## 3. The Diagnosis Engine

### Principle

The industry-standard model for filter coffee separates two independent things
that beginners constantly conflate:

- **Extraction** — *how much* you pulled out of the grounds. Too little → sour,
  salty, thin finish. Too much → bitter, drying, harsh.
- **Strength (concentration)** — how much coffee is dissolved in the water. Too
  little → watery. Too much → heavy, muddy.

You can have a strong, under-extracted cup (sour and intense) or a weak,
over-extracted one (bitter and thin). **Teaching this distinction is arguably the
single highest-value thing the app does.**

Two questions in the log screen produce two axes. Two axes produce a quadrant.
The quadrant produces exactly one adjustment.

### The grid

```
              STRENGTH
              ▲
     heavy    │  Sour & heavy          │  Bitter & heavy
     +2       │  → grind finer         │  → more water (weaker ratio)
              │                        │
    ──────────┼────────────────────────┼──────────────▶ EXTRACTION
              │        BALANCED        │        bitter/drying +2
     thin     │  Sour & thin           │  Bitter & thin
     −2       │  → grind finer         │  → grind coarser
              │  (both axes move)      │  + less water
       sour/sharp −2
```

### Rule table (V60 / pour-over, v1)

Two gates run *before* the table, and both can stop it entirely:

| Gate | Effect |
|---|---|
| **Tier** | If `method.supportTier != .full` the table does not run at all. A `.guided` method returns method-level advice; a `.reference` method has no brew to reason about. This is enforced in the engine rather than the UI, so a tier can never be bypassed by a screen. |
| **Milk** | If `withMilk` is true, every rule that reads the **extraction axis** (rules 4–7) is suppressed. Milk flattens acidity and masks sour-versus-bitter entirely; running those rules anyway would confidently misdiagnose every milk drink. Strength and bean rules still apply. |

Then, evaluated top to bottom; **first match wins, and only one adjustment is ever
surfaced.**

| # | Condition | Hypothesis | The one change | Concept shown |
|---|---|---|---|---|
| 1 | `freshness == .resting` **and** cup is not balanced | Beans are still degassing; CO₂ is disrupting extraction and results will be erratic | *No change — this bag needs 2–3 more days. Brew the same way and compare.* | Degassing |
| 2 | `freshness == .stale` **and** descriptor ∈ {flat, papery} | Stale coffee. No brew variable recovers this. | *Nothing to fix — this bag is past it. Note it and move on.* | Freshness & staling |
| 3 | `waterSource == .ro` **and** cup is sour or thin **and** water advice not yet seen | Water too pure to extract properly — this is not a grind problem | *No grind change. **Blend your RO with tap, about 70:30**, and brew it exactly the same way.* | Water for coffee |
| 4 | `extraction ≤ −1` **and** `waterTempC < 88` | Temperature-driven under-extraction | **Hotter water** — before touching the grind | Water temperature |
| 5 | `extraction ≤ −1` | Under-extracted | **Grind one step finer.** (shows *your* grinder's units) | Under-extraction |
| 6 | `extraction ≥ +1` **and** `actualTotalTime > expected.max + 15s` | Over-extracted via contact time | **Grind one step coarser** — your drawdown ran long | Drawdown |
| 7 | `extraction ≥ +1` | Over-extracted | **Grind one step coarser.** | Over-extraction |
| 8 | `extraction == 0` **and** `strength ≤ −1` | Extraction is right, cup is dilute | **Same grind — use less water.** Ratio 1:16 → 1:15. | Brew ratio |
| 9 | `extraction == 0` **and** `strength ≥ +1` | Extraction is right, cup is too concentrated | **Same grind — use more water.** 1:15 → 1:16. | Brew ratio |
| 10 | `balanced` **and** `rating ≥ 4` | It worked | *Nothing to change. This is your recipe now.* → offer **Save as my recipe** | — |
| 11 | `balanced` **and** `rating ≤ 3` | Technically sound, not enjoyable — a bean or water problem, not a brew problem | *Your brew is dialled in. Try a different coffee, or check your water.* | Water for coffee |
| 12 | Fallback | Insufficient signal | *Brew it the same way once more so we have something to compare.* | — |

> **Ordering correction (found during implementation).** The temperature rule was
> originally listed last. That made it unreachable — rule 5 catches every
> `extraction ≤ −1` first — and it gave the wrong advice besides: water well below
> range swamps grind, so it has to be fixed first. It is now rule 4, and
> `testCoolWaterIsCheckedBeforeGrind` in `DiagnosisEngineTests` guards against the
> ordering regressing.

### Rules the engine follows

1. **Never suggest more than one change.** Two variables means an uninterpretable
   result and a user who never converges. This is the entire point.
2. **Fix the dominant cause first, then extraction, then strength.** Grind moves both axes; ratio moves mainly
   strength. Chasing strength first means re-doing it after the grind changes.
3. **The water rule fires once, not forever.** Rule 3 is gated on *"water advice not
   yet seen"* — without that gate, a user on RO water who is also genuinely grinding
   too coarse would be told "it's your water" after every single brew, and the
   mastery loop would never advance past its first turn. It is a **gate**, not a
   verdict: it interrupts once, teaches the fix, and then steps out of the way so
   grind and ratio advice can resume. The user acknowledging it, or changing their
   recorded water source, clears it.
4. **Rule out the bean before blaming the brewer.** Rules 1, 2 and 9 exist so the
   app doesn't send someone chasing grind settings on coffee that was never going
   to be good. Trust is built by saying "this isn't your fault."
5. **Say the change in the user's units.** Never "grind finer" — always
   *"Grind finer: 18 → 16 clicks on your Encore."*
6. **Show the reasoning, one tap away.** Every suggestion carries a Concept Card.
   The suggestion is the answer; the card is the education. Both, always.
7. **Close the loop visibly.** When the next brew applies the adjustment and rates
   higher, say so: *"That worked — up half a star. Keep this grind."* This is the
   moment the product proves itself.

### Milk does not suppress a rule — it removes an axis

`07` §5 specifies milk as *"suppress acidity-driven rules and weight body/strength
instead."* Implementing that literally exposes a problem the brief doesn't name.

The log screen asks two questions: an **extraction axis** (sour ↔ bitter) and a
**strength axis** (thin ↔ heavy). With milk in the cup the first one is not merely
less useful — **it is unanswerable.** Milk fat and protein bind to exactly the
compounds that read as acidity and bitterness. A user tasting a milk coffee cannot
reliably place it on sour ↔ bitter, so suppressing the rules downstream still leaves
us asking a question, taking the tap, and discarding the answer.

**The resolution is to swap the axis rather than ignore it.** When `withMilk` is set,
the extraction axis is replaced — same position on screen, same one tap, same 30
second budget — by an axis the user *can* answer for a milk drink:

| | Black | With milk |
|---|---|---|
| Axis 1 | Sour ↔ **Balanced** ↔ Bitter | Harsh / burnt ↔ **Smooth** ↔ Flat / dull |
| Axis 2 | Thin ↔ Just right ↔ Heavy | *(unchanged)* |

Axis 1's milk variant maps to over-roast and over-extraction at one end and
under-strength at the other — a coarser signal than the black-coffee axis, but a real
one, and honestly coarser rather than falsely precise.

**This is also why a milk-first method cannot currently be Tier 1.** Promoting South
Indian filter or moka to full diagnosis needs a second *diagnosis model* for the
milk axis pair, not just a second rule table. That is a materially bigger piece of
work than the tier table implies, and it is the substantive answer to `07`'s open
question about filter coffee's tier. See `05`, A16.

### What the engine does not do in v1
No confidence scores shown to users, no multi-brew regression, no ML. A transparent
rule table that a coffee professional can read, argue with, and correct is worth
more at this stage than a model nobody can debug — and it's reviewable before
launch, which a model isn't.

> **⚠️ This table is a designer's draft and must be reviewed by a Q-grader or
> experienced roaster before build.** See OQ-1. The structure is sound; the
> thresholds are guesses.

---

## 4. Derived values (computed, never stored)

| Value | Formula |
|---|---|
| Water for a brew | `actualDose × ratio` — recomputed live as the user adjusts dose |
| Rest days | `today − roastDate` |
| Freshness state | `<4 resting · 4–14 peak · 15–30 fading · >30 stale` (light roasts skew later; see OQ-4) |
| Bag remaining | `bagWeight − Σ(doses of brews with this bean)` |
| Course progress | completed lessons / total |
| Rating trend | rolling mean of last 5 brews vs the 5 before |
| **Methods tried** | `Set(brews.map(\.methodID))` — the exploration loop's progress object. **Derived, never stored.** A stored copy could disagree with the journal after a deleted brew, and *"it says I tried Chemex and I never did"* is a trust bug in the one surface built to feel like a record of your own doing. |
| **Handoff progress** | Highest count of logged brews on any single method — the user-facing shadow of the north star |

---

## 5. Persistence & sync

- **Local-first, offline-always.** A single Codable JSON document on device, in
  the shared App Group container. No network call is ever on the critical path
  of a brew.
  *Changed during implementation from SwiftData.* A journal is small, v1 has no
  sync, export is a hard requirement, and the widgets need to read the same data
  from a second process. A document gives atomic writes, a trivial export path
  and a pre-migration backup for free, with no store contention. SwiftData plus
  CloudKit is the right answer when sync lands in v1.1 — it is not the right
  answer for shipping the loop.
- **Content bundle** (methods, recipes, lessons, concepts, rule sets) ships in the
  app and is remotely updatable, additively. Update failure is silent; the bundled
  version always works.
- **Sync deferred to v1.1** (CloudKit private database — no server, no accounts,
  no user data leaving the user's own iCloud).
- **Export is a v1 requirement, not a nice-to-have.** CSV + JSON of the full
  journal, offline, from Profile. Users trust a journal they can get out of.

---

## 6. Vocabulary lock

Use these words and only these words, in code, copy, and design files:

**Brew** (never session, log, entry, cup) · **Bean** (never coffee, bag, roast) ·
**Recipe** (never preset, profile) · **Method** (never brewer, device) ·
**Concept** (never term, tip, card) · **Step** (never stage, phase) ·
**Grind setting** (never grind size, when referring to the user's dial).
