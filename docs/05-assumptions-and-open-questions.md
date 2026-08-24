# Assumption Log, Open Questions & Risks

Everything in the other five documents rests on these. They are listed here so that
when something turns out to be wrong, we know exactly what has to change.

**Types:** 🟡 Business · 🔵 User · 🔴 Technical · ⚪ Scope

---

## Assumption log

| # | Assumption | Type | Confidence | How to validate | Cost if wrong |
|---|---|---|---|---|---|
| A1 | People will log a brew **every time** if it takes under 30 seconds | 🔵 | **Low** | Prototype the log screen alone; 10 users, 5 brews each at home, over a week. Measure completion rate, not opinion. | **Fatal.** No log → no diagnosis → no loop → the app is a timer. This is the assumption the entire product rests on. Test it first and cheaply. |
| A2 | Two 5-point axes carry enough signal to diagnose usefully | 🔵🔴 | Medium | Have an experienced brewer taste 20 cups, record both our 2-axis input and a full cupping form, compare the diagnoses | High. Would force richer input, which fights A1 directly. This tension is the central design problem. |
| A3 | Users will **trust and follow** a single suggested change | 🔵 | Medium | Prototype test: show a diagnosis, ask what they'd do next. Do they accept, ignore, or want alternatives? | High. If they want options, the "one change" principle breaks and interpretability goes with it. |
| A4 | Learning delivered in-context beats a lessons destination | 🔵 | Medium-high | Instrument Concept-Card-originated lesson opens vs Learn-tab opens | Medium. If Learn-tab wins, restructure toward a course-first product. |
| A5 | Target users own a **calibratable burr grinder** | 🔵 | Medium | Survey; check grinder ownership in the enthusiast segment | High. Pre-ground users can't act on grind advice at all — the primary lever disappears and diagnosis falls back to ratio and temperature only. |
| A6 | One method (V60) is enough to prove the loop | ⚪ | High | — | Low; adding methods is additive |
| A7 | Live Activities + audio + haptics give a reliable background timer | 🔴 | Medium-high | Technical spike, week 1. Test with a real call mid-brew, low power mode, and Focus modes. | **High and early.** If background timing is unreliable, the hero screen's core promise fails and the design changes. **Spike this before design finalises.** |
| A8 | The rule table produces advice a professional would endorse | 🔴 | **Low** | Q-grader / roaster review — see OQ-1 | **High.** Wrong advice destroys trust permanently. Cheap to fix now, impossible to fix after launch. |
| A9 | Grinder anchoring ("what do you use for pour-over?") beats real calibration | 🔴🔵 | Medium | Test whether relative steps land correctly across 3–4 popular grinders | Medium. Fallback is per-model step tables, which is a data-collection problem. |
| A10 | People will pay for methods and courses; the free tier drives the habit | 🟡 | Low | Pricing test post-launch | Medium. Business model, not product model — deliberately under-specified in v1. |
| A11 | Ratings will measurably improve over the first 10 brews | 🔵🟡 | Medium | This is the north-star promise; measure at day 30 | **High** — it's the marketing claim. If ratings don't climb, either the engine or the premise is wrong. |
| A12 | Beans is used enough to earn a tab | ⚪🔵 | Low | Instrument tab opens from day one | Low. Demote to a Journal segment. Cheap to fix. |
| A13 | Text + illustration lessons are sufficient; video isn't required | ⚪🟡 | Medium | Lesson completion rates | Medium. Video is a production commitment, not a feature toggle. |

---

## Open questions

| # | Question | Why it matters | Needed by |
|---|---|---|---|
| **OQ-1** | **Who reviews the diagnosis rule table?** | It is a designer's draft. Thresholds (rest days, temperature cut-offs, drawdown bands) are educated guesses. Shipping wrong coffee advice is the fastest way to lose the audience that would otherwise love this. | **Before build.** Blocking. |
| **OQ-2** | Free vs Pro line — what exactly is paid? | Shapes the paywall, the onboarding promise, and whether the free tier can build a habit. Current recommendation: methods and courses are paid; **journal, export and the diagnosis engine are never paid.** | Before build |
| **OQ-3** | Segmented controls or sliders for the taste axes? | Drives the 30-second target and diagnosis fidelity. Spec says segments; A2 might argue for more granularity. | Before design finalises |
| **OQ-4** | Do freshness windows differ enough by roast level to model separately? | Light roasts often peak later than dark. If we use one window, diagnosis rule 1 misfires on light roasts — which is most of what our users buy. | Before build |
| **OQ-5** | Name. "Grind" is a placeholder and almost certainly taken. | App Store search, trademark, and every piece of copy | Before submission |
| **OQ-6** | Watch app in v1.1 or v2? | It's the genuine answer to the wet-hands problem and may be more valuable than a second brew method. | After v1 launch data |
| **OQ-7** | Who writes the lesson content? | 8 lessons × ~4 min plus 25 concept cards is real authorial work with a real cost, and it must be written by someone who actually knows coffee. Not a build task. | Before build |
| **OQ-8** | Do we ship any analytics at all, and how do we say so? | Every metric in the brief needs instrumentation. A product built on trust needs an honest, local-first-flavoured privacy answer. | Before build |

---

## Risks, ranked

1. **The log screen is the single point of failure.** Every downstream feature
   assumes a taste record exists. If logging is skipped, the app degrades to a
   timer with a lessons tab — a worse version of apps that already exist.
   → *Prototype and test S06 in isolation before anything else is designed.*

2. **Wrong coffee advice is unrecoverable.** The target user can taste when advice
   is wrong, and this audience talks to each other. One confidently incorrect
   recommendation costs more than a month of polish buys.
   → *OQ-1 is blocking. Get an expert reviewer before build starts.*

3. **Background timer reliability is a hard iOS constraint, not a design choice.**
   If Live Activity updates or audio cues prove unreliable under low-power mode or
   Focus, the hero screen's promise ("run the brew without looking") breaks.
   → *Technical spike in week 1, before the design is finalised.*

4. **Scope gravity toward breadth.** "Just add AeroPress" is a two-week trap that
   feels like progress and tests nothing new. Every method multiplies recipes,
   rule tables, illustrations and QA.
   → *One method until the loop metrics are green. Hold the line.*

5. **The espresso migration.** Modelled in `02-content-model.md`; the fix is a
   method-scoped parameter bag in v1. Costs a day now, costs a migration later.
   → *Non-negotiable in the data model, even though espresso is out of scope.*

6. **Content authoring is unestimated.** Lessons and concepts are treated as a
   design deliverable in this spec but they're a writing project with its own
   timeline and its own required expertise.
   → *Resolve OQ-7 during planning, not during build.*
