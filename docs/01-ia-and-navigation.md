# Information Architecture & Navigation

> Updated by [`07-repositioning-brief.md`](07-repositioning-brief.md): the Brew tab
> gains a browse state (the Method Explorer), and the hierarchy justification is
> re-run below with a dozen methods in play instead of one. **Four tabs stay four.**

Run through the IA rigor sequence as a **forward-looking design brief**, not an
audit — the structure is being decided here, so each check is a decision with a
recorded rationale rather than a flaw found.

---

## 1. Mental model

> **Dominant organizing logic: mode of engagement.**
> Two "doing" modes (Brew, Learn) and two "my stuff" collections (Beans, Journal).

The repositioning tested this model and it held. The obvious reflex — give
exploration its own tab — was rejected: *Explore* and *Brew* are the same mode of
engagement at two moments in one person's life, and splitting them would have made
the tab bar encode the product's roadmap instead of the user's intent. The two loops
are a **sequence through the Brew tab**, not two places.

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
├── Brew        (cup icon)        — default tab; two states, one root
│   ├── Continue state   ── you have brewed before → "Brew again", your methods
│   └── Explore state    ── you have not, or you tapped Explore → Method Explorer
├── Learn       (book icon)
├── Beans       (bag icon)
├── Journal     (list icon)
└── ⌂ Profile — top-right avatar button, present on all four tab roots
```

**The Brew root has two states, not two screens.** A user with no brews opens onto
the Method Explorer, because there is nothing to continue. A user with history opens
onto Continue, with the Explorer one tap away and always visible — never buried, and
never a modal. The state is a consequence of the user's own history, which is exactly
what the two-loop model predicts: exploration is where you start, mastery is where
you end up, and the tab quietly follows you across.

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

For a user with no history that job doesn't exist yet, and their actual first
question is *"what should I even try?"* — which is why the same tab opens onto the
Explorer instead. Same tab, same intent, different answer depending on what the app
knows about you.

---

## 3. Naming review

| Item | Name | New user reads it as | Strong alternative | Verdict |
|---|---|---|---|---|
| Tab 1 | **Brew** | "make coffee" | *Recipes* | **Keep.** "Recipes" implies browsing; the tab's job is starting. |
| Tab 2 | **Learn** | "lessons / study" | *Academy*, *School*, *Guide* | **Keep.** "Academy" oversells; "Guide" reads as reference not course. |
| Tab 3 | **Beans** | "my bags of coffee" | *Coffees*, *Shelf*, *Pantry* | **Keep.** "Shelf" is cute and ambiguous. "Coffees" collides with "cups of coffee". |
| Tab 4 | **Journal** | "my brew history" | *Log*, *History*, *Brews* | **Keep**, with a flag — see below. |
| Sheet | **Concept Card** | (internal name) | — | Internal only; user never sees the label. |
| Screen | **Method Explorer** | (internal name; surfaces as "Explore") | *Browse*, *Discover*, *All methods* | **"Explore" in the UI.** *Browse* is what you do in a shop; *Discover* is marketing's word for a feed. *Explore* is the only one that promises the user does the choosing. |
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
| Brew → Explore (Method Explorer) | ✅ | A sibling state of the same root, not a child screen. Reachable in one tap from Continue and vice versa; neither is "inside" the other. |
| Explore → Method Detail | ✅ | The Explorer's whole job is routing to one of these |
| Brew → Method Detail | ✅ | Methods are how recipes are grouped; you pick a device before a recipe |
| Method Detail → Recipe Detail | ✅ | A recipe only means anything within a method. **Tier 3 methods have no children here** — see below. |
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

### Re-run: does the hierarchy survive a dozen methods?

The original model was justified against one method, where "Brew → Method → Recipe"
was almost a formality. With twelve it is doing real work, so it gets re-checked.

**What holds.** Depth does not increase. A method is still level 2 and a recipe
still level 3, whether there are three methods or thirty. Adding a method is a row,
not a level — which is exactly the property the content model was designed for.

**What changes: the tree is no longer uniform.** A method's tier decides how far
down you can go, and the same parent now has children of three different shapes:

| Tier | Method Detail contains | Depth reached |
|---|---|---|
| 1 | Overview, recipes, start a brew, full diagnosis afterwards | 3 |
| 2 | Overview, recipes, start a brew, method-level advice afterwards | 3 |
| 3 | Overview only — what it is, what it tastes like, what it costs | **2, and it stops there** |

**A ragged tree is the honest shape here**, and flattening it would be the error.
The alternative — give Tier 3 methods empty recipe lists so every branch looks the
same — teaches the user that some methods are broken rather than that some are
described-not-supported. **The IA should express the difference, not hide it.**

**The cost, stated plainly:** Tier 3 is a leaf. A user who taps into cold brew from
the Explorer has reached the end of that branch. That is legitimate for a reference
card, but it becomes a dead end if the card offers nothing onward, which is why
tier-3 dead-ends are a tracked counter-metric in `00` §6 and why every reference card
must end in a route back into the Explorer ("methods like this one you *can* brew").

**Sorting is now an IA decision, not a display detail.** With twelve methods, the
Explorer's default order *is* the app's opinion about what to try next. It is not
alphabetical and it is not tier-first — leading with the fully-supported methods
would read as a paywall. Default order is **what this user is most likely to be able
to make today**, given the gear they told us about in onboarding.

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
| **Locked / paid content** | Locked items are **visible but marked**, never hidden. A locked method shows in the Explorer with a badge; tapping explains what it is and what it costs. Hiding paid content means users never learn the app has it. |
| **Tier 3 leaf** | The branch genuinely ends. The card says so in plain words — *"we can tell you about this one, but we can't coach you through it yet"* — and offers a route onward to two methods the user *can* brew. Never a disabled Start button: a greyed control reads as broken, while an absent one with an explanation reads as honest. |
| **Tier 2 after a brew** | The user gets method-level advice, visibly different in shape from a Tier 1 diagnosis — no "the one change" card, no from → to numbers. **A Tier 2 method must never look like it diagnosed you.** Borrowing Tier 1's layout would be the single most damaging thing tiering could do to trust. |
| **Explorer with no gear known** | A user who skipped the gear question sees every method, ordered by forgiveness rather than by what they own, with a one-tap "tell us what you have" that re-sorts. Never an empty state — the Explorer is content, and content is never empty. |
| **Method tried, then abandoned** | The shelf records the attempt, permanently and without judgement. There is no "incomplete" state and nothing decays. It is a record of what you've done, not a checklist of what you owe. |
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
Descriptor — plus, after the repositioning: **SupportTier** (an attribute of Method
that gates how deep its branch goes), **WaterSource** and **withMilk** (attributes of
a Brew that gate which diagnosis rules may fire), and **MethodsTried** (derived from
the journal, not stored — see below).

**Multi-homed objects — all deliberate:**

| Object | Homes | Intentional? |
|---|---|---|
| **Concept** | Learn → Concept Library (canonical), plus a sheet from any inline reference anywhere in the app | ✅ **This is the point.** The Concept layer is the spine that makes learning ambient. One canonical record, many entry points, one presentation. |
| **Brew** | Journal (canonical), Bean Detail (filtered), Recipe Detail ("your brews with this recipe") | ✅ Filtered views of one store, not copies |
| **Recipe** | Method Detail (canonical), Brew tab recents, Journal → "brew again" | ✅ |
| **Methods tried** | Explorer (as the shelf), Method Detail (as "you've made this") | ✅ **Derived, never stored.** It is `Set(brews.map(\.methodID))` — a projection of the journal. Storing it separately would create a second source of truth that could disagree with the journal after a delete, and the first bug report would be "it says I tried Chemex and I never did." |

**No object appears under two different labels.** A Brew is called a brew
everywhere; it is never "session", "log entry", or "cup" in different screens.
Vocabulary discipline is a shipping requirement, not a style preference.

**Scaling test — where does a new object type go in six months?**

| New object | Fits? |
|---|---|
| New brew method (AeroPress) | ✅ **Confirmed by the repositioning.** Twelve methods slotted in as rows with zero IA change — this was the model's main claim and it survived being tested at scale rather than argued at one. |
| A method with no timer (cold brew, instant) | ✅ Tier 3 handles it. The reason this works is that tiering is an attribute of the Method rather than a separate kind of object — a reference method is the *same* type with a shallower branch, so nothing in the IA has to special-case it. |
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
   → *Card-sort with 8–10 target users before build. One afternoon.* The card sort
   should now also test whether *Explore* and *Brew* read as one place or two.

4. **Tier 2 borrowing Tier 1's clothes.** The highest-consequence *new* risk. If
   method-level advice is rendered in the same card as a real diagnosis, the app
   quietly claims a precision it does not have — on the majority of its methods.
   Every trust argument in `00` depends on not doing this.
   → *Design the Tier 2 advice surface first and separately, before reusing a single
   component from Next Time.*

5. **The Explorer becomes a brochure.** Twelve reference cards and two brewable
   methods is a Wikipedia category page with a tab bar. Breadth has to route back
   into doing.
   → *Track tier-3 dead ends from day one (`00` §6). If most Explorer sessions end
   on a reference card, promote a method rather than adding another.*

## 9. Quick wins

- Lock the object vocabulary now (Brew, Bean, Recipe, Method, Concept) and put it
  at the top of the design file. Prevents "session"/"log"/"cup" drift in mockups.
- Write every empty state before designing any populated state. Empty is the first
  thing every user sees and the last thing anyone designs.
- Name the Live Activity copy early — it's the app's most-seen surface after the
  timer itself and it's 40 characters of real estate.
