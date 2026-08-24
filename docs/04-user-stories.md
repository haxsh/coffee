# Epics & User Stories

> Updated by [`07-repositioning-brief.md`](07-repositioning-brief.md): adds Epic G
> (exploration) and Epic H (honest limits), and revises the critical path. Epics A–F
> are unchanged in substance — they are the mastery loop, which survived the
> repositioning intact.

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

## Epic G — Exploration

**Goal:** A user can find out what's out there and pick something to try.
**Done when:** A new user opens three method overviews and starts a brew, without
being told which one to pick.

---

### G1 — Compare methods honestly · P0

> When I know there are other ways to make coffee but not which is worth my money or
> my counter space, I want to see them side by side on things I actually care about,
> so I can pick one instead of defaulting to what I already own.

**Acceptance criteria**
- [ ] Given the Explorer, when it opens, then every method is listed with effort,
      time, gear cost, forgiveness and a taste description.
- [ ] Given a method I can't brew in the app, when I see it, then its card says so in
      words and offers "Learn about this" — never a disabled Start button.
- [ ] Given I told onboarding what gear I own, when the Explorer opens, then methods
      I can make today are ordered first.
- [ ] Given I skipped the gear question, when the Explorer opens, then it orders by
      forgiveness and offers one tap to tell it what I own.
- [ ] Given any method card, when I read it, then nothing on it implies a level of
      support the app doesn't have for it.

---

### G2 — Try something new with the friction as low as it goes · P0

> When I've decided to try a method for the first time, I want the app to not require
> gear I don't have, so a first attempt is actually possible tonight.

**Acceptance criteria**
- [ ] Given a method I've never brewed, when I start it, then the recipe offered is
      the most forgiving one available for that method, not the highest-clarity one.
- [ ] Given I have no grinder configured, when I start any brew, then it proceeds
      with descriptive grind guidance and never blocks.
- [ ] Given I complete a first brew on a method, when it saves, then that method
      appears on my shelf.

---

### G3 — See what I've tried · P1

> When I've been at this a couple of weeks, I want to see what I've actually made, so
> I get some credit for exploring and can see what I haven't touched yet.

**Acceptance criteria**
- [ ] Given ≥ 1 logged brew, when I open the Explorer, then the shelf shows each
      method I've brewed at least once.
- [ ] Given the shelf, when it renders, then it is derived from the journal — a
      deleted brew that was my only one on a method removes it.
- [ ] Given the shelf, when I look at it, then nothing on it can lapse, expire or
      break. It is a record, not a streak.

---

### G4 — Be nudged toward mastery, not away from it · P1

> When I've tried a few methods and keep coming back to one, I want the app to notice
> and help me get good at it, so exploring doesn't quietly become drifting.

**Acceptance criteria**
- [ ] Given ≥ 2 logged brews on one method, when I open Brew, then it opens on
      Continue rather than Explore.
- [ ] Given a method with several brews, when I view it, then I can see how many
      I've logged on it.
- [ ] Given I'm making progress on one method, when the app surfaces that, then it
      never frames trying another method as a failure.

---

## Epic H — Honest limits

**Goal:** The app never claims precision it doesn't have.
**Done when:** A tier 2 method's advice is visibly, structurally different from a
tier 1 diagnosis.

---

### H1 — Advice matches the tier · P0

> When the app tells me something after a brew, I want to know whether it's about my
> cup or about the brewer in general, so I know how much to trust it.

**Acceptance criteria**
- [ ] Given a `.full` method, when I log a brew, then I get a diagnosis and one
      adjustment in my own units.
- [ ] Given a `.guided` method, when I log a brew, then I get method-level notes and
      **no** single-change card, **no** from → to values, and copy that names the
      limit.
- [ ] Given a `.reference` method, when I view it, then there is no timer and no log.
- [ ] Given any tier 2 method, when its advice renders, then it shares no layout
      component with Next Time.
- [ ] **Enforced in the engine, not the view:** given a `.guided` method, when the
      engine runs, then it cannot return a per-symptom diagnosis at all.

---

### H2 — Water gets ruled out before grind · P0

> When my coffee is sour and it's because my RO water can't extract properly, I want
> to be told that, so I don't spend three weeks chasing my grinder.

**Acceptance criteria**
- [ ] Given RO water and a sour or thin cup, when I log it, then the advice names
      water — not grind — and gives the 70:30 blend fix.
- [ ] Given I've seen the water advice once, when I log another sour brew, then
      normal grind advice resumes. **The rule interrupts once; it does not repeat.**
- [ ] Given I change my recorded water source, when I next log a sour brew, then the
      rule may fire again.
- [ ] Given water "not sure", when I log anything, then the rule never fires.

---

### H3 — Milk drinks aren't misdiagnosed · P0

> When I make a coffee with milk, I want to be asked something I can actually answer,
> so the advice I get back means something.

**Acceptance criteria**
- [ ] Given a method where milk is normal, when I log a brew, then a milk toggle is
      present; given a method where it isn't, then it is absent.
- [ ] Given the milk toggle is on, when the log renders, then axis 1 asks
      harsh ↔ smooth ↔ flat, not sour ↔ bitter.
- [ ] Given a milk brew, when the engine runs, then no rule reading the extraction
      axis can fire.
- [ ] Given I set the toggle on a method, when I next log that method, then it
      defaults to my last answer — costing zero taps in the steady state.
- [ ] **Instrumented:** median log time on milk methods stays ≤ 30s.

---

## Story map — the critical path

```
        EXPLORATION                    THE HANDOFF                MASTERY
   F2 ─▶ G1 ─▶ G2 ─▶ G3 ────────────▶ G4 ────────────▶ A1 ─▶ A2 ─▶ A3
              │                                          │
              └─ H1 (tier honesty) ─┐                    ▼
                                    └──────────▶ B1 ─▶ B2 ─▶ B3 ─▶ E1
                                                  │      │
                                            H2, H3 ┘     └─ C1  ◀── ambient learning
```

**The chain that is the product is still B1 → B2 → B3** — log, diagnose, apply. That
did not change with the repositioning; it moved from being the *whole* app to being
the destination the app escorts people toward.

**What changed is the entrance.** G1 → G2 → G4 is now what a user meets first, and
**G4 is the single most important story in this document** — it is the handoff, and
the north star measures precisely it.

**H1 is a prerequisite for shipping breadth at all.** Adding methods without tier
honesty means claiming diagnosis on methods that have no rule table, which is worse
than not shipping them.
