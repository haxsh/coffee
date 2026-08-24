# Phasing

Phases are gated on **evidence**, not on calendar. Each gate is a question that has
to be answered yes before the next phase starts.

---

## Phase 0 — De-risk *(before any production design)*

Cheapest possible tests of the three things that could kill the product.

| Work | Answers |
|---|---|
| Technical spike: Live Activity + background audio + haptics through a full 4-min brew, with an interrupting call, low power mode, and a Focus mode | A7 |
| Throwaway prototype of **S06 Log Brew only** — 10 users, real kitchens, one week | A1 — the fatal assumption |
| Diagnosis rule table reviewed by a Q-grader or experienced roaster | A8 / OQ-1 |
| Card sort of the tab bar with 8–10 target users | The mixed verb/noun flag |

**Gate:** Do people log ≥ 80% of their brews with a 30-second form? If not, the
loop premise needs rethinking before a line of production code.

---

## Phase 1 — The loop, one method

Everything marked 🟢 in `03-screen-specs.md`. V60 only. Three recipes. One course
(~8 lessons). ~25 concepts. Full offline. Local-only storage.

**Build order:** F2 → F1 → A1 → A2 → A3 → **B1 → B2 → B3** → E1 → C1 → D1 → the rest.

**Gate — the loop is working:**
- ≥ 45% of new users log a brew within 24h
- ≥ 40% of diagnoses are applied to the next brew
- Median log time ≤ 30s
- Ratings for brews 8–10 beat brews 1–3 by ≥ 0.6 stars

If those are green, the product works and everything after is amplification. If
they're red, **do not add features** — fix the loop.

---

## Phase 2 — v1.1, depth before breadth

Ships only if Phase 1's gate is green.

- **Apple Watch companion** — the honest answer to wet hands. Strong candidate to
  outrank a second brewing method in value.
- **CloudKit sync** (private database; no accounts, no server, no data leaving the
  user's iCloud)
- **Insights** — now that users have 20+ brews and the charts say something
- **Recipe editor** (duplicate-and-edit)
- **Bag label scanning** — the highest-value delight feature identified
- **AeroPress** — the first added method, and the real test of whether the
  method-scoped parameter model works

---

## Phase 3 — Breadth

French press · Chemex · cold brew · a second and third course · the Flavour
Trainer · global search.

---

## Phase 4 — Espresso, as its own initiative

Not a method addition. Different variables, different diagnosis model, different
user behaviour (10 shots a morning while dialling in, not 1 cup). It needs its own
brief. The v1 data model is built so this is an addition rather than a migration —
that's the only espresso work in scope before Phase 4.

---

## Deliberately never (unless the strategy changes)

Social feed · gear affiliate marketplace · café directory · pro/roastery tooling ·
streak-based gamification as the primary motivator. Each of these pulls the product
away from the one thing it's for: making your next cup better than your last one.
