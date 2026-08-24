# Product Brief — Grind

**Owner:** Harsh · **Status:** Draft v0.2 — repositioned · **Last updated:** 2026-08-25

> Repositioned by [`07-repositioning-brief.md`](07-repositioning-brief.md) from
> *mastery of one method* to *guided exploration across many, for the Indian metro
> market*. Where this document and `07` disagree, `07` wins.

---

## 1. The idea, compressed

A home-brewing companion for iOS that helps you find the brewing method that suits
you, then makes you good at it. It ships brew recipes with a guided timer, a
browsable library of brewing methods, structured concepts, a brew journal, and a
bean shelf — held together by **two loops**, and by the app's job of moving you
from the first to the second.

---

## 2. Problem

There are two problems, and they belong to the same person at different times.

### The exploration problem — months 0 to 1

**User:** Someone in a metro who got into specialty coffee through a café or a
lockdown purchase, and owns one brewer they didn't really choose.
**Situation:** They know there are other ways to make coffee. They don't know which
is worth their money, their counter space, or their morning.
**Pain:** Every answer online is a fifteen-minute video by someone with a €400
grinder, and none of them says *"here's what this actually tastes like, what it
costs, and whether you'd like it."*
**Impact:** They stay on the one brewer they have, or they buy the wrong second one.

### The mastery problem — month 2 onward

**User:** The same person, now settled on a method.
**Situation:** They stand at the counter each morning with five minutes and one shot
at the cup.
**Pain:** They follow a recipe, get a cup that's sour or bitter or just flat, and
have no idea which of eight variables caused it. So they change three things at
once, or nothing, and never converge.
**Impact:** They stall at "fine" coffee forever, blame the beans, and stop caring.

> One-liner: *People can't tell which brewing method is for them, and once they pick
> one they can't connect what they did to how it tasted.*

### Why this is a real gap, not a crowded one

| Category | What exists | What it doesn't do |
|---|---|---|
| Recipe + timer apps | Step timers, ratio calculators, method presets | Tell you *what*, never *why*. No memory of your last cup. |
| Education | YouTube, roaster blogs, books, courses | Excellent content, entirely detached from the cup in your hand. Consumed on a couch, not at a counter. |
| Journals / logs | Structured logging, export, stats | Record-keeping with no feedback. Data in, nothing out. |
| Bean trackers | Inventory, roast dates, freshness | Isolated from brewing entirely. |
| **All of the above** | Written for a Western enthusiast with a burr grinder, filtered water and black coffee | **Nothing models milk, RO water, chicory, or South Indian filter — which is most of how coffee is actually made in our market.** |

That last row is the differentiated one. The first four are the reason to build a
diagnosis engine; the fifth is the reason to build it *here*.

---

## 3. Two loops

The product is no longer one loop. It is two, sequenced — and the app's central job
is escorting a user from the first into the second.

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

### The exploration loop

1. **Discover** — browse every method the app knows about, comparable on effort,
   time, gear cost, forgiveness, and what the cup tastes like.
2. **Try** — for anything the app supports with a timer, brew it with the friction
   as low as it goes: no grinder required, sensible defaults, forgiving recipe.
3. **Compare** — see what you've tried and what you thought of it.
4. **Prefer** — settle. The progress object here is a **shelf of methods attempted**,
   not a streak.

### The mastery loop

1. **Brew** — a guided, step-timed pour with everything pre-computed for your dose,
   your grinder, your bean.
2. **Taste** — under 30 seconds of structured input. A rating and two axes.
3. **Diagnose** — map the axes to a hypothesis and name the single most likely cause.
4. **Adjust** — propose **one** variable change and pre-load it. One. Changing three
   is why people never converge.

Learning runs through both: a Concept Card is reachable from any technical term,
in either loop.

### They pull against each other, on purpose

A user hopping between methods never accumulates the repetitions on one method that
the diagnosis engine needs. That tension is not a flaw to design away — it is the
shape of the product. Exploration buys attention; mastery keeps it. **The metric
that matters is the handoff between them**, not the volume of either.

### Why this makes the pillars one product

| Pillar | Its job | Without the loops, it's… |
|---|---|---|
| Method Explorer | Exploration 1–4 | A Wikipedia category page |
| Recipes + timer | Exploration 2, Mastery 1 | Another timer app |
| Journal | Mastery 2 + memory | A notes app with fields |
| Concepts | Both, ambiently | A blog you don't visit |
| Bean shelf | Context for everything | An inventory spreadsheet |

---

## 4. Users

Target market: **Mumbai, Bangalore, Pune and comparable tier-1 Indian cities.**

### Primary — "Metro Explorer"
Mid-twenties to late thirties, salaried or running something. Came in through a café
— Blue Tokai, Third Wave, Subko — or a lockdown purchase. Owns *a* brewer, usually
one they were given or picked on a whim: a French press, a moka pot, maybe an
AeroPress. **Does not necessarily own a grinder**, and often buys pre-ground.
Brews with RO water without thinking about it. Drinks a good share of their coffee
with milk. Curious about what else is out there and wary of spending on the wrong
thing.

**This is who we design for.** Note how much of that paragraph the previous version
of this document assumed away.

### Secondary — "Filter Coffee Native"
Grew up on South Indian filter kaapi and makes it well by feel. Curious about
specialty, but every resource assumes black coffee, a burr grinder, and vocabulary
they've never needed. We serve them by treating filter coffee as a first-class
method rather than a curiosity, and by never implying that the way they already
make coffee is the wrong way.

### Explicit non-user
Café professionals and roasters. Their needs — shot logging at volume, refractometry,
green inventory, staff training — pull toward a different app and would ruin the
counter-side simplicity the primary user needs.

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

The exploration loop has a *different* context — a couch, a commute, a phone held
close, full attention — and should not inherit these constraints. The Method
Explorer is reading; the guided brew is doing.

---

## 6. Goals & success metrics

**North star:** *% of users who reach 5 logged brews on a single method within 30
days.* One number, and it measures the handoff — whether exploration is converting
into mastery. Neither loop alone tells you that.

| Goal | Metric | Target (first 90 days post-launch) |
|---|---|---|
| **The handoff** | % of users with ≥ 5 logged brews on one method within 30 days | **≥ 25%** |
| Exploration starts | % of new users who open ≥ 3 method overviews in week 1 | ≥ 60% |
| Exploration converts | % of new users who log a brew within 24h of install | ≥ 45% |
| Breadth is real | Median distinct methods *tried* per user by day 30 | ≥ 3 |
| The mastery loop is trusted | % of brews where the suggested adjustment was applied next time | ≥ 40% |
| The mastery loop works | Median rating of brews 8–10 vs brews 1–3, same user, same method | +0.6 stars |
| Learning is ambient | % of concept opens originating in context, not the Learn tab | ≥ 50% |
| Retention | D30 retention | ≥ 20% |

*Secondary:* brews logged per weekly active user — the old north star, kept because
it's the fastest signal that something has broken.

**Counter-metrics (things we must not break):**
- Median time to complete the post-brew log: **≤ 30 seconds**, and this does not get
  a budget increase for milk or water. If logging feels like data entry, the mastery
  loop dies at step 2. This remains the single most fragile point in the product.
- Guided-brew abandonment (started timer, never finished): **≤ 15%.**
- Cold start to a tappable brew: **≤ 1.2s.**
- **Tier-3 dead ends:** % of Method Explorer sessions ending on a reference method
  with no onward action. If browsing routinely terminates in "you can't do anything
  with this here", the explorer is a brochure.

---

## 7. Scope — support tiers, not a method count

The old MVP argument — *one method, prove the loop* — is retired. It was right for
the bet it was testing and wrong for this one. Breadth is now the acquisition
strategy, so the scope question changes from *how many methods* to **how deeply each
one is supported**.

Full tier definitions and the current assignment live in
[`07-repositioning-brief.md` §2](07-repositioning-brief.md). In short:

| Tier | User gets | Cost |
|---|---|---|
| **1 — Full** | Recipes, guided timer, log, **full diagnosis + one adjustment** | High — its own rule table, and expert review |
| **2 — Guided** | Recipes, guided timer, log, **method-level advice** | Medium — recipes and timings |
| **3 — Reference** | An honest overview card. No timer, no logging. | Low — content only |

This is what makes breadth affordable. A method costs a paragraph unless it earns
more, and **a method never implies precision the engine doesn't have** — that's the
rule the tiering exists to enforce.

### Still in scope, unchanged

Guided timer with Live Activity and cues · the diagnosis engine · concept cards ·
bean shelf with roast-level-aware freshness · journal with planned-vs-actual ·
grinder calibration · offline-first, local-only, no accounts.

### Newly in scope

Method Explorer · support tiers · water source as a diagnosis gate · the milk flag ·
progressive disclosure driven by logged brew count · Indian roasters and gear in all
examples and defaults.

### Out of scope — unchanged

| Deferred | Why |
|---|---|
| Insights / trends dashboard | Needs data density we won't have at launch |
| Compare two brews side by side | The diagnosis already does the comparing |
| Community / shared recipes | Moderation, accounts, content strategy. Separate initiative. |
| Apple Watch app | Genuinely solves the wet-hands problem, but not before the phone loops work |
| CloudKit sync | Local-first at launch |
| Refractometry / TDS input | Not our user |
| Water calculators, mineral profiles | Explicitly out — see `07` §4. The water *question* is in; the water *feature* is not. |
| A beginner/advanced mode selector | Explicitly out — see `07` §6. Progressive disclosure instead. |
| Video lessons | Text and illustration first. Video is a production commitment. |

### v1 is done when…

A new user can install, browse a dozen brewing methods and understand what each one
is for, brew one of them with the guided timer without owning a grinder, log the
result in under 30 seconds, get advice honest to that method's tier, and — if they
come back to the same method — start converging on a cup they like. **Entirely
offline, one-handed, without reading a manual.**

---

## 8. What we're deliberately not doing

- **Not a social app.** No feed, no follows, no likes. The feedback loop is with
  your own past cups.
- **Not a marketplace, and not an affiliate funnel** — but *not silent about gear
  and roasters either.* This changed. Pointing outward is allowed at a **triggered
  moment**: when a bag crosses its freshness window or is running out, when a lesson
  ends, when a method you've been reading about needs a piece of kit you don't own.
  Never as a browsable directory, never as a persistent surface.
  The reasoning: a directory makes us a shop, and a shop can't be trusted to teach.
  A single well-timed pointer, after we've already delivered something, reads as
  help. The difference is entirely in the timing, which is why the rule is about
  *when* rather than *whether*.
  **Write the affiliate policy now**, while there is no money in it. A rule set
  before the temptation exists is the only kind that holds.
- **Not gamified with streaks and badges as the primary motivator.** The motivator
  is that the coffee gets better and you can taste it. The exploration loop's shelf
  of methods tried is a record, not a streak — it never breaks, and it never nags.
- **Not comprehensive in depth.** Broad in *coverage*, narrow in *claims*. A method
  we can only describe gets described. That is the whole point of Tier 3.

---

## 9. Next step

1. **OQ-1 is now more blocking, not less.** Two full rule tables means twice as much
   coffee advice that a roaster hasn't checked. See `05`.
2. **Resolve the milk-axis question** (`05`, A16). Milk doesn't only suppress rules —
   it invalidates one of the two axes the log screen asks about, which changes the
   log UI and caps how far a milk-first method can be promoted.
3. **Prototype the brew timer at an actual sink.** Unchanged, and still the thing
   most worth doing before anything else.
