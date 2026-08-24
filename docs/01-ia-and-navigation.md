# Information Architecture & Navigation

Run through the IA rigor sequence as a **forward-looking design brief**, not an
audit — the structure is being decided here, so each check is a decision with a
recorded rationale rather than a flaw found.

---

## 1. Mental model

> **Dominant organizing logic: mode of engagement.**
> Two "doing" modes (Brew, Learn) and two "my stuff" collections (Beans, Journal).

Rejected alternatives, and why:

| Model | Would look like | Why rejected |
|---|---|---|
| By object type | Recipes / Lessons / Beans / Brews | Puts a 3-recipe library on equal footing with a 40-lesson course. Mirrors the database, not the user's day. |
| By workflow stage | Prepare / Brew / Evaluate / Improve | Faithful to the loop but nobody navigates by stage — they navigate by intent. "Evaluate" is not a place you go. |
| Single home + drill-down | Today → everything | Collapses to a Dashboard. See naming smells below. |

The mental model is *mixed* (activity + collection) and that is a deliberate,
logged choice — see Check 2.

---

## 2. Navigation structure

**Pattern:** standard iOS `TabView`, 4 tabs. Profile/Settings is **not** a tab.

```
Tab bar
├── Brew        (cup icon)        — the launchpad; default tab
├── Learn       (book icon)
├── Beans       (bag icon)
├── Journal     (list icon)
└── ⌂ Profile — top-right avatar button, present on all four tab roots
```

**Modal / global layers** (reachable from anywhere, belonging to no tab):
- **Concept Card** — bottom sheet, medium detent. The single most important
  navigation object in the app.
- **Guided Brew** — full-screen cover, dismisses the tab bar. You are *in* a brew,
  not browsing.
- **Global search** — search field on Brew and Learn roots; searches recipes,
  lessons, concepts, beans and brews in one result list.

### Why 4 tabs and not 5

Profile/Settings is low-frequency (units, gear, subscription, export). It does not
deserve 20% of the most valuable real estate on screen. It gets one canonical home
— a Profile screen pushed from the avatar button — reachable identically from every
tab root, so there is exactly one path and no ambiguity about where settings live.

### Why "Brew" is the default tab

The primary job is *"I'm at the counter, help me make coffee now."* Opening to a
content library or a dashboard makes the user do a navigation step before the app
does anything for them. Brew opens with "Brew again: V60, Ethiopia Guji, grind −1"
as a single tap.

---

## 3. Naming review

| Item | Name | New user reads it as | Strong alternative | Verdict |
|---|---|---|---|---|
| Tab 1 | **Brew** | "make coffee" | *Recipes* | **Keep.** "Recipes" implies browsing; the tab's job is starting. |
| Tab 2 | **Learn** | "lessons / study" | *Academy*, *School*, *Guide* | **Keep.** "Academy" oversells; "Guide" reads as reference not course. |
| Tab 3 | **Beans** | "my bags of coffee" | *Coffees*, *Shelf*, *Pantry* | **Keep.** "Shelf" is cute and ambiguous. "Coffees" collides with "cups of coffee". |
| Tab 4 | **Journal** | "my brew history" | *Log*, *History*, *Brews* | **Keep**, with a flag — see below. |
| Sheet | **Concept Card** | (internal name) | — | Internal only; user never sees the label. |
| Screen | **Brew Setup** | "check settings before starting" | *Prepare* | Keep. |
| Screen | **Next Time** | "what to change" | *Diagnosis*, *Analysis* | **Keep "Next Time."** "Diagnosis" is clinical and implies you did something wrong. "Next Time" is forward-facing and matches the actual job. |

### Flags and deliberate violations

**🚩 Mixed grammatical mode at one nav level.** `Brew` and `Learn` are verbs;
`Beans` and `Journal` are nouns. This is a recognised IA smell.

*Logged as a deliberate choice.* An all-noun set costs us the strongest label in
the app (`Brew`), and there is no good noun for the Learn tab — `Lessons` is
narrower than the content, `Academy` is grandiose. An all-verb set (`Brew / Learn /
Stock / Log`) makes the collections read as actions, which is worse. The split is
also semantically real: the verbs are things you do *now*, the nouns are things you
*have*. **Action: validate in a card sort before build.** If users hesitate on the
tab bar in testing, the fallback is `Brew / Learn / My Coffee` (3 tabs, Beans and
Journal as segments inside).

**✅ Junk drawers avoided.** No `Dashboard`, no `Tools`, no `More`, no `Resources`.
The ratio calculator — the classic candidate for a `Tools` tab — lives inside Brew
where it's used, and inside Brew Setup where it's needed.

**⚠️ "Settings" scope check.** Profile mixes user-level (units, appearance) with
equipment (grinders, brewers) and account (subscription, export). Equipment is not
a setting — it's an object the user owns that affects brewing math. **Decision:**
Profile has a distinct `My Gear` section styled as a collection, not a settings
list, so grinders read as things you own rather than preferences you toggle.

---

## 4. Hierarchy justification

| Parent → Child | Justified? | Rationale |
|---|---|---|
| Brew → Method Detail | ✅ | Methods are how recipes are grouped; you pick a device before a recipe |
| Method Detail → Recipe Detail | ✅ | A recipe only means anything within a method |
| Recipe Detail → Brew Setup → Guided Brew | ✅ | Three genuine stages: choose → configure → execute. Setup is skippable via "Brew again" which jumps straight to Guided Brew with last-used values. |
| Guided Brew → Log Brew → Next Time | ✅ | Strictly sequential; each depends on the previous. Log is dismissible; Next Time is not reachable without a log (by design — no taste input, no diagnosis). |
| Learn → Course → Lesson → Quiz | ✅ | Standard, and 3 levels is the ceiling |
| Learn → Concept Library → Concept | ⚠️ **Promote.** | Concepts are level-2 in the Learn tab *and* globally reachable as a sheet from anywhere. This is intentional multi-homing — see Content Model. The Learn-tab route exists for deliberate browsing; the sheet route exists for in-context lookup. |
| Beans → Bean Detail → Brews with this bean | ✅ | Filtered view of Journal, not a duplicate store |
| Journal → Brew Detail | ✅ | |
| Journal → Insights | ⚠️ | v1.1. Currently a segment inside Journal, not a child screen — it's a different view of the same data, not a sub-object. |

**Nothing exceeds 3 levels of depth.** Anything that wanted a 4th level is either
a sheet (Concept Card) or a filter of an existing list (brews-by-bean).

**Promotion check — is anything at level 1 actually a feature of something at
level 2?** `Beans` is arguably a supporting object for brewing rather than a
destination. Kept at level 1 because it has a real standalone job: *"I'm in a coffee
shop deciding what to buy — what did I like?"* That job happens away from the
counter, with no brew in flight, and burying it under Brew would make it unreachable
in that moment.

---

## 5. Edge-case navigation

| State | Design decision |
|---|---|
| **Empty — brand new user** | Tabs are all visible, never hidden or disabled. Each empty state does one job and offers one action. Journal: *"Your brews will land here. Your first one is 4 minutes away."* → [Start a brew]. Beans: *"Add the bag on your counter."* → [Add bean]. Learn is never empty (courses ship with the app). Hiding tabs to "reduce clutter" teaches the wrong model of the app on day one. |
| **Empty — no beans, user starts a brew** | Brew Setup's bean field is optional and reads *"Not tracking this one"*. Never block a brew on inventory data. Post-brew, offer once: *"Want to save this coffee?"* |
| **Interrupted brew** | Timer is a Live Activity; it survives lock, backgrounding, and calls. If the app is force-quit, on relaunch: *"You had a brew running — finished it?"* → [Log it] / [Discard]. Never silently lose a brew in progress. |
| **Deep link** (from a lesson's "try this" CTA, a share, or a widget) | Lands on the target with a synthesised back-stack to its tab root, so Back is never a dead end. A deep link into a Recipe pushes onto Brew with Method Detail beneath it. |
| **Concept Card from a deep context** | Opens as a sheet *over* whatever you're doing — including mid-brew — and dismisses back to exactly where you were. The timer keeps running underneath and stays visible in the Dynamic Island. Reading about bloom must never cost you the brew. |
| **Search arrival** | Results are grouped and labelled by type (Recipe · Lesson · Concept · Bean · Brew) so the user knows what kind of thing they're about to open. Opening a result pushes into its home tab with a real back-stack. |
| **Locked / paid content** | Locked items are **visible but marked**, never hidden. A locked method shows in the Brew grid with a lock badge; tapping explains what it is and what it costs. Hiding paid content means users never learn the app has it. |
| **Content load failure** (remote lesson update fails) | The app ships with the full v1 content bundle on-device. Remote updates are additive and failure is silent — the user sees the bundled version, never an error, never a spinner. |
| **Data corruption / migration failure** | Journal is the irreplaceable object. Export-to-CSV/JSON is available offline from Profile at all times, and a local backup is written before any schema migration. |

---

## 6. Role variants

**One role.** Single-user, local-first, no accounts in v1. There is no admin, no
sharing, no permissions model.

Two *state* variants that behave like roles:

| Variant | What changes |
|---|---|
| **Free vs Pro** | Locked-but-visible items (see above). No structural difference — same tabs, same hierarchy. Deliberate: a paywall that reshapes the IA makes upgrading feel like moving to a different app. |
| **Onboarded vs not** | Onboarding is a full-screen flow before the tab bar exists, run once. Not a variant of the IA — a gate in front of it. Skippable, and skipping produces sensible defaults (V60, generic grinder, standard recipe) rather than a broken state. |

*If accounts and sync arrive in v1.1, revisit this section — it is the most likely
place for the model to break.*

---

## 7. Content model integrity (summary)

Full model in [`02-content-model.md`](02-content-model.md). The IA-relevant findings:

**Core objects:** Method, Recipe, Brew, Bean, Lesson, Course, Concept, Grinder,
Descriptor.

**Multi-homed objects — all deliberate:**

| Object | Homes | Intentional? |
|---|---|---|
| **Concept** | Learn → Concept Library (canonical), plus a sheet from any inline reference anywhere in the app | ✅ **This is the point.** The Concept layer is the spine that makes learning ambient. One canonical record, many entry points, one presentation. |
| **Brew** | Journal (canonical), Bean Detail (filtered), Recipe Detail ("your brews with this recipe") | ✅ Filtered views of one store, not copies |
| **Recipe** | Method Detail (canonical), Brew tab recents, Journal → "brew again" | ✅ |

**No object appears under two different labels.** A Brew is called a brew
everywhere; it is never "session", "log entry", or "cup" in different screens.
Vocabulary discipline is a shipping requirement, not a style preference.

**Scaling test — where does a new object type go in six months?**

| New object | Fits? |
|---|---|
| New brew method (AeroPress) | ✅ Slots in as a Method. Zero IA change. This is the primary planned growth axis and the model handles it cleanly. |
| Espresso shots | ⚠️ **Conditionally.** A shot is a Brew with different variables (pressure, yield, ratio 1:2 not 1:16) and a different diagnosis table. The Brew object needs a method-specific parameter bag from day one, or espresso forces a migration. **Design for this now even though espresso is out of scope.** |
| Roaster / café directory | ❌ No home. Would need a 5th tab or to live under Beans. Flag if it ever gets proposed. |
| Community recipes | ⚠️ Fits under Method Detail as a segment (`Built-in | Mine | Community`), but brings accounts and moderation. Structural room exists; the cost is elsewhere. |
| Water chemistry profiles | ✅ Under Profile → My Gear, alongside grinders |

---

## 8. Top 3 IA risks

1. **The espresso-shaped hole.** `Brew` is currently modelled around pour-over
   variables. If those are stored as fixed columns rather than a method-scoped
   parameter set, adding espresso means a data migration and a rewrite of the
   journal, the diagnosis engine, and every brew view.
   → *Model Brew with a typed, method-scoped parameter bag in v1, even though v1
   only ships one method.*

2. **`Beans` may not earn a tab.** It's the thinnest of the four and the most
   likely to see low engagement. If usage data shows it's rarely opened outside
   Brew Setup, the honest move is to demote it to a segment inside Journal and
   spend the tab on Insights.
   → *Instrument tab-open rates from day one so this is a data decision, not a
   debate.*

3. **The mixed verb/noun tab bar.** Low-cost to be wrong, but only if caught
   early — renaming tabs after launch confuses existing users.
   → *Card-sort with 8–10 target users before build. One afternoon.*

## 9. Quick wins

- Lock the object vocabulary now (Brew, Bean, Recipe, Method, Concept) and put it
  at the top of the design file. Prevents "session"/"log"/"cup" drift in mockups.
- Write every empty state before designing any populated state. Empty is the first
  thing every user sees and the last thing anyone designs.
- Name the Live Activity copy early — it's the app's most-seen surface after the
  timer itself and it's 40 characters of real estate.
