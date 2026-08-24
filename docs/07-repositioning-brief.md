# Repositioning Brief — India, Multi-Method, Two Loops

**Owner:** Harsh · **Status:** Source of truth, supersedes conflicting sections of `00`–`06` · **Date:** 2026-08-25

This document overrides earlier docs where they conflict. Tags: `[STATED]` = Harsh's
decision. `[INFERRED]` = filled in on his behalf; confirm before it gets expensive.

---

## 1. What changed, and why it matters

`00-product-brief.md` bets on **mastery of one method**: V60 only, converge, ratings
climb. That is no longer the product.

**The product is now guided exploration across many brewing methods, for the Indian
metro market.** `[STATED]`

This is a repositioning, not an addition. Exploration and mastery pull in opposite
directions — a user hopping between methods never accumulates the repetitions on a
single method that the diagnosis engine needs to converge.

**Resolution: two loops, sequenced.** `[INFERRED]`

| | Exploration loop | Mastery loop |
|---|---|---|
| **Job** | "Show me what's out there, help me try it" | "Help me get good at the one I picked" |
| **Serves** | Acquisition, first 30 days | Retention, month 2 onward |
| **Cycle** | discover → try → compare → prefer | brew → taste → diagnose → adjust |
| **Needs** | Breadth, overviews, low-friction first attempts | Depth, rule tables, repetition |

**The app's central job is escorting a user from the first loop to the second.**
Try six methods, find yours, then get good at it. Everything below serves that.

**North star changes.** Old: brews logged per WAU. New: **% of users who reach 5
logged brews on a single method within 30 days.** `[INFERRED]` That single number
measures whether exploration is converting to mastery — which is the whole bet.
Keep brews-per-WAU as a secondary.

---

## 2. Method support tiers — the key architectural change

Breadth is only affordable if methods are not all supported equally. Every method
gets an entry; not every method gets a rule table.

Add `supportTier` to `BrewMethod` in `Packages/CoffeeKit/Sources/CoffeeKit/Models/BrewMethod.swift`.
`paramSchema` is already method-scoped, so the model absorbs this cleanly.

| Tier | User gets | Build cost |
|---|---|---|
| **1 — Full** | Recipes, guided timer, log, **full diagnosis + one adjustment**, concept links | High — needs its own rule table and expert review |
| **2 — Guided** | Recipes, guided timer, log, **generic method-level advice** (not per-symptom diagnosis), concept links | Medium — recipes and timings only |
| **3 — Reference** | Overview card: what it is, what it tastes like, what you need, roughly what it costs, whether to try it. **No timer, no logging.** | Low — content only |

**Tier 3 is what "support as many brewers as possible" actually means.** It costs a
paragraph each and delivers the browse-and-discover experience without pretending to
expertise the app doesn't have.

**Promotion rule:** a method moves up a tier when usage justifies the authoring cost,
not before. Instrument this from day one.

### Proposed tiering `[INFERRED — confirm]`

| Method | Tier | Reason |
|---|---|---|
| V60 | 1 | Highest variable-sensitivity; the engine's best showcase. Already built. |
| French press | 1 | Widely owned in Indian metros; only two real levers (grind, time) so the rule table is small and cheap |
| AeroPress | 2 | High enthusiast ownership, many variables, but recipe-driven culture |
| Moka pot | 2 | Common in Indian homes. Advice is technique-correction, not symptom diagnosis — be honest about that |
| South Indian filter | 2 | Culturally central to this market; no competitor models it; the milk story runs through it |
| Kalita / flat-bottom | 2 | Cheap once V60 exists |
| Cold brew | 3 | **12-hour feedback loop — the daily brew→taste→adjust cycle cannot run.** Do not force it into the timer model |
| Espresso | 3 | Different variables, different diagnosis model. Own initiative (Phase 4 in `06`) |
| Instant / pre-ground | 3 | Where most beginners actually start. An honest "here's why the next step up is worth it" card is a real acquisition surface |
| Chemex, siphon, cezve | 3 | Curiosity/browse value only |

**Open question:** South Indian filter at Tier 2 may be undershooting. It's the most
defensible differentiator in the list and no global coffee app touches it. Argue this
before locking.

---

## 3. New surface: Method Explorer

The exploration loop currently has no home. `[INFERRED]`

Add a browsable overview of all methods — comparable on a few honest axes: effort,
time, gear cost, forgiveness, and what the cup tastes like. A beginner should be able
to answer *"what should I try next, and why?"* in one screen.

- Lives in the **Brew** tab as its root-level browse state, not a new tab. Four tabs
  stay four tabs.
- Tier 1 and 2 methods offer "Start a brew." Tier 3 offer "Learn about this."
- Track which methods a user has tried. **This is the exploration loop's progress
  object** and the emotional payoff — a shelf of methods attempted, not a streak.

---

## 4. Water

**Decision: model it, but minimally.** `[INFERRED — Harsh delegated this call]`

Water is ~98% of the cup and is the highest-frequency *undiagnosable* failure in
Indian homes. RO water is too pure to extract properly; metro tap is usually too hard
and buffers acidity flat. A user on straight RO can follow every suggestion the engine
makes and never get there.

**Minimum viable version is a diagnosis gate, not an advice feature:**

1. One onboarding question: *what water do you brew with?* — RO, tap, bottled, RO+tap
   mix, don't know.
2. Store on the brew record.
3. **New rule, near the top of the diagnosis order** (above grind, alongside the
   bean-freshness rules): if water is straight RO and the report is sour/thin,
   the hypothesis is water, not grind. Saying *"this isn't your grind, it's your
   water"* when no other app can is a large trust win.
4. One Concept Card: why water matters, and the fix — **blend RO with tap, roughly
   70:30 to start.** Free, requires no purchase, and solves the most common invisible
   failure in this market. Mention bottled mineral water and the Epsom-salt DIY as
   secondary options.

Do **not** build a water calculator, mineral profiles, or TDS input. Out of scope.

---

## 5. Milk

Milk is in scope. `[STATED]`

Two things it affects:

**Diagnosis.** Milk flattens acidity and masks the sour/bitter axis the engine reads.
Add a **"with milk" flag** on the log. When set, suppress acidity-driven rules and
weight body/strength instead. Without this the engine will confidently misdiagnose
every milk drink. `[INFERRED — load-bearing, do not skip]`

**Content.** One concept card. **Teach the property, name brands as illustration.**
`[INFERRED]` Fat and protein are what determine texture — full-cream toned milk
steams and textures better than double-toned; fresh behaves differently from UHT.
Properties don't rot; brand lists do and are regional (Nandini is Bangalore, Amul is
national, Country Delight and Sid's Farm are metro D2C). Name two or three as examples
inside a property explanation, never as a standalone recommendation list.

**Scope milk to the methods it actually appears in** — moka, South Indian filter,
espresso. Not V60.

---

## 6. Stage: trajectory, not segment

Harsh's intent: beginners **and** people some way into the journey — explicitly not
professionals. `[STATED]`

**Do not build a mode selector.** `[INFERRED]` Beginners want fewer decisions; experienced
users want more control. There is no dial between those, and a stage toggle silently
multiplies every screen and every string by two.

**Build progressive disclosure instead.** One onboarding question sets *defaults only*
— it never locks a mode, and every control stays reachable. The app then deepens based
on **logged history**, not a self-declared label:

- Fewer than ~5 brews: strong defaults, plain-language copy, "grind finer" phrased in
  clicks not microns.
- Growing history on one method: surface finer parameters, planned-vs-actual diffs,
  more precise vocabulary.
- Advanced parameters are always available behind a disclosure, never gated.

The same app grows with one person over 18 months. That is a different and better
product than one serving two populations at once.

---

## 7. India / metro positioning

Target: Mumbai, Bangalore, Pune and comparable tier-1 cities. `[STATED]`

Consequences:

- **Bean database and examples must be Indian.** Blue Tokai, Subko, Third Wave,
  Naivo, KC Roasters, Curious Life and similar — not Counter Culture. `[INFERRED]`
- **Roaster and gear discovery: no marketplace, no affiliates.** Point outward only at
  a *triggered moment* — when a bag crosses its freshness window or is running out —
  never as a browsable directory. `[INFERRED]`
- **Social/YouTube: end of a course, not alongside it.** "You've finished Foundations,
  here's where to go deeper." Pointing outward after delivering your own value reads
  as confidence; instead of it, it reads as thin. `[INFERRED]`
- **Write the affiliate policy now**, while there's no money in it. A rule set before
  the temptation exists is the only kind that holds.

---

## 8. Build order

1. `supportTier` on `BrewMethod` + tier-aware UI gating. Unblocks everything.
2. Tier 3 content for all listed methods — cheapest breadth, immediately visible.
3. Method Explorer in the Brew tab.
4. French press to Tier 1 (second full rule table — proves the model generalises).
5. Water question + diagnosis gate + concept card.
6. Milk flag + rule suppression + concept card.
7. Tier 2 methods: AeroPress, moka, South Indian filter.
8. Progressive disclosure driven by brew count.

Do not start 7 before 4 is green. If the second rule table is painful, the tier model
is wrong and it's better to find out at two methods than at seven.

---

## 9. Inferred calls worth confirming

| # | Call | Cost if wrong |
|---|---|---|
| 1 | Two loops sequenced, exploration → mastery | Whole framing; everything else follows |
| 2 | New north star: 5 brews on one method in 30 days | Wrong metric drives wrong roadmap for a year |
| 3 | Three-tier method support | Structural; expensive to unpick later |
| 4 | Cold brew is Tier 3, never in the timer loop | Medium — forcing it in breaks the loop model |
| 5 | Water as a diagnosis gate, not an advice feature | Low to build, high trust value |
| 6 | Milk flag suppresses acidity rules | **High.** Without it, every milk drink is misdiagnosed |
| 7 | Progressive disclosure instead of a stage selector | High — a mode selector is very hard to remove later |
| 8 | South Indian filter at Tier 2 | Possibly undershooting the strongest differentiator |

---

## 10. Blocking, unchanged from `05`

OQ-1 (expert review of the rule table) was already blocking with one method. With
**two** full rule tables it is more so. Wrong coffee advice is unrecoverable with this
audience, and now there is twice as much of it.
