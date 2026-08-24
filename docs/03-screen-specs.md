# Screen-by-Screen Design Brief

29 screens. Three are specced deep because they carry the product: **S05 Guided
Brew**, **S06 Log Brew**, **S07 Next Time**. The rest are specced at the level a
designer needs to start.

**Legend:** 🟢 v1 · 🟡 v1.1 · ⚪ later

---

## Screen inventory

| # | Screen | Tab | Ship |
|---|---|---|---|
| S00 | Onboarding | — | 🟢 |
| S01 | Brew Home | Brew | 🟢 |
| S02 | Method Detail | Brew | 🟢 |
| S03 | Recipe Detail | Brew | 🟢 |
| S04 | Brew Setup | Brew | 🟢 |
| S05 | **Guided Brew** | modal | 🟢 |
| S06 | **Log Brew** | modal | 🟢 |
| S07 | **Next Time** | modal | 🟢 |
| S08 | Ratio Calculator | Brew | 🟢 |
| S09 | Recipe Editor | Brew | 🟡 |
| S10 | Learn Home | Learn | 🟢 |
| S11 | Course Detail | Learn | 🟢 |
| S12 | Lesson Reader | Learn | 🟢 |
| S13 | Quiz / Check | Learn | 🟢 |
| S14 | Concept Card (sheet) | global | 🟢 |
| S15 | Concept Library | Learn | 🟢 |
| S16 | Flavour Trainer | Learn | ⚪ |
| S17 | Beans List | Beans | 🟢 |
| S18 | Bean Detail | Beans | 🟢 |
| S19 | Add / Edit Bean | Beans | 🟢 |
| S20 | Journal List | Journal | 🟢 |
| S21 | Brew Detail | Journal | 🟢 |
| S22 | Insights | Journal | 🟡 |
| S23 | Compare Brews | Journal | ⚪ |
| S24 | Profile | global | 🟢 |
| S25 | My Gear / Grinder Setup | Profile | 🟢 |
| S26 | Global Search | global | 🟡 |
| S27 | Paywall | global | 🟢 |
| S28 | Live Activity / Dynamic Island | system | 🟢 |

---

# The three that matter

## S05 — Guided Brew 🟢

**The hero screen. If this isn't right, nothing else counts.**

### Context
Standing at a counter. Kettle in the right hand, phone flat on the counter or
propped. Steam. Wet hands. Eyes on the pour, not the screen. 3–4 minutes.

### Job
Tell me what to do *right now*, tell me what's coming next, and never make me
touch the screen unless I choose to.

### Layout — top to bottom
1. **Elapsed time.** Huge. Rounded mono digits, ~90pt, legible from a metre away
   at a glance. This is the anchor.
2. **Water target — the second-biggest thing on screen.** `247 g / 350 g` with a
   filling progress ring or bar. **Cumulative**, matching what the scale reads.
   Never per-pour; never make the user add.
3. **Current step.** One short imperative sentence: *"Pour in slow circles to 200 g."*
   Not a paragraph. Any technical noun in it is underlined → S14.
4. **Step progress.** Small dot/segment row — where you are in the brew, how much
   is left. Answers "am I nearly done" without reading.
5. **Next step, preview.** Dimmed, one line: *"Next: wait until 1:45."* Removes
   the surprise; lets the user pre-position the kettle.
6. **Controls.** Two, both huge (≥ 88pt targets, thumb-reachable, bottom third):
   **Pause/Resume** and **Next step**. That's it.
7. Small `×` top-left (confirm before discarding); `+15s` secondary.

### Behaviour
- **Auto-advancing** by default; a step you finish early is skipped with **Next**.
  Never *blocks* on the user pressing something — the timer is the truth.
- **Audio cues** — a distinct tone at each step change, plus a soft tick in the
  last 3 seconds of a timed step. Audible over a grinder and a kettle. Ducks other
  audio (podcasts) rather than stopping it.
- **Haptics** — `.notification` on step change, light tick on countdown. The user
  should be able to run a whole brew from sound and feel alone.
- **Screen stays awake** for the entire brew. Non-negotiable.
- **Live Activity + Dynamic Island** from second one. This is how the brew survives
  lock, backgrounding, and the user opening Messages. Island shows elapsed +
  current water target; expanded shows the step and a Next control (S28).
- **Concept Card mid-brew** — opens as a sheet over a still-running timer, which
  stays visible in the Island. Dismisses back to exactly where you were.
- **Ends** by auto-advancing into S06. No "finish" button to remember to press —
  forgetting to press it means a lost brew and a broken loop.

### Rejected
- ❌ Swipe-to-advance — wet fingers, no. Taps only, big ones.
- ❌ Animated pour visualisation as the primary display — pretty in a mockup,
  useless when you're looking at the actual coffee.
- ❌ A single "tap anywhere to advance" surface — too easy to trigger by accident
  when setting the phone down.
- ❌ Any modal alert during the brew.

### States
Paused (timer dims, everything else holds) · Overrun (a step's time exceeded —
turns amber, does not nag) · Backgrounded (Live Activity) · Force-quit and
relaunched (recovery prompt, see IA edge cases) · VoiceOver (each step change
announced with `.assertive` priority; time is a live region polled, not spammed).

### Accessibility
Dynamic Type to AX3 on every label including the timer (layout reflows, never
truncates) · high-contrast palette validated in direct sunlight · all information
conveyed by colour also conveyed by text or shape · full VoiceOver labels on both
controls · Reduce Motion removes the ring animation but keeps the numeric target.

---

## S06 — Log Brew 🟢

**The most fragile screen in the product.** Everything the app does downstream
depends on this being completed. It is competing with "I want to drink my coffee."

### Hard constraint
**Median completion under 30 seconds.** Design decisions are subordinate to this
number. When in doubt, cut a field.

### Job
Capture enough signal to diagnose, in less time than it takes the cup to cool.

### Layout
Appears automatically when the timer ends, as a sheet you can drink through.

1. **"How was it?"** — 5 taps of a star or a 5-segment control. One tap.
2. **Two axis pickers**, the entire diagnostic payload:
   - *"Taste"*: `Sour ← ● → Bitter` with a labelled centre `Balanced`
   - *"Body"*: `Thin ← ● → Heavy` with centre `Just right`
   Presented as **5-position segmented controls, not sliders.** Sliders demand
   precision with wet hands and imply false granularity; segments are one tap each.
   Both default to centre, so the fast path is: rate → done.
3. **Descriptors (optional).** A single row of chips, horizontally scrolling:
   *sweet · juicy · sharp · drying · flat · muddy · tea-like · syrupy · papery · ashy*.
   Max 3. Each chip long-presses to a Concept Card.
4. **Actuals, collapsed.** One summary line: *"18 g · 1:16 · 3:24 · 16 clicks"* with
   an edit affordance. Pre-filled from the timer and setup. Most users never open it.
5. **Photo + note**, both optional, both last, both one tap to skip.
6. **[Save & see what to change]** — primary, always enabled.

### Rules
- **Nothing is required except the rating.** A brew logged with only a rating is a
  valid brew; the diagnosis just returns rule 11.
- **Never block on the bean.** If no bean was selected, offer *"Save this coffee?"*
  once, inline, dismissible forever.
- **Dismissing is allowed** and saves what's been entered. A partial log beats a
  lost one.
- **No free-text field above the fold.** A text box is a wall; it makes the screen
  read as homework.

### Rejected
- ❌ SCA cupping form (fragrance/aroma/flavour/aftertaste/acidity/body/balance,
  each 6–10). Correct for professionals, fatal for the 30-second target.
- ❌ A flavour wheel as the primary input. Beautiful, slow, and requires vocabulary
  the beginner doesn't have yet. It belongs in S16 as *training*, and can graduate
  to an optional input later.
- ❌ "Log later" — the taste memory is gone in ten minutes, and so is the loop.

---

## S07 — Next Time 🟢

**The payoff. This is the screen the whole product exists to show.**

### Job
Tell me one thing to change, tell me why in a sentence, and make doing it trivially
easy tomorrow.

### Layout
1. **The verdict**, plain language, no jargon: *"Under-extracted — it came out
   sour and a bit thin."*
2. **The one change**, as the visual centre of the screen, in the user's own units:

   > ### Grind finer
   > **18 → 16 clicks** on your Baratza Encore

   One thing. Never a list. If a second thing matters, it waits for the next brew.
3. **Why**, two sentences max, ending in an underlined concept → S14:
   *"Coarser grounds give water less surface to work on, so it pulls out the
   bright, acidic compounds and not the sweet ones. That's __under-extraction__."*
4. **[Save this for next time]** — primary. Writes the adjustment so S04 pre-fills
   it and shows *"Applying your adjustment: 16 clicks."*
5. **[Learn why in 3 min]** — secondary, opens the linked lesson.
6. **[Not this time]** — tertiary, dismisses without applying. Always available; a
   recommendation you can't refuse isn't advice.

### The moment that matters — closing the loop
When a brew **applied a prior adjustment** and rated higher, S07 leads with it
before anything else:

> **That worked.** ⭐️3 → ⭐️4 after grinding finer. Same grind next time.

This is the payoff for the entire product. It should be the most celebratory
moment in the app — and it is *earned*, not confetti-for-opening-the-app. It's also
the honest one: when it *didn't* work, say that too, and suggest going back.

### Rejected
- ❌ Showing multiple ranked suggestions. Kills the loop's interpretability and
  every user picks the easiest one.
- ❌ Hedging language ("you might want to consider possibly…"). Commit. Being
  confidently wrong once and correcting is better than being uselessly vague every
  time — that's how a coach earns trust.

---

# The rest

## S00 — Onboarding 🟢
Four screens, skippable at any point, before the tab bar exists.
1. *What are you brewing with?* — method picker (v1: V60 pre-selected, others shown
   with "coming soon" so the roadmap is visible).
2. *What do you grind with?* — searchable grinder list + "I don't know / pre-ground".
   Feeds S25 calibration.
3. *Where are you at?* — Just started / Been at it a while / Pretty dialled in.
   Sets recipe defaults (forgiving vs high-clarity) and the starting course.
4. *Let's brew one.* → straight into S04 with everything pre-filled.
**Rule:** skipping produces working defaults, never a broken state. **Success
criterion: the first brew must not fail.**

## S01 — Brew Home 🟢
- **"Brew again"** card at the top: last brew's method + bean + any pending
  adjustment, one tap to S04 (or straight to S05 if nothing changed). The single
  most-used control in the app.
- Method grid (locked methods visible with a badge → S27).
- *Your recipes* / *Recent*.
- Ratio calculator entry.
- Empty state: a single large *Start your first brew* with a 4-minute promise.

## S02 — Method Detail 🟢
What it is, what it's good at, gear needed, difficulty, typical time. Recipe list
segmented `Built-in | Mine`. Linked concepts. A short *how it works* explainer that
is a lesson entry point, not a wall of text.

## S03 — Recipe Detail 🟢
Params at a glance (dose · ratio · grind · temp · total time). Step timeline as a
readable list with cumulative water. Concept links inline. **[Start brew]** pinned
bottom. Overflow: duplicate, edit, share.

## S04 — Brew Setup 🟢
The pre-flight. Every field pre-filled; a user who changes nothing can hit Start.
- Bean picker (optional, defaults to last used, shows rest days inline).
- **Dose** stepper in grams — the only number people actually change. Water
  recomputes live and visibly.
- Ratio control (1:15 / 1:16 / 1:17 + custom).
- Grind, shown in **your** grinder's units, with the pending adjustment highlighted:
  *"16 clicks — applying yesterday's adjustment"*.
- Temp.
- **[Start brew]**, full width, bottom, thumb-height.

## S08 — Ratio Calculator 🟢
Dose ↔ water ↔ ratio; change any two, the third solves. Unit toggle. *"Brew this"*
converts it into a freestyle brew. A genuinely useful standalone utility that also
teaches the relationship by making it manipulable.

## S09 — Recipe Editor 🟡
Duplicate-and-edit only in v1.1 (no from-scratch). Steps are add/reorder/delete with
inline validation: cumulative water must be non-decreasing, times must increase,
final water must equal dose × ratio (or flag the mismatch and offer to fix the ratio).

## S10 — Learn Home 🟢
- **Continue** card — the lesson in progress, resumed at the right block.
- Course cards with progress rings.
- *Concepts you've met* — concepts surfaced through diagnoses, which is the ambient
  path made visible and satisfying.
- Concept Library entry.

## S11 — Course Detail 🟢
Blurb, level, total time, lesson list with completion state and per-lesson minutes.
Lessons are **not gated** in sequence — locking lesson 4 until 3 is done punishes the
person who arrived from a Concept Card, which is our primary intended path.

## S12 — Lesson Reader 🟢
Typographically serious — this is reading, on a couch, not at a counter, so the
constraints of S05 don't apply and shouldn't be imported.
- Typed blocks, generous measure (~65 chars), real illustrations over stock photos.
- Inline concept links, underlined, → S14.
- Progress preserved per-block.
- Ends with: quiz (if any) → **Try it** (deep link to a matching Brew Setup) → next
  lesson. **The Try It is what makes Learn feed the loop rather than being a
  dead end.**

## S13 — Quiz 🟢
2–4 questions. Immediate feedback with the *explanation*, not just right/wrong —
a wrong answer is the best teaching moment available. No score kept, no failing, no
retake gating. Purpose is retention, not assessment.

## S14 — Concept Card 🟢 (sheet, global)
**The most important navigation object in the app.**
- Medium detent, expandable to large.
- Term · one-line definition · ~60-second explainer, one illustration where it
  earns its place · related concepts · **[Learn more]** → full lesson.
- Openable from anywhere including mid-brew, over a running timer.
- Fully offline, instant, no loading state ever.

## S15 — Concept Library 🟢
A–Z, searchable, filterable by "met" vs "unmet". ~25 concepts at launch. Deliberately
small — a 400-term glossary is a worse product than 25 someone reads.

## S16 — Flavour Trainer ⚪
Interactive wheel, guided tasting exercises, "describe this cup" drills. Later — it's
the right long-term answer to the vocabulary problem, and the wrong first move.

## S17 — Beans List 🟢
Active bags sorted by roast date, each with a **freshness indicator** (resting ·
peak · fading · stale) and estimated remaining. Archived section collapsed below.
Empty: *"Add the bag on your counter."* → S19.

## S18 — Bean Detail 🟢
Bag facts, roaster's notes, rest-day timeline, **your** brews with this bean, your
best-rated brew with it and its exact parameters (*"your best cup from this bag"* —
a genuinely delightful, cheap feature), remaining estimate. **[Brew this]**.

## S19 — Add / Edit Bean 🟢
Name and roast date are the only two that matter; everything else is optional and
below the fold. Roast date defaults to today with a friendly nudge. Barcode/label
scanning deferred — flagged as the highest-value delight feature for v1.1.

## S20 — Journal List 🟢
Reverse-chronological, grouped by day. Each row: method · bean · rating · the one
adjustment applied, if any. Filter by method / bean / rating. Search. Swipe to
duplicate-and-brew. Empty: *"Your brews will land here."*

## S21 — Brew Detail 🟢
The full record: planned vs actual side by side (differences highlighted — this is
where users learn they don't execute what they plan), taste record, the diagnosis
that was given, whether it was applied, and what the *next* brew rated. **[Brew this
again]**. This screen is the journal's real payoff.

## S22 — Insights 🟡
Ships when users have ~20 brews, not at launch — an empty chart is worse than no
chart. Rating over time · best ratio per method · best-performing beans · applied-
adjustment success rate. Every chart must answer a question a user actually asks.

## S23 — Compare Brews ⚪
Two brews, variables diffed, ratings side by side. Deferred: the diagnosis already
does the comparison the user needs.

## S24 — Profile 🟢
Units (g/oz, °C/°F), appearance, **My Gear** (a collection, not a settings list),
notifications, **Export journal (CSV + JSON, offline)**, subscription, about.

## S25 — My Gear / Grinder Setup 🟢
Add grinder → pick from a known list or "other" → **calibrate by anchoring**:
*"What setting do you use for pour-over?"* → that becomes normalised 50. Everything
else is derived. Two taps, no measuring, and it's what makes "grind finer" mean
something concrete.

## S26 — Global Search 🟡
One field, results grouped and labelled by type. Offline, local.

## S27 — Paywall 🟢
Triggered by tapping a locked item — always contextual, never a wall on launch.
Names the specific thing you just tried to open. Free tier must be genuinely usable:
V60, three recipes, unlimited journal, first course. **Do not cap the journal.**
Holding a user's own data hostage is the fastest way to lose trust in a product
whose entire premise is trust.

## S28 — Live Activity / Dynamic Island 🟢
Compact: elapsed + current water target. Expanded: step text, progress, Next, Pause.
Lock screen: full step detail. Copy is ~40 characters and gets seen more than most
screens — write it early, deliberately.

---

## Cross-cutting requirements

**Empty states.** Every list has one, written before the populated design. Each does
exactly one job and offers exactly one action.

**Error states.** The app is offline-first; there are very few. Where they exist
(export failed, remote content update failed) they are non-blocking and never
interrupt a brew.

**Accessibility (all screens, v1 requirement not polish):** Dynamic Type to AX3,
VoiceOver labels and ordering, no colour-only information, ≥44pt targets (≥88pt on
S05), Reduce Motion honoured, contrast validated for bright-kitchen use.

**Motion.** Restrained everywhere except two moments that are allowed to be
expressive: the brew completing, and *"That worked"* on S07. Earned celebration
only.

**Haptics.** Reserved for physical-world sync — step changes, countdowns, timer
end. Never for navigation. Overuse burns the channel we depend on in S05.
