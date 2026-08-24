# Epics & User Stories

Stories are written as **job stories** where situation drives behaviour, and as
classic user stories where the role is what matters. Acceptance criteria are
testable — if a criterion can't be passed or failed by someone who wasn't in the
room, it's rewritten.

**Priority:** P0 = MVP is not shippable without it · P1 = v1 · P2 = v1.1+

---

## Epic A — Guided Brewing

**Goal:** A user can execute a repeatable brew without holding numbers in their head.
**Done when:** A first-time user completes a V60 brew end to end, one-handed,
without reading instructions outside the app.

---

### A1 — Start a brew with everything pre-computed · P0

> When I've decided to make coffee and I'm standing at the counter, I want the app
> to have already worked out my water, grind and temperature for the dose I actually
> weighed, so I can start pouring instead of doing arithmetic.

**Acceptance criteria**
- [ ] Given a selected recipe, when I open Brew Setup, then dose, ratio, grind,
      temp and computed water are all pre-filled from the recipe and my grinder.
- [ ] Given I change the dose, when the value updates, then total water and every
      step's cumulative target recompute immediately and visibly.
- [ ] Given a pending adjustment from my last brew, when Brew Setup opens, then the
      adjusted grind is applied and visibly labelled as an adjustment.
- [ ] Given I have no beans saved, when I open Brew Setup, then the bean field reads
      "Not tracking this one" and Start remains enabled.
- [ ] Given I change nothing, when I tap Start, then the brew begins with valid values.

---

### A2 — Follow a step-timed brew without looking · P0

> When I'm pouring with a kettle in one hand and steam in my face, I want to be told
> what to do by sound and feel, so I can keep my eyes on the coffee.

**Acceptance criteria**
- [ ] Given a brew is running, when a step ends, then a distinct audio tone and a
      notification haptic fire and the next step's instruction is displayed.
- [ ] Given a timed step with 3s remaining, when each second elapses, then a light
      haptic tick fires.
- [ ] Given music or a podcast is playing, when a cue fires, then other audio ducks
      and resumes; it is never stopped.
- [ ] Given a brew is running, when I do nothing, then the screen never sleeps.
- [ ] Given the water target for a step, when displayed, then it is the **cumulative**
      total matching a scale reading, not a per-pour amount.
- [ ] Given VoiceOver is on, when a step changes, then the new instruction is
      announced at assertive priority.
- [ ] Given a step's allotted time is exceeded, when the overrun begins, then the
      display indicates it without an alert, a sound, or blocking progress.

---

### A3 — Not lose a brew to the real world · P0

> When my phone locks or someone calls me mid-pour, I want the brew to keep running,
> so one interruption doesn't cost me the cup.

**Acceptance criteria**
- [ ] Given a brew starts, when it begins, then a Live Activity is created showing
      elapsed time and current water target.
- [ ] Given the app is backgrounded or the phone is locked, when a step changes,
      then the Live Activity updates and the cue still fires.
- [ ] Given the Dynamic Island is expanded, when I tap Next, then the brew advances
      without opening the app.
- [ ] Given the app was force-quit mid-brew, when I relaunch, then I'm asked whether
      to log or discard the interrupted brew, with the elapsed time preserved.
- [ ] Given the device is in airplane mode, when I run a complete brew, then every
      feature behaves identically.

---

### A4 — Learn a term without abandoning the brew · P0

> When an instruction uses a word I don't know while I'm mid-brew, I want to read
> what it means right now, so I don't have to choose between understanding and
> finishing.

**Acceptance criteria**
- [ ] Given a concept reference in a step instruction, when I tap it, then a Concept
      Card sheet opens over the running timer.
- [ ] Given the sheet is open, when time passes, then the timer keeps running, cues
      still fire, and the Live Activity stays visible.
- [ ] Given I dismiss the sheet, when it closes, then I return to the exact brew state.
- [ ] Given the device is offline, when I open any Concept Card, then it renders
      immediately with no loading state.

---

## Epic B — The Feedback Loop *(the differentiator — nothing ships without it)*

**Goal:** Every brew produces one actionable, explained change.
**Done when:** Users measurably apply suggestions and their ratings climb.

---

### B1 — Log a brew in under 30 seconds · P0

> When my coffee is made and I want to drink it, I want logging to be almost free,
> so I actually do it every time instead of twice.

**Acceptance criteria**
- [ ] Given the brew timer completes, when it ends, then Log Brew appears
      automatically without a tap.
- [ ] Given the log screen, when it opens, then rating, taste axis and body axis are
      reachable in three taps total, above the fold, no scrolling.
- [ ] Given I set only a rating, when I tap Save, then the brew saves successfully.
- [ ] Given actual dose, time, grind and ratio, when the screen opens, then they are
      pre-filled from the brew and collapsed behind one summary line.
- [ ] Given I dismiss the sheet, when it closes, then whatever I entered is saved,
      not discarded.
- [ ] **Instrumented:** median time from open to save is recorded and must be ≤ 30s.

---

### B2 — Get one specific thing to change · P0

> When my cup didn't taste right, I want to be told the single most likely cause and
> exactly one change, in my grinder's units, so I can act without guessing.

**Acceptance criteria**
- [ ] Given a saved taste record, when I save, then Next Time shows exactly **one**
      recommended change.
- [ ] Given the change is a grind change, when displayed, then it is expressed in my
      grinder's own units with from → to values.
- [ ] Given no grinder is configured, when a grind change is recommended, then it is
      expressed as a relative step and I'm offered grinder setup.
- [ ] Given the bean has fewer than 4 rest days, when diagnosis runs, then the app
      recommends no change and explains degassing.
- [ ] Given a balanced, well-rated brew, when diagnosis runs, then it says nothing
      needs changing and offers to save it as my recipe.
- [ ] Given any recommendation, when shown, then it links to exactly one Concept Card.
- [ ] Given any recommendation, when shown, then "Not this time" is available and
      dismisses without applying.

---

### B3 — Have the adjustment waiting next time · P0

> When I come back tomorrow, I want yesterday's decision already applied, so the
> improvement happens without me remembering anything.

**Acceptance criteria**
- [ ] Given I tap "Save this for next time", when I next open Brew Setup for that
      method, then the adjusted value is pre-filled and labelled as an adjustment.
- [ ] Given an adjustment is pending, when Brew Home renders, then "Brew again"
      surfaces it.
- [ ] Given I brew with the adjustment applied, when the brew saves, then it records
      which prior brew it was adjusted from.
- [ ] Given an adjustment was applied and the rating improved, when Next Time renders,
      then it leads with the improvement, naming both ratings and the change made.
- [ ] Given an adjustment was applied and the rating got worse, when Next Time renders,
      then it says so plainly and offers to revert.

---

## Epic C — Learning

**Goal:** Understanding arrives in context; depth is available on demand.
**Done when:** ≥ 50% of lesson opens originate from a Concept Card, not the Learn tab.

### C1 — Look up any term, from anywhere · P0
- [ ] Given a technical term in any screen's copy, when it has a Concept, then it is
      visibly tappable.
- [ ] Given I tap it, when the sheet opens, then I see term, one-line definition, and
      a ~60-second explainer.
- [ ] Given a Concept has a lesson, when the sheet is open, then "Learn more" opens it.
- [ ] Given the same Concept opened from three different screens, when compared, then
      the content is identical.

### C2 — Work through a course · P1
- [ ] Given a course, when I open it, then I see lesson list, per-lesson minutes, and
      my progress.
- [ ] Given I leave a lesson mid-way, when I return, then I resume at the same block.
- [ ] Given I've completed no prior lessons, when I open lesson 4, then it opens —
      lessons are not sequence-gated.
- [ ] Given a lesson with a quiz, when I answer wrong, then I see the explanation, not
      just the correction.

### C3 — Try what I just learned · P1
- [ ] Given a lesson with a Try It, when I tap it, then Brew Setup opens pre-configured
      for that lesson's variation.
- [ ] Given I arrived from a lesson, when I complete that brew, then Next Time
      references the lesson's variable.
- [ ] Given I tap back from that Brew Setup, then I return to the lesson, not a dead end.

---

## Epic D — Beans

**Goal:** Enough context for accurate diagnosis, and a memory of what you liked.

### D1 — Add a bag in under 30 seconds · P1
- [ ] Given Add Bean, when it opens, then name and roast date are the only prominent
      fields and everything else is optional and below the fold.
- [ ] Given roast date, when the screen opens, then it defaults to today.
- [ ] Given only a name, when I save, then the bean saves.

### D2 — Know whether a bag is ready · P1
- [ ] Given a bean with a roast date, when shown in any list, then a freshness state
      is displayed (resting / peak / fading / stale).
- [ ] Given a bean under 4 rest days, when used in a brew, then diagnosis accounts for
      degassing.
- [ ] Given a bean's rest days, when stored on a brew, then the value is frozen at
      brew time.

### D3 — Remember my best cup from a bag · P1
- [ ] Given a bean with ≥ 1 rated brew, when I open Bean Detail, then my highest-rated
      brew with it is shown with its full parameters.
- [ ] Given that brew, when I tap "Brew this", then Brew Setup opens with those exact
      parameters.

---

## Epic E — Journal

### E1 — See what I've brewed · P0
- [ ] Given ≥ 1 brew, when I open Journal, then brews are listed newest first, grouped
      by day, each showing method, bean, rating and any applied adjustment.
- [ ] Given no brews, when I open Journal, then I see an empty state with one action.
- [ ] Given a brew, when I open it, then I see planned vs actual side by side with
      differences highlighted, the diagnosis given, and whether it was applied.

### E2 — Get my data out · P0
> When I've built up months of brews, I want to be able to export them, so my history
> isn't hostage to this app.
- [ ] Given any number of brews, when I tap Export, then I get CSV and JSON containing
      every brew, its parameters, taste record and diagnosis.
- [ ] Given the device is offline, when I export, then it succeeds.
- [ ] Given the free tier, when I export, then it is not restricted. **Not a paid feature.**

---

## Epic F — Foundations

### F1 — Grinder that means something · P0
- [ ] Given onboarding, when I pick a grinder, then I'm asked one anchoring question
      ("what do you use for pour-over?") and no measurement is required.
- [ ] Given a calibrated grinder, when any recipe or recommendation shows a grind,
      then it's shown in my grinder's units.
- [ ] Given "I don't know / pre-ground", when selected, then grind guidance switches to
      descriptive terms and the app never shows meaningless numbers.

### F2 — First brew must not fail · P0
- [ ] Given a brand-new user, when they complete onboarding, then they land directly in
      Brew Setup with a valid, forgiving recipe pre-filled.
- [ ] Given a user skips every onboarding step, when they reach Brew Setup, then all
      values are valid defaults and Start works.

### F3 — Works entirely offline · P0
- [ ] Given airplane mode from install onward, when I use every v1 feature, then all of
      them work, including all lessons and concepts.
- [ ] Given a failed remote content update, when it fails, then the bundled content is
      used and no error is shown to the user.

---

## Story map — the critical path

```
F2 ─▶ F1 ─▶ A1 ─▶ A2 ─▶ A3 ─▶ B1 ─▶ B2 ─▶ B3 ─▶ E1
                              │       │
                              └─ C1 ──┘   ◀── the ambient learning join
```

**Build B1 → B2 → B3 before any breadth work.** Everything else is supporting
structure; that chain is the product. If it isn't working by the end of the
prototype phase, no amount of methods, lessons or charts will save the app.
