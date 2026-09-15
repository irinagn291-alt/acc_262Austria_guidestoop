# Guidestoop — Build Specification

> Portfolio app 57, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Stake the cairn. Drag one road.

| Field | Value |
| --- | --- |
| Product name | Guidestoop |
| Bundle identifier | `com.guidestoop.cairn` |
| Domain | https://guidestoop-cairn.pro |
| Contact URL | https://guidestoop-cairn.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Light |
| Asset prefix | `gds_` |
| User-Agent | `Guidestoop/1.0 (iOS; +https://guidestoop-cairn.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
5. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
6. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
7. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Guidestoop -destination 'generic/platform=iOS' build`.
8. **Nothing may echo another app in this batch** in naming, layout or visuals.
9. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

The gate opens two roads.

### 2.1 User flow

1. Open the waymap and stand on the occupied camp
2. Stake today's chore on that camp, one stake per day
3. Hold the streak until the gate sprouts two forward roads
4. Drag the walker onto one revealed camp; the sibling road seals
5. After five stakes in the week, face the boss for bonus XP

### 2.2 Essential behaviour

- Waymap of camps with a three-day streak gate
- One stake per day on the occupied camp only
- Fork reveal at streak >= 3; commit seals the sibling road
- XP += value; level = 1 + totalXP/100
- Weekly boss after five completions for bonus XP

---

## 3. Uniqueness assignment for Guidestoop

| Axis | Assigned value |
| --- | --- |
| Architecture | **Forking path DAG (streak >= 3 reveals two successors; commit writes one edge and seals the other)** |
| UI approach | **SwiftUI Canvas + MagnifyGesture waymap (cairns are Path; MagnifyGesture pans; drag moves the walker; no representable)** |
| Naming convention | **Waymark / cairn lexicon** |
| File organization | **By path role (Camp, Road, Fork, Seal, Party, Boss)** |
| Dependency strategy | **None** |
| Design direction | **Moorland waymap (peat brown, granite cairn, mist grey, lichen green, iron-gall roads)** |
| Typography | **SF Pro** |
| Navigation pattern | **Waymap-locked chrome (the path never leaves; Journal, Hero and Settings arrive as sheets)** |
| AI art style | **Hand-colored itinerary strip map (vellum, cinnabar cairns, lampblack contour)** |
| Functional twist | **Fork-seal commit (streak reveals two roads; commit picks one and seals the other)** |
| Persistence | **UserDefaults+Codable** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — habit_rpg

**Core** — The gate opens two roads.

**Audience** — People who will do a daily chore if the next camp is a road they pick, not a checkbox that advances itself.

**User flow**

1. Open the waymap and stand on the occupied camp
2. Stake today's chore on that camp, one stake per day
3. Hold the streak until the gate sprouts two forward roads
4. Drag the walker onto one revealed camp; the sibling road seals
5. After five stakes in the week, face the boss for bonus XP

**Essential features**

- Waymap of camps with a three-day streak gate
- One stake per day on the occupied camp only
- Fork reveal at streak >= 3; commit seals the sibling road
- XP += value; level = 1 + totalXP/100
- Weekly boss after five completions for bonus XP

**Twist** — Fork-seal commit. After three consecutive stakes the occupied camp grows a pair of forward roads. A further stake does not pick. The walker must be dragged onto exactly one revealed camp; its sibling road then seals for the rest of this map. Dragging toward a sealed or fogged camp does nothing. The three-day streak still gates the reveal; a day accepts a single stake; yesterday must have been staked or the streak drops; each stake adds XP and level equals one plus totalXP divided by one hundred; five stakes during the week unlock the boss bonus. Journal keeps the chosen road.

**Why this is not a repeat** — Family habit_rpg is absent from the ledger. Home is a waymap whose gate sprouts two roads at streak three; the walker must be dragged onto one camp and the sibling seals. That verb is commit-the-road, not tick-a-quest, close-a-ring, park-a-miss, or log-a-reading-expedition. Invariant holds: one stake per day, streak iff yesterday, reveal at streak >= 3, XP += value, level = 1 + totalXP/100, weekly boss after five stakes. Unique catalogs are exhausted, so eight unique axes are new ASCII values. screens takes the free catalog label Breadcrumb trail screens instead of the occupied No Detail screen that rejected the last draft. Non-unique axes repeat the graph seed (None, SF Pro, UserDefaults+Codable, AVCaptureMetadataOutput, cgi search pl, YYYYMMDD). repeats is empty because no unique axis collides.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: World map. Nodes unlock. Weekly boss.
- Invariant: One completion/day. Streak continues iff yesterday. Unlock next node at streak ≥ 3. XP += value; level = 1 + totalXP/100. Boss: 5 completions → bonus XP.
- Never: Cosmetic skins only. No social server.

### 3.1 Architecture contract

The home graph is a forking path DAG: camps are nodes and roads are directed edges owned by one observable WaymapGraph. A day accepts a single CampStake on the occupied camp only; the streak continues if and only if yesterday was staked, otherwise it drops. When streak is at least three the occupied camp reveals exactly two successor camps; a further stake does not choose a road. Commit is a graph write: dragging the walker onto one revealed camp inserts that edge and seals the sibling for the rest of this map. Each stake adds XP and level equals one plus totalXP divided by one hundred; five stakes in the week unlock the boss bonus. Views call methods on that graph and never keep a forked copy of the path.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

Home is a SwiftUI Canvas. Cairns and iron-gall roads are Path shapes; MagnifyGesture pans the waymap; a drag moves the walker. There is no UIViewRepresentable, no UIKit host, and no TabView. Journal, Hero, and Settings arrive as sheets over the canvas. Empty Map is a full page with generated art, one headline, one line, and one full-width CTA using frame(maxWidth: .infinity, maxHeight: .infinity). Chrome lives inside each Button label with contentShape and a minimum hit of 44pt; buttonStyle is plain. Numbers go through NumberFormatter. Day edges use Calendar.current.startOfDay. One haptic on a successful stake or fork-seal commit, none on opening a sheet. Every icon-only control has a VoiceOver label; a sealed road is marked by a stroke as well as colour. The background fills the safe area. iPad is full screen and portrait.

### 3.3 Naming contract

Convention: Waymark / cairn lexicon.

Examples to follow: `WaymapGraph`, `CampStake`, `ForkSeal`, `dragWalker(to:)`

### 3.4 Dependency contract

None. Zero SPM packages and no CocoaPods; project.yml has no packages key. No AVFoundation capture session, no VisionKit, no Open Food Facts client. Foundation and SwiftUI only.

### 3.5 Navigation contract

The waymap never leaves. Journal, Hero, and Settings arrive as sheets from waymap-locked chrome; there is no tab bar and no pushed detail. After onboarding, read ProcessInfo.processInfo.arguments once: -ReviewScreen today stays on Map, log presents Journal, goals presents Hero. Close dismisses a sheet. Onboarding Next is bottom and full width.

### 3.6 Screen composition contract

Breadcrumb trail screens. The path never leaves; Journal, Hero and Settings are crumbs as sheets. Physical screens: Map (root waymap; ReviewScreen today), Journal (chosen-road log sheet; ReviewScreen log), Hero (level, totalXP, weekly boss; ReviewScreen goals), Settings (sheet; contact URL, re-run onboarding, reset). The weekly boss is an overlay on Map after five stakes, not a destination. Onboarding is a one-shot cover that writes defaults and a completion flag. Empty Map copy: The path is closed. Finish three days to open the next node. No Today, Scan, Search, or Goals screens.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

---

## 4. Target file organization

Scheme: **By path role (Camp, Road, Fork, Seal, Party, Boss)**

```
Guidestoop/
  Camp/
Road/
Fork/
Seal/
Party/
Boss/
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Map
A first-class screen for **Map**. Must render empty, populated and error states.

### 5.3 Journal
A first-class screen for **Journal**. Must render empty, populated and error states.

### 5.4 Hero
A first-class screen for **Hero**. Must render empty, populated and error states.

### 5.5 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.6 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.7 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.

---

## 6. Domain model

Minimum entities, named per this app's convention:

- **Quest** — named per this app's convention.
- **Avatar** — named per this app's convention.
- **WeeklyBoss** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **Moorland waymap (peat brown, granite cairn, mist grey, lichen green, iron-gall roads)**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#EDE6D4` | Screen background |
| `surface` | `#D8CFBC` | Cards, rows, sheets |
| `ink` | `#1E1914` | Primary text and icons |
| `accent` | `#4A6B32` | Primary action, key figure, progress fill |
| `muted` | `#7A7264` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **SF Pro**

SF Pro only, reached as .system. At most six named steps behind one accessor. Weights carry hierarchy; no size jump above 34pt and no Font.custom with a fixed size. Body is at least 12pt. Text stays legible at the largest Dynamic Type size.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- One corner radius value applied consistently, or deliberately none if the
  design direction calls for hard edges.
- Every interactive element is at least 44x44 pt.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable**

One Codable waymap snapshot encoded to JSON in UserDefaults under a single versioned key. dayKey is Int in YYYYMMDD form derived from Calendar.current.startOfDay. Writes debounce and also flush on background so a force-quit cannot lose a stake. The UI never touches UserDefaults; a store protocol is the seam. resetAllData() is used by tests and reachable from Settings. Simulator seed once behind gds.demo.v1 marks onboarding complete and occupies a camp so home is not empty; never seed on a device.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Guidestoop/1.0 (iOS; +https://guidestoop-cairn.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- The app must not present itself as medical advice. It is a personal food log.
- Nutrition data is credited to Open Food Facts, a public database.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.lifestyle`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Light
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.lifestyle
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Fork-seal commit (streak reveals two roads; commit picks one and seals the other)

Fork-seal commit is the home verb: after three consecutive stakes the occupied camp grows a pair of forward roads. A further stake does not pick; the walker must be dragged onto exactly one revealed camp. That drag writes the chosen edge and seals the sibling road for the rest of this map; dragging toward a sealed or fogged camp does nothing. The three-day streak still gates the reveal; a day accepts a single stake; yesterday must have been staked or the streak drops. Each stake adds XP and level equals one plus totalXP divided by one hundred; five stakes during the week unlock the boss bonus. Journal keeps the chosen road so the breadcrumb trail is the committed DAG, not a quest list.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Hand-colored itinerary strip map (vellum, cinnabar cairns, lampblack contour)**

Base prompt, reused and extended for every asset:

```
Hand-colored itinerary strip map on vellum, cinnabar cairns, lampblack contour lines, peat-brown moor, granite stone piles, mist grey wash, lichen green moss, iron-gall ink roads, quiet margins, no readable text, no modern UI chrome
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `gds_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `gds_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `gds_Splash` | 1290x2796 | allowed | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `gds_Onboarding1` | 1024x1536 | allowed | Onboarding page 1 illustration: what the app is for. |
| 4 | `gds_Onboarding2` | 1024x1536 | allowed | Onboarding page 2 illustration: the main verb. |
| 5 | `gds_Onboarding3` | 1024x1536 | allowed | Onboarding page 3 illustration: why they stay. |
| 6 | `gds_EmptyHome` | 1024x1024 | allowed | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `gds_EmptyList` | 1024x1024 | allowed | Empty state: a secondary list has no rows. |
| 8 | `gds_CardBackdrop` | 1200x800 | allowed | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `gds_ControlFace` | 512x512 | allowed | Custom control artwork used for the primary interactive element. |
| 10 | `gds_TwistHero` | 1024x1024 | allowed | Hero art for the 'Fork-seal commit (streak reveals two roads; commit picks one and seals the other)' feature screen. |
| 11 | `gds_SuccessMark` | 512x512 | allowed | Shown briefly when the primary action succeeds. |
| 12 | `gds_HeaderDecor` | 1200x600 | allowed | Decorative header accent on the main screen. |

### Prompt per asset

**`gds_AppIcon`** — 1024x1024

```
Hand-colored itinerary strip map emblem: a single cinnabar granite cairn on peat-brown vellum, lampblack contour, fills the canvas edge to edge, no text, no alpha, no transparency, no rounded corners, no drop shadow
```

**`gds_Splash`** — 1290x2796

```
Vertical hand-colored itinerary strip map, vellum field, mist grey moor, iron-gall road fading into fog, quiet uncluttered middle third, lampblack contour, no text
```

**`gds_Onboarding1`** — 1024x1536

```
Hand-colored itinerary strip map of a lone guidestoop cairn on a peat moor, cinnabar stones, lampblack contour, vellum, what the product is
```

**`gds_Onboarding2`** — 1024x1536

```
Hand-colored itinerary strip map mid-gesture: a walker token dragged onto one of two revealed forward roads, the sibling road sealing in lampblack, vellum, cinnabar cairns
```

**`gds_Onboarding3`** — 1024x1536

```
Hand-colored itinerary strip map after a week: a breadcrumb trail of chosen cairns, one sealed sibling faded into mist, a distant ridge boss mark, vellum, lichen green moss
```

**`gds_EmptyHome`** — 1024x1024

```
Hand-colored itinerary strip map of a closed gate and fogged camps, no open road, calm vellum, lampblack contour, never sad
```

**`gds_EmptyList`** — 1024x1024

```
Empty vellum journal leaf with a faint lampblack contour and no chosen roads, itinerary strip map style, calm
```

**`gds_CardBackdrop`** — 1200x800

```
Low-contrast vellum wash with a faint peat-brown contour and lichen haze, itinerary strip map, text must stay readable
```

**`gds_ControlFace`** — 512x512

```
A small granite cairn pile as the walker token, cinnabar lichen flecks, lampblack contour, itinerary strip map, square emblem
```

**`gds_TwistHero`** — 1024x1024

```
Hand-colored itinerary emblem of a camp sprouting two forward roads, one road sealing, cinnabar cairns, iron-gall ink, vellum
```

**`gds_SuccessMark`** — 512x512

```
A cinnabar cairn with a small lampblack arrival mark, vellum field, itinerary strip map, no text
```

**`gds_HeaderDecor`** — 1200x600

```
Wide hand-colored itinerary band: mist moor, peat, one iron-gall road, granite cairns at the edges, lampblack contour, no text
```


### 13.3 Asset rules

- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, background textures, and anything else that needs a guaranteed transparent region or a guaranteed seamless join are drawn in SwiftUI via `Path` or `Shape`. The image generator is not used for these elements: it guarantees neither an alpha channel nor a seamless tile.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. Never seed on a physical device. Guard with
`#if targetEnvironment(simulator)` and `gds.demo.v1`.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as primary iconography.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.


---

## 17. Tests

Add a unit test target `GuidestoopTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Snapshot unit tests for every main screen named in section 3.6.
   Each of those screens must be a `*View` or `*Screen` type that constructs
   with no arguments (demo fixtures inside the view). The factory runs these
   tests on iPhone and iPad and keeps the PNGs.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Guidestoop -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.

**Uniqueness**
- [ ] Architecture matches **Forking path DAG (streak >= 3 reveals two successors; commit writes one edge and seals the other)** with no leakage across layers.
- [ ] UI approach matches **SwiftUI Canvas + MagnifyGesture waymap (cairns are Path; MagnifyGesture pans; drag moves the walker; no representable)**.
- [ ] Navigation matches **Waymap-locked chrome (the path never leaves; Journal, Hero and Settings arrive as sheets)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **SF Pro** and nothing else.
- [ ] Palette matches section 7.1 exactly.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Guidestoop
xcodegen generate
xcodebuild -scheme Guidestoop -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Guidestoop -destination 'platform=iOS Simulator,id=<UDID>' test
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY or DEVELOPMENT_TEAM in project.yml — CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
