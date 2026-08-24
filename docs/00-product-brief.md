# Product Brief — Grind

**Owner:** Harsh · **Status:** Draft v0.1 · **Last updated:** 2026-08-24

---

## 1. The idea, compressed

A home-brewing companion for iOS that teaches you coffee *through* the coffee you
actually make. It ships four things — brew recipes with a guided timer, structured
lessons, a brew journal, and a bean library — but they are one product, not four,
because they form a single loop.

---

## 2. Problem

### Problem statement

**User:** A home brewer who has bought decent gear (a grinder, a V60 or AeroPress,
a kettle) and buys specialty beans.
**Situation:** They stand at the counter each morning with 5 minutes and one shot
at the cup.
**Pain:** They follow a recipe from a video, get a cup that's sour or bitter or
just flat, and have no idea which of the eight variables caused it. So they change
three things at once, or nothing, and never converge.
**Impact:** They stall at "fine" coffee forever, blame the beans, and eventually
stop caring — or churn to the next gadget.
**Current workaround:** YouTube recipes, a notes app, a kitchen scale, and memory.
The notes are never re-read because they aren't attached to anything actionable.

> One-liner: *Home brewers can't connect what they did to how it tasted, so they
> repeat mistakes and plateau at mediocre coffee.*

### Why this is a real gap, not a crowded one

| Category | What exists | What it doesn't do |
|---|---|---|
| Recipe + timer apps | Step timers, ratio calculators, method presets | Tell you *what*, never *why*. No memory of your last cup. |
| Education | YouTube, roaster blogs, books, courses | Excellent content, entirely detached from the cup in your hand. Consumed on a couch, not at a counter. |
| Journals / logs | Structured logging, export, stats | Record-keeping with no feedback. Data in, nothing out. |
| Bean trackers | Inventory, roast dates, freshness | Isolated from brewing entirely. |

Nobody closes the loop. The loop is the product.

---

## 3. The core loop

```
        ┌──────────────────────────────────────────────┐
        │                                              │
   [1] BREW ──▶ [2] TASTE ──▶ [3] DIAGNOSE ──▶ [4] ADJUST
        ▲                          │                   │
        │                          ▼                   │
        └──────────── [5] LEARN ◀──┘◀──────────────────┘
```

1. **Brew** — a guided, step-timed pour with everything pre-computed for your dose,
   your grinder, your bean.
2. **Taste** — 20 seconds of structured input. Not a paragraph. A rating and 1–3
   outcome descriptors from a fixed vocabulary.
3. **Diagnose** — the app maps descriptors to an extraction hypothesis
   ("sour + thin → under-extracted") and names the single most likely cause.
4. **Adjust** — it proposes **one** variable change for the next brew and pre-loads
   it. One variable. Changing three is why people never converge.
5. **Learn** — the diagnosis links to a Concept Card ("what under-extraction is,
   in 60 seconds") and, if you want it, the full lesson. Learning arrives *because
   the cup was sour*, not because you opened a lessons tab.

**Everything in this spec exists to serve that loop.** If a feature doesn't feed a
step of it, it's a candidate for cutting.

### Why this makes four pillars into one product

| Pillar | Its job in the loop | Without the loop, it's… |
|---|---|---|
| Recipes + timer | Step 1 | Another timer app |
| Journal | Step 2 + memory | A notes app with fields |
| Lessons | Step 5 | A blog you don't visit |
| Bean library | Context for 1–4 | An inventory spreadsheet |

---

## 4. Users

### Primary — "Plateaued Enthusiast"
Six months to three years in. Owns a burr grinder and at least one brewer. Buys
whole bean from a local roaster. Brews 1–2 cups a day, almost always the same
method. Can taste that some cups are better but can't reliably reproduce the good
ones. Has watched Hoffmann. Wants their coffee to get measurably better and enjoys
the craft framing.

**This is who we design for.**

### Secondary — "Just Got a Grinder"
Two weeks in, gift or impulse purchase, currently intimidated. Needs the app to
make the first ten brews *not fail*, and to explain vocabulary without condescension.
We serve them with onboarding and defaults, not with a separate mode.

### Explicit non-user (v1)
Café professionals and roasters. Their needs — shot logging at volume, refractometry,
green inventory, staff training records — pull the product toward a different app.
Serving them early would ruin the counter-side simplicity the primary user needs.

---

## 5. Design context (the constraint that shapes everything)

The hero moment happens with **wet hands, in steam, in a bright kitchen, with
90 seconds of divided attention, holding a kettle in one hand.**

Non-negotiables that fall out of this:
- The brew timer must be usable **one-handed, without precision gestures**.
- It must be usable **without looking** — audio and haptic step cues, because your
  eyes are on the pour.
- It must survive **screen lock, backgrounding, and an incoming call** without
  losing the timer. (→ Live Activity + Dynamic Island, not a foreground-only timer.)
- It must work **fully offline**. No spinner is acceptable mid-pour.
- Text must be legible at arm's length in daylight glare. Dynamic Type support is
  a requirement, not a polish item.

Any design that only works held close, dry, and with full attention is wrong,
however beautiful it looks in a mockup.

---

## 6. Goals & success metrics

**North star:** *Brews logged per weekly active user.* If people aren't logging,
the loop isn't running and nothing else in the app matters.

| Goal | Metric | Target (first 90 days post-launch) |
|---|---|---|
| The loop starts | % of new users who log a brew within 24h of install | ≥ 45% |
| The loop repeats | % of users with ≥ 2 logged brews in week 1 | ≥ 30% |
| The loop is trusted | % of brews where the suggested adjustment was applied next time | ≥ 40% |
| The loop works | Median rating of brews 8–10 vs brews 1–3, same user | +0.6 stars |
| Learning is ambient, not a chore | % of lesson opens that originate from a Concept Card, not the Learn tab | ≥ 50% |
| Retention | D30 retention | ≥ 20% |

**Counter-metrics (things we must not break):**
- Median time to complete the post-brew log: **≤ 30 seconds.** If logging feels
  like data entry, the loop dies at step 2. This is the single most fragile point
  in the product.
- Guided-brew abandonment (started timer, never finished): **≤ 15%.**
- Cold start to "Start brew" tappable: **≤ 1.2s.**

**Leading indicators in the first two weeks:** onboarding completion rate, first-brew
completion rate, Concept Card open rate.

---

## 7. MVP scope — and the line

**The core bet MVP tests:** *If we hand people a diagnosis and one adjustment after
each cup, they will log the next brew — and their ratings will climb.*

That bet is testable with **one brewing method**. It is not made more testable by
six. Breadth is the most tempting and most expensive way to fail here: six methods
means six recipe sets, six diagnosis tables, six sets of illustrations, and one
untested hypothesis.

### In scope — v1

| Feature | Why it's in |
|---|---|
| **V60 pour-over only**, 3 built-in recipes (standard, forgiving, high-clarity) | Highest variable-sensitivity → best showcase for diagnosis. Widest ownership in the target segment. |
| Guided brew timer with Live Activity, audio + haptic cues | The hero. The loop can't start without it. |
| Brew setup: bean picker, dose → ratio → water, grind, temp | Pre-computation is the whole reason to use an app over a video |
| Post-brew log: rating + fixed descriptor vocabulary + optional note | Step 2. Kept brutally short by design. |
| **Diagnosis engine** — descriptor → hypothesis → one adjustment | The differentiator. Nothing ships without it. |
| Concept Cards — ~25 concepts, tappable from anywhere | The learning delivery mechanism |
| One course: *Foundations* (~8 lessons, 3–5 min each) | Enough to prove the Learn pillar; a destination for people who want depth |
| Bean library — add/edit bags, roast date + rest indicator, link to brews | Needed for diagnosis fidelity (age is a variable) and it's cheap |
| Journal — list, detail, "brew this again" | Step 2's storage; also the emotional payoff (progress made visible) |
| Grinder profile — map your grinder to a normalized coarseness scale | Without this, "grind finer" is meaningless advice |
| Onboarding — gear, goal, experience level → seeds first recipe + path | The first brew must not fail |

### Out of scope — v1

| Deferred | Why |
|---|---|
| AeroPress, espresso, French press, Chemex, cold brew, moka | Add one per release after the loop is proven. Espresso especially — different variables, different diagnosis model, needs its own spec. |
| Insights / trends dashboard | Needs data density we won't have at launch. Ships when users have 20+ brews. |
| Compare two brews side by side | Nice, but the diagnosis already does the comparing |
| Community / shared recipes | Requires moderation, accounts, and a content strategy. Whole separate initiative. |
| Bag label / barcode scanning | Delightful, not load-bearing. Manual entry is 30s. |
| Apple Watch app | Strong candidate for v1.1 — genuinely solves the wet-hands problem — but not before the phone loop works |
| CloudKit sync across devices | Local-first at launch; sync in v1.1 |
| Refractometry / TDS input | Pro-tier user, not our primary |
| Video lessons | Text + illustration first. Video is a production commitment, not a feature. |

### MVP is done when…
A new user can install, complete onboarding, brew a V60 with the guided timer,
log the result in under 30 seconds, receive a specific diagnosis and one adjustment,
tap through to a Concept Card explaining it, and start the next brew with that
adjustment already applied — **entirely offline, one-handed, without reading a
manual.**

---

## 8. What we're deliberately not doing

- **Not a social app.** No feed, no follows, no likes. The feedback loop is with
  your own past cups.
- **Not a gear store or affiliate funnel.** Recommending gear the moment we're
  also teaching corrodes the trust the teaching depends on.
- **Not gamified with streaks and badges as the primary motivator.** The motivator
  is that the coffee gets better and you can taste it. Streaks are a cheap
  substitute that we can add later if the real one doesn't hold.
- **Not comprehensive.** A glossary of 400 terms is a worse product than 25 concepts
  someone actually reads.

---

## 9. Next step

Two things before any pixels:
1. **Resolve OQ-1 and OQ-3** in `05-assumptions-and-open-questions.md` — the
   diagnosis rule table needs a real coffee expert's review, and we need to decide
   whether descriptor input is chips or sliders (it drives the 30-second target).
2. **Prototype the brew timer screen only**, and test it at an actual sink with wet
   hands and a real kettle. Not on a desk. Everything else in this spec is
   negotiable; that screen is the product.
