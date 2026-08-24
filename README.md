# Grind — coffee learning & recipe app for iOS

**Status:** Core loop implemented. Builds clean and all tests pass on CI — see [`BUILD.md`](BUILD.md).
**Working name:** Grind (placeholder — see Open Questions)
**Platform:** iOS 18+, SwiftUI, WidgetKit

A home-brewing app that closes the loop between *making* coffee and *understanding*
coffee. Most tools do one or the other: recipe-and-timer apps tell you what to do
but never why; blogs and videos teach but aren't attached to the cup in your hand;
journal apps record data and give nothing back.

**The core bet:** teaching lands when it arrives at the moment of a bad cup.
Brew → taste → diagnose → adjust → learn → brew again.

## Documents

| Doc | What's in it |
|---|---|
| [`docs/00-product-brief.md`](docs/00-product-brief.md) | Problem, users, the core loop, MVP scope line, success metrics |
| [`docs/01-ia-and-navigation.md`](docs/01-ia-and-navigation.md) | Sitemap, tab structure, naming decisions, IA rigor check, edge-case navigation |
| [`docs/02-content-model.md`](docs/02-content-model.md) | Core objects, relationships, the Concept layer, the diagnosis rule table |
| [`docs/03-screen-specs.md`](docs/03-screen-specs.md) | Screen-by-screen design brief — 29 screens, 3 specced deep |
| [`docs/04-user-stories.md`](docs/04-user-stories.md) | Epics and dev-ready stories with acceptance criteria |
| [`docs/05-assumptions-and-open-questions.md`](docs/05-assumptions-and-open-questions.md) | Assumption log, open questions, risks |
| [`docs/06-roadmap.md`](docs/06-roadmap.md) | Phasing, what ships when, what's deliberately deferred |

## Code

| Path | What it is |
|---|---|
| [`BUILD.md`](BUILD.md) | **Start here.** What you need to install, how to build it, how to see the widgets, and what's still waiting on you. |
| `Packages/CoffeeKit/` | Domain layer — models, brew maths, the diagnosis engine, the concept library. Pure Foundation, no UI, and covered by tests that run with `swift test` on any machine. |
| `Grind/` | The app. SwiftUI, iOS 18+. |
| `GrindWidgets/` | Widget extension: *Brew again*, *Bean freshness*, the brew Live Activity + Dynamic Island, and a Control Centre control. |
| `Shared/` | Compiled into both iOS targets — the Live Activity contract and the App Intents the widgets fire. |
| `project.yml` | The project, as a readable file. `xcodegen generate` builds `Grind.xcodeproj` from it; the pbxproj is not committed. |

```
Brew Setup ─▶ Guided Brew ─▶ Log Brew ─▶ Next Time ─▶ (adjustment pre-filled)
              │  Live Activity          │  ≤30s        │  one change, your units
              │  audio + haptic cues    │  2 axes      │  + a concept card
              └─ survives a locked screen
```

### What's verified

[![iOS](https://github.com/haxsh/coffee/actions/workflows/ios.yml/badge.svg?branch=claude/coffee-learning-recipe-app-rtyv9s)](https://github.com/haxsh/coffee/actions/workflows/ios.yml)

CI runs on a macOS runner on every push and does two things:

- **Builds the app and the widget extension** for the iOS Simulator, from a
  project generated fresh out of `project.yml`.
- **Runs the domain test suite** — 58 tests covering the full diagnosis grid,
  rule ordering, the grinder mapping, brew maths, snapshot persistence, and
  every concept link.

Both are green. What CI *cannot* tell you is whether the guided brew feels right
with wet hands at an actual sink — that's still the thing worth testing first,
and it needs a person and a kettle.

## Read order

If you have 10 minutes: `00-product-brief.md`, then the Core Loop section of
`02-content-model.md`.
If you're designing: `01` → `03`.
If you're building: `02` → `04`.
