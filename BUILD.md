# Getting this running

Everything in this repo was written without a Mac, an Xcode, or a Swift
compiler. CI builds it on a real Mac on every push
(`.github/workflows/ios.yml`) — **currently green**: the app and widget extension
compile for the Simulator, and all 88 domain tests pass.

So it builds. What nobody has done yet is *run* it, which is what needs you.

Below is the whole list of what only you can do.

---

## 1. Your machine — about an hour, mostly downloading

| Step | What | Notes |
|---|---|---|
| 1 | **Install Xcode** from the Mac App Store | ~10 GB. Needs a recent macOS — if the App Store says your macOS is too old, update macOS first. Xcode itself is free. |
| 2 | **Open Xcode once** and let it finish | It installs command-line tools and iOS platform support on first launch. Accept the licence when prompted. |
| 3 | **Install Homebrew** | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` |
| 4 | **Install XcodeGen** | `brew install xcodegen` |
| 5 | **Sign in to Xcode** with your Apple ID | Xcode → Settings → Accounts → **+**. A free Apple ID is enough to run on the Simulator. |

You need Xcode 16 or newer for the iOS 18 SDK. Anything the App Store gives you
today is newer than that.

---

## 2. Build it

```bash
git clone https://github.com/haxsh/coffee.git
cd coffee
git checkout claude/coffee-learning-recipe-app-rtyv9s

xcodegen generate          # writes Grind.xcodeproj from project.yml
open Grind.xcodeproj
```

Then in Xcode: pick an iPhone simulator in the toolbar and press **⌘R**.

Before the first run you'll need to set your team:
- Select the **Grind** target → *Signing & Capabilities* → **Team**
- Do the same for the **GrindWidgets** target

Or set it once in `project.yml` (`DEVELOPMENT_TEAM`) and re-run `xcodegen generate`.

**Run the tests with ⌘U**, or without Xcode at all:

```bash
swift test --package-path Packages/CoffeeKit
```

Those tests cover the whole diagnosis rule table, the grinder mapping, the brew
maths and every concept link. They're the reason the domain layer is a separate
package.

---

## 3. Seeing the widgets

**In the Simulator** — everything works, including the App Group, with a free
Apple ID:

- **Home screen widgets** — long-press the home screen → **+** → search *Grind*.
  You'll get *Brew again* and *Bean freshness*.
- **Lock Screen widget** — Settings → Wallpaper → Customise → Lock Screen, then
  add *Bean freshness* to the widget row.
- **Control Centre** — swipe down from the top-right → **+** → search
  *Start a brew*.
- **Live Activity + Dynamic Island** — start a brew, then lock the screen or
  swipe to the home screen. Use an iPhone 16 Pro simulator to see the Dynamic
  Island; the Live Activity appears on any of them.

Widgets read a small JSON file the app writes to the shared App Group container
on every change, so brew something first — an empty snapshot renders the empty
state, which is correct but not very interesting.

---

## 4. Running on your actual phone

This is where it stops being free.

**App Groups require a paid Apple Developer Program membership ($99/year).**
Free "personal team" provisioning does not include the App Groups capability, and
App Groups is how the widgets read your data. On a physical device with a free
account the build will fail to provision.

Your options:

| Option | What you get |
|---|---|
| **Stay on the Simulator** | Everything works, including all four widgets. Free. Fine for building and reviewing. |
| **Join the Developer Program** | Device builds, TestFlight, and eventually the App Store. Enrol at developer.apple.com. Takes 24–48 hours to approve. |
| **Device without App Groups** | Remove the App Group from both `.entitlements` files. The app runs; the widgets show placeholder data. Not recommended — it hides the thing you asked for. |

---

## 5. Making it yours

The bundle identifier and App Group appear in **four** places and must match.
Change them together:

| File | What to change |
|---|---|
| `project.yml` | `bundleIdPrefix`, and `PRODUCT_BUNDLE_IDENTIFIER` on both targets |
| `Grind/Grind.entitlements` | the `group.…` string |
| `GrindWidgets/GrindWidgets.entitlements` | the same `group.…` string |
| `Packages/CoffeeKit/Sources/CoffeeKit/Shared/WidgetSnapshot.swift` | `AppGroup.identifier` |

Then `xcodegen generate` again.

The widget kind strings (`com.haxsh.grind.widget.*`) can stay as they are — they
only have to be unique within the app — but if you rename them after anyone has
installed a widget, their existing widgets go blank.

---

## 6. Working on it from here

`project.yml` is the source of truth; `Grind.xcodeproj` is generated and
git-ignored. That means no pbxproj merge conflicts, and a project anyone can
reproduce — but it also means **adding a file in Xcode isn't enough on its own**
if it lands outside the existing source folders. Files inside `Grind/`,
`GrindWidgets/`, `Shared/` and `Packages/` are picked up automatically; re-run
`xcodegen generate` after adding a new top-level folder.

---

## What's actually built

The whole repositioned product, end to end.

**Exploration loop**
- **Method Explorer** — twelve methods compared on effort, time, gear cost,
  fussiness and what the cup tastes like. Sorted by what you can most likely make
  today, from the gear you told onboarding about.
- **The shelf** — methods you've actually brewed, derived from the journal. It
  can't lapse or break; it's a record, not a streak.
- **Method Detail** — recipes and a brew for the nine you can make; an honest
  overview card plus two onward suggestions for the three you can't.

**Mastery loop**
- Brew setup → **guided timer with Live Activity, audio and haptic cues** → log in
  under 30 seconds → advice → applied automatically to the next brew.
- **Two full rule tables.** V60 reaches for grind first; French press reaches for
  steep time, because immersion is time-dominant.
- **Tier-honest advice.** A guided method gets notes about the brewer and says so;
  it never borrows the diagnosis layout.

**The things that make it work here**
- **Pre-ground is a first-class answer.** You're never told to grind. The engine
  spends temperature, time and ratio instead — and when those run out it tells you
  which brewer your coffee actually suits.
- **Milk swaps the taste axis** rather than suppressing it, on the methods where
  milk is normal. Remembered per method, so it costs zero taps after the first.
- **Water** is one question and one rule that fires once.

**Plus** the bean shelf with roast-level-aware freshness, the journal with
planned-vs-actual, 27 concept cards, CSV/JSON export, and all four widgets.

### What to try first, in order

1. **Onboarding** — pick *I buy it pre-ground* on the grinder screen. Watch what
   changes: the copy, the Explorer's ordering, and later the advice.
2. **The Explorer** — you land here, not on a recipe. Open a reference method
   (cold brew) and check it reads as honest rather than broken.
3. **Brew a French press.** Log it as bitter. You should be told to *steep less*,
   not to grind coarser — that's the second rule table doing something different
   from the first.
4. **Brew a moka pot**, toggle *With milk*, and notice the taste axis changes from
   sour ↔ bitter to harsh ↔ flat. Then check you get **notes about moka pots**, not
   a diagnosis of your cup.
5. **Brew a V60 twice** — apply the adjustment the first time, and see whether the
   second one tells you it worked.

### Deliberately not built

Lesson content (a writing project — OQ-7), the recipe editor, insights, sync, and
promotion of any tier 2 method to tier 1.

## What I still need from you

| # | Decision | Why it's blocking |
|---|---|---|
| 1 | **Someone who knows coffee to review the rule table** (`Packages/CoffeeKit/Sources/CoffeeKit/Diagnosis/DiagnosisEngine.swift`) | The structure is sound; the thresholds are my guesses. Wrong advice is the one mistake this audience won't forgive. Every number is in `DiagnosisThresholds` so it's readable top to bottom. |
| 2 | **A real name** | "Grind" is a placeholder and almost certainly taken on the App Store. |
| 3 | **An app icon** | The slot is there and empty. Xcode warns; it won't block you. |
| 4 | **Whether to pay for the Developer Program now** | Only needed for device builds and TestFlight. The Simulator covers everything else. |

Nothing else is waiting on you. Push a commit and CI will tell us if it builds.
