# Assumption Log, Open Questions & Risks

Everything in the other documents rests on these. They are listed here so that when
something turns out to be wrong, we know exactly what has to change.

**Types:** 🟡 Business · 🔵 User · 🔴 Technical · ⚪ Scope

> Revised by [`07-repositioning-brief.md`](07-repositioning-brief.md). **A6 is
> retired** — it is now false by decision, not by evidence. A5 is re-rated: it was
> medium risk against a Western enthusiast and is high risk against an Indian metro
> user, which is the single biggest change in this table.

---

## Retired

| # | Assumption | Why it's gone |
|---|---|---|
| **A6** | *One method (V60) is enough to prove the loop* | Retired by the repositioning. It was a correct assumption for a bet the product is no longer making. It is worth keeping visible rather than deleting: it was never invalidated by evidence, it was **overtaken by a strategy change**, and confusing those two is how teams learn the wrong lesson from a pivot. |

---

## Assumption log

| # | Assumption | Type | Confidence | How to validate | Cost if wrong |
|---|---|---|---|---|---|
| A1 | People will log a brew **every time** if it takes under 30 seconds | 🔵 | **Low** | Prototype the log screen alone; 10 users, 5 brews each at home, over a week | **Fatal to the mastery loop.** No log → no diagnosis → no loop. Still the assumption the depth half of the product rests on. |
| A2 | Two 5-point axes carry enough signal to diagnose usefully | 🔵🔴 | Medium | Experienced brewer tastes 20 cups; compare our 2-axis input against a full cupping form | High. Would force richer input, which fights A1 directly. |
| A3 | Users will **trust and follow** a single suggested change | 🔵 | Medium | Prototype test: show a diagnosis, ask what they'd do next | High. If they want options, the "one change" principle breaks. |
| A4 | Learning delivered in-context beats a lessons destination | 🔵 | Medium-high | Instrument concept opens by origin | Medium. If the Learn tab wins, restructure toward course-first. |
| **A5** | Target users own a **calibratable burr grinder** | 🔵 | **Low** — was Medium | Survey grinder ownership in Mumbai/Bangalore/Pune specifically. Cheap and fast. | **Severe, and now the most under-examined item here.** Grind is the primary lever in every tier 1 rule table. A pre-ground user can act on ratio, water and temperature only — roughly half the engine. The repositioning made this worse, not better: it moved the target market toward a segment where pre-ground purchase is common and simultaneously made the diagnosis engine the *destination* rather than the whole product. **If A5 is false for most users, the handoff has nowhere to hand them off to.** |
| A7 | Live Activities + audio + haptics give a reliable background timer | 🔴 | Medium-high | Spike with a real call mid-brew, Low Power Mode, Focus | High and early. Partially retired by CI compiling it, but *behaviour* is still unverified. |
| A8 | The rule table produces advice a professional would endorse | 🔴 | **Low** | Q-grader / roaster review — OQ-1 | **High, and now doubled.** Two full rule tables. |
| A9 | Grinder anchoring beats real calibration | 🔴🔵 | Medium | Test relative steps across 3–4 popular grinders | Medium. Fallback is per-model step tables. |
| A10 | People will pay; free tier drives the habit | 🟡 | Low | Pricing test post-launch | Medium. Deliberately under-specified. |
| A11 | Ratings measurably improve over the first 10 brews | 🔵🟡 | Medium | Measure at day 30 | High — it's the marketing claim. |
| A12 | Beans is used enough to earn a tab | ⚪🔵 | Low | Instrument tab opens | Low. Demote to a Journal segment. |
| A13 | Text + illustration lessons are sufficient | ⚪🟡 | Medium | Lesson completion rates | Medium. Video is a production commitment. |

### New with the repositioning

| # | Assumption | Type | Confidence | How to validate | Cost if wrong |
|---|---|---|---|---|---|
| **A14** | **Exploration and mastery are sequential for one person** — people explore, settle, then deepen | 🔵 | **Low** | Diary study with 8–10 target users over 30 days. Watch whether anyone actually settles, or whether they keep hopping indefinitely. | **Highest-consequence new assumption.** The whole two-loop framing, the north star, and the app's central job all rest on it. If people never settle, the mastery loop is built for a user who doesn't exist and the app is a browse-and-timer product. |
| **A15** | Three support tiers read as *honest* rather than as *crippled* | 🔵⚪ | Medium | Show the Explorer to 8 users; ask what they think a "Learn about this" method means | **Structural.** If tiering reads as a paywall or as bugs, breadth actively costs trust instead of buying attention. Cheap to test with a static mockup, expensive to unpick after build. |
| **A16** | Milk needs a **different axis pair**, not just rule suppression | 🔵🔴 | Medium-high | Have 5 people rate the same milk coffee on both axis pairs; see which one they can answer at all | **High.** Getting this wrong means either misdiagnosing every milk drink (the brief's version) or asking a question users can't answer (literal suppression). It also caps how far a milk-first method can ever be promoted — see the open question below. |
| **A17** | The 70:30 RO-to-tap blend is good general advice for Indian metros | 🔴 | **Low** | Same expert review as OQ-1 — this is a coffee claim, not a product claim | High. It's the app's most distinctive single piece of advice and the one most likely to be repeated to friends. Wrong, it's memorably wrong. Tap hardness varies enormously between and within these cities. |
| **A18** | The new north star (5 brews on one method in 30 days) is the right target | 🟡 | Medium | Can't be validated pre-launch. Sanity-check the ≥25% target against any comparable habit app. | High — a wrong metric drives a wrong roadmap for a year. The *shape* is right; the threshold is a guess. |
| **A19** | Progressive disclosure by brew count serves both ends without a mode | 🔵⚪ | Medium | Usability test at 0 brews and at simulated 20 brews | High. A mode selector is very hard to remove later, so this is worth being right about early rather than reversible. |
| **A20** | Tier 3 reference cards are worth building at all | ⚪🔵 | Medium | Instrument tier-3 dead ends from day one | Medium. If browsing routinely ends there, they're a brochure and the effort should go into promoting one method instead. |
| **A21** | A second rule table (French press) can be authored without an expert per method | 🔴⚪ | Medium | **Build it and see** — this is `07` §8 step 4, deliberately sequenced as the test | **Structural.** If the second table is painful, the tier model doesn't generalise and the whole breadth strategy needs rethinking. Better to learn this at two methods than at seven. |

---

## Inferred calls carried in from `07` §9

The brief marks these `[INFERRED]` — decided on Harsh's behalf, pending confirmation.
They are recorded here as assumptions so they don't quietly become facts.

| # | Call | Status | Cost if wrong |
|---|---|---|---|
| 1 | Two loops, sequenced exploration → mastery | **Confirm** — see A14 | Whole framing; everything follows |
| 2 | North star: 5 brews on one method in 30 days | **Confirm** — see A18 | Wrong roadmap for a year |
| 3 | Three-tier method support | **Confirm** — see A15, A21 | Structural; expensive to unpick |
| 4 | Cold brew is Tier 3, never in the timer loop | **Agreed, no argument.** A 12-hour feedback loop cannot run a daily brew→taste→adjust cycle. Worth noting a scheduled *reminder* is a different feature that might serve it later without touching the loop model. | Medium |
| 5 | Water as a diagnosis gate, not an advice feature | **Agreed, with one change:** it must fire *once* and then step aside, or it jams the mastery loop permanently for every RO user. See `02`, rule 3. | Low to build, high trust value |
| 6 | Milk flag suppresses acidity rules | **Agreed in direction, revised in mechanism** — see A16. Suppression alone still asks an unanswerable question. | **High** |
| 7 | Progressive disclosure instead of a stage selector | **Agreed, no argument** — see A19 | High |
| 8 | South Indian filter at Tier 2 | **Agreed for now, for a different reason than the brief gives** — see the open question below | Possibly undershooting |

---

## Open questions

| # | Question | Why it matters | Needed by |
|---|---|---|---|
| **OQ-1** | **Who reviews the rule tables?** | Now **two** full tables plus the water claim (A17). Thresholds are educated guesses. Shipping wrong coffee advice is the fastest way to lose this audience, and there is now twice as much of it. | **Before build.** Blocking. |
| **OQ-9** | **Can South Indian filter ever be Tier 1?** | `07` asks whether Tier 2 undershoots. The answer turns on A16: milk removes the extraction axis, so a milk-first method needs a second *diagnosis model*, not a second rule table. Tier 2 is right today; the real question is whether building that second model is worth it — and it might be, because it would unlock filter coffee, moka-with-milk and eventually espresso together. | Before promoting any milk-first method |
| **OQ-10** | **Does the pre-ground user get a real product?** | A5. If grind is unavailable, tier 1 diagnosis loses its main lever. Options: a ratio-and-temperature-only rule path, or pushing grinder purchase as the app's one gear opinion. Both are decisions, not defaults. | Before build — it changes the engine |
| OQ-2 | Free vs Pro line | Recommendation unchanged: journal, export and the diagnosis engine are never paid. Tiering must not become the paywall. | Before build |
| OQ-3 | Segmented controls or sliders for the taste axes | Drives the 30-second target and diagnosis fidelity | Before design freeze |
| OQ-4 | Roast-level freshness windows | Implemented roast-aware; thresholds still unreviewed | Before build |
| OQ-5 | The name | "Grind" is a placeholder and almost certainly taken | Before submission |
| OQ-6 | Watch app in v1.1 or v2 | Genuine answer to wet hands | After launch data |
| OQ-7 | Who writes the lesson content — **and now the tier 3 cards** | Twelve reference cards plus concept cards is real authorial work by someone who knows coffee. Larger than before. | Before build |
| OQ-8 | Analytics, and how we say so honestly | Every metric here needs instrumentation | Before build |

---

## Risks, ranked

1. **A14 — nobody settles.** If exploration doesn't converge into mastery, the
   north star is unreachable by construction and half the app serves nobody. This is
   now a bigger risk than the log screen, because the log screen at least has a
   testable prototype and this doesn't until people use it for a month.
   → *Diary study before build. It's the cheapest way to find out whether the central
   framing describes real behaviour.*

2. **A5 — the pre-ground user.** Grind is the primary lever in every rule table, and
   the repositioning moved us toward a market where many people don't own a grinder.
   → *Survey grinder ownership in the target cities. One afternoon, and it may change
   the engine.*

3. **Wrong coffee advice is unrecoverable — and there's more of it now.** Two rule
   tables plus a water claim that will be repeated to friends.
   → *OQ-1 is blocking, and now covers A17.*

4. **Tier 2 borrowing Tier 1's clothes.** If method-level advice renders like a
   diagnosis, the app claims precision it lacks on the majority of its methods.
   → *Design S30 separately, sharing no component with S07.*

5. **The log screen is still a single point of failure**, and milk and water both
   push on it.
   → *The 30-second budget does not increase. Test it with the milk toggle in place.*

6. **Breadth becomes a brochure.** Twelve reference cards and two brewable methods
   is a Wikipedia category with a tab bar.
   → *Track tier-3 dead ends from day one. Promote rather than add.*

7. **Content authoring is unestimated, and grew.** Twelve overview cards, two rule
   tables, water and milk concepts.
   → *OQ-7 during planning, not during build.*
