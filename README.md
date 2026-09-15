# Guidestoop

Stake the cairn. Drag one road.

Guidestoop is an offline habit map for people who will do a daily chore if the next camp is a road they pick, not a checkbox that advances itself. Stand on the occupied camp, plant one stake a day, hold the streak until the gate sprouts two forward roads, then drag the walker onto exactly one revealed cairn. The sibling road seals for the rest of this map.

There is no account, no ads, no in-app purchase, and no remote configuration. The waymap stays on the device.

## Architecture

The home graph is a forking-path DAG. Camps are nodes and roads are directed edges owned by one `WaymapGraph`. A day accepts a single `CampStake` on the occupied camp only. The streak continues if and only if yesterday was staked; otherwise it drops. When the occupied-camp streak is at least three, that camp reveals exactly two successors. A further stake does not choose a road.

Commit is a graph write: `dragWalker(to:)` inserts the chosen edge and seals the sibling. Views call methods on that graph and never keep a forked copy of the path. `WaymapWatch` is the observable owner; `WaymapStore` is the only persistence seam (UserDefaults JSON plus an Application Support file). The UI never touches `UserDefaults`.

A DAG fits this product because the marketed verb is commit-the-road: one write, one sealed sibling, a breadcrumb trail that is the committed graph rather than a quest list.

## Fork-seal commit

After three consecutive stakes the occupied camp grows a pair of forward roads. Drag the walker onto one revealed camp. That write commits the chosen edge and seals the other for this map. Dragging toward a sealed or fogged camp does nothing.

This is why someone would pick Guidestoop: the next camp is a road you choose, not a node the app unlocks for you. Journal keeps the chosen roads. Five stakes in a week open the ridge boss for bonus XP. Level is `1 + totalXP / 100`. XP is stored; level is never stored.

The twist is visible on the waymap (revealed roads, walker drag) and has its own `ForkSealView` sheet.

## Design

Moorland waymap: peat brown, granite cairn, mist grey, lichen green, iron-gall roads. SF Pro only, reached as `.system` through `MoorVellum`. Palette tokens live in `Assets.xcassets` and are read only through `MoorVellum.Palette`.

The path never leaves. Journal, Hero, and Settings arrive as sheets. There is no tab bar and no Game tab. Empty Map copy: “The path is closed. Finish three days to open the next node.” Simulator seeds once behind `gds.demo.v1` and marks onboarding complete; a device never seeds.

Contact: https://guidestoop-cairn.pro/contact-us

## Art

Hand-colored itinerary strip map on vellum, cinnabar cairns, lampblack contour lines, peat-brown moor, granite stone piles, mist grey wash, lichen green moss, iron-gall ink roads, quiet margins, no readable text, no modern UI chrome.

Exact prompt used for every asset:

**Base, reused and extended**

```
Hand-colored itinerary strip map on vellum, cinnabar cairns, lampblack contour lines, peat-brown moor, granite stone piles, mist grey wash, lichen green moss, iron-gall ink roads, quiet margins, no readable text, no modern UI chrome
```

| Image set | Prompt |
| --- | --- |
| `gds_AppIcon` | Hand-colored itinerary strip map emblem: a single cinnabar granite cairn on peat-brown vellum, lampblack contour, fills the canvas edge to edge, no text, no alpha, no transparency, no rounded corners, no drop shadow |
| `gds_Splash` | Vertical hand-colored itinerary strip map, vellum field, mist grey moor, iron-gall road fading into fog, quiet uncluttered middle third, lampblack contour, no text |
| `gds_Onboarding1` | Hand-colored itinerary strip map of a lone guidestoop cairn on a peat moor, cinnabar stones, lampblack contour, vellum, what the product is |
| `gds_Onboarding2` | Hand-colored itinerary strip map mid-gesture: a walker token dragged onto one of two revealed forward roads, the sibling road sealing in lampblack, vellum, cinnabar cairns |
| `gds_Onboarding3` | Hand-colored itinerary strip map after a week: a breadcrumb trail of chosen cairns, one sealed sibling faded into mist, a distant ridge boss mark, vellum, lichen green moss |
| `gds_EmptyHome` | Hand-colored itinerary strip map of a closed gate and fogged camps, no open road, calm vellum, lampblack contour, never sad |
| `gds_EmptyList` | Empty vellum journal leaf with a faint lampblack contour and no chosen roads, itinerary strip map style, calm |
| `gds_CardBackdrop` | Low-contrast vellum wash with a faint peat-brown contour and lichen haze, itinerary strip map, text must stay readable |
| `gds_ControlFace` | A small granite cairn pile as the walker token, cinnabar lichen flecks, lampblack contour, itinerary strip map, square emblem |
| `gds_TwistHero` | Hand-colored itinerary emblem of a camp sprouting two forward roads, one road sealing, cinnabar cairns, iron-gall ink, vellum |
| `gds_SuccessMark` | A cinnabar cairn with a small lampblack arrival mark, vellum field, itinerary strip map, no text |
| `gds_HeaderDecor` | Wide hand-colored itinerary band: mist moor, peat, one iron-gall road, granite cairns at the edges, lampblack contour, no text |

## How this differs

Family `habit_rpg` is a waymap, not a quest list and not a calorie log. Home is a SwiftUI Canvas: cairns and iron-gall roads are `Path`; `MagnifyGesture` pans; a drag moves the walker. There is no `UIViewRepresentable` and no tab bar. Unique catalogs were exhausted, so the eight unique axes are new ASCII values. The verb is commit-the-road, not tick-a-quest, close-a-ring, or log-a-reading-expedition.

## Build

Requires Xcode 16+, iOS 17.0, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
cd Guidestoop
xcodegen generate
xcodebuild -scheme Guidestoop -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Guidestoop -destination 'platform=iOS Simulator,id=<UDID>' test
```

Bundle identifier: `com.guidestoop.cairn`. Domain: https://guidestoop-cairn.pro
