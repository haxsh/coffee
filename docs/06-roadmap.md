# Phasing

Phases are gated on **evidence**, not on calendar. Each gate is a question that has
to be answered yes before the next phase starts.

> Rewritten to the build order in [`07-repositioning-brief.md` §8](07-repositioning-brief.md).
> The old phasing — one method, prove the loop, then add breadth — is retired along
> with A6.

---

## Phase 0 — De-risk *(before production work)*

Cheapest possible tests of the things that could kill the product. The list grew with
the repositioning, and two of the new items are cheaper than anything already on it.

| Work | Answers |
|---|---|
| **Diary study, 8–10 target users, 30 days** — do people actually settle on a method, or hop indefinitely? | **A14** — the two-loop framing itself |
| **Grinder-ownership survey** in Mumbai / Bangalore / Pune | **A5** — whether tier 1 diagnosis has its main lever |
| Rule tables + the 70:30 water claim reviewed by a Q-grader or roaster | A8, A17 / OQ-1 |
| Static Explorer mockup shown to 8 users: what does "Learn about this" mean to you? | A15 — does tiering read as honest or crippled |
| Throwaway prototype of **S06 Log Brew only**, with the milk toggle, in real kitchens | A1, A16, and the 30-second budget |
| Live Activity behaviour spike — real call, Low Power Mode, Focus | A7 |
| Card sort of the tab bar, now also testing whether Explore and Brew read as one place | The verb/noun flag, and the Brew tab's two states |

**Gate:** Do people settle on a method within a month, and do ≥ 80% of them log a
brew with a 30-second form? A "no" on the first question means the two-loop model
describes nobody, and that is worth knowing before building for it.

---

## Phase 1 — Breadth, honestly *(steps 1–3)*

Make the app wide before making it deep. This is the acquisition half.

1. **`supportTier` on `BrewMethod` + tier-aware gating**, enforced in the engine as
   well as the UI. Unblocks everything else.
2. **Tier 3 content for every listed method.** The cheapest breadth available and
   immediately visible to a user.
3. **Method Explorer** in the Brew tab, with the shelf.

**Gate — is breadth working?**
- ≥ 60% of new users open ≥ 3 method overviews in week 1
- Tier-3 dead ends are not the majority of Explorer sessions
- Tiering reads as honest in testing, not as a paywall

If browsing routinely ends in "you can't do anything with this here", the answer is
to **promote a method, not to add another.**

---

## Phase 2 — The tier model's real test *(step 4)*

4. **French press to Tier 1** — a second full rule table.

This phase exists to answer one question, and it is deliberately a phase of its own
rather than a task inside another: **does the tier model generalise, or was it
shaped around V60 by accident?**

**Gate — A21.** If authoring the second rule table is painful, or if it needs an
expert per method rather than an expert per release, the breadth strategy needs
rethinking. **Do not start Phase 4 before this is green.** Finding this out at two
methods costs a week; finding it out at seven costs the roadmap.

---

## Phase 3 — Honesty features *(steps 5–6)*

5. **Water question + diagnosis gate + concept card.** Cheap to build, and the most
   distinctive single thing the app says to this market.
6. **Milk flag + axis swap + rule suppression + concept card.** Load-bearing: without
   it, every milk drink is confidently misdiagnosed.

Both are gates on the engine rather than features on top of it, which is why they
come after the engine has been proven to generalise and before more methods are
poured into it.

**Gate:** Median log time on milk methods still ≤ 30s. If the milk toggle costs the
budget, it moves into the actuals disclosure rather than the log getting slower.

---

## Phase 4 — Tier 2 methods *(step 7)*

7. **AeroPress, moka pot, South Indian filter** at Tier 2.

Blocked on Phase 2. South Indian filter is the most defensible thing in the list and
should be built with the most care — it is the one no competitor has, and the one
where getting the tone wrong (treating a way people already make coffee as a
curiosity) does real damage.

---

## Phase 5 — Depth *(step 8, then the mastery loop's own backlog)*

8. **Progressive disclosure driven by logged brew count.**

Then the retention half: Insights (now that there is data density), the recipe
editor, Apple Watch, sync, bag-label scanning.

**Gate — the north star.** ≥ 25% of users reaching 5 logged brews on a single method
within 30 days. This is the handoff working. If it isn't, the answer is not more
methods and not more features — it is finding out where between exploring and
settling people fall out.

---

## Later, and deliberately unscheduled

- **A second diagnosis model for milk-first drinks** (OQ-9). Would unlock South
  Indian filter, moka-with-milk and eventually espresso at Tier 1 together — which is
  what makes it worth doing as one piece rather than three.
- **Espresso**, as its own initiative. Different variables, different model,
  different behaviour. Needs its own brief. The v1 data model is built so this is an
  addition rather than a migration; that remains the only espresso work in scope.
- Chemex, siphon, cezve promotions — only if usage justifies the authoring cost.

---

## Deliberately never (unless the strategy changes)

Social feed · a browsable gear or roaster marketplace · café/roastery pro tooling ·
streak-based gamification as the primary motivator · a beginner/advanced mode
selector.

Note the change from the previous version: pointing outward at roasters and gear is
now allowed **at a triggered moment** — a bag going stale, a lesson ending — but
never as a directory. See `00` §8. The rule is about *when*, not *whether*.
