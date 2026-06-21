# PrepFlow ASCII Wireframes for Implementation Edits

Purpose: make the current SwiftUI implementation easier to inspect and edit.

This file is not the UI source of truth. The source of truth remains:

- `docs/ui-fidelity-contract.md`
- `design/*.png`
- `design/*.html`
- snapshot tests and `docs/ui-comparisons/*.comparison.png`

Use this file as a code navigation map only. If a layout change is desired, update
the matching `design/` wire first, then update SwiftUI to follow it.

## Legend

```text
+-----+     opaque content layer
|     |
+-----+

[glass]     Liquid Glass functional layer only
(time)      time / NOW / delay / deadline use; may use PrepFlowColor.time
[ink]       selection / progress / normal emphasis; must not use time red
<sheet>     modal sheet
{store}     BoardStore or AuthStore state/action
```

## Route Map

```text
PrepFlowApp
  |
  v
ContentView
  |
  v
AuthenticatedRootView
  |
  +-- no session -------------------------------------------+
  |                                                        |
  |  AuthGateView                                          |
  |   -> invite / Apple / magic link / local fallback       |
  |                                                        |
  +-- session ----------------------------------------------+
                                                           |
     AuthenticatedSessionView                              |
       |                                                   |
       +-- activation -> ActivationSummaryView             |
       +-- simulation -> SimulationView                    |
       +-- service    -> ServiceSetupView                  |
       +-- board      -> PrepFlowBoardView                 |
       +-- catalog    -> CatalogEditorView                 |
       +-- settings   -> SettingsHomeView                  |
```

## Auth Gate

Source file: `apps/ios/Sources/PrepFlow/AuthGateView.swift`
Canonical wire: `design/p0-wireframe-onboarding-liquidglass.png`

```text
+--------------------------------------------------------------------------------+
| [glass] AuthTopBar                                                              |
|         step 1 -- step 2 -- step 3                                               |
+--------------------------------------------------------------------------------+
|                                                                                |
| +--------------------------------+  +-----------------------------------------+ |
| | AuthHero                       |  | AuthInvitePanel                         | |
| | - product signal               |  | - email field                           | |
| | - onboarding message           |  | - magic link action                     | |
| | - readiness / local fallback   |  | - Apple sign-in action                  | |
| +--------------------------------+  +-----------------------------------------+ |
|                                                                                |
| +--------------------------------+  +-----------------------------------------+ |
| | AuthTenantPanel                |  | AuthStatusRows                         | |
| | - tenant / role                |  | - Supabase readiness                    | |
| | - local invite                 |  | - Apple readiness                       | |
| +--------------------------------+  +-----------------------------------------+ |
|                                                                                |
+--------------------------------------------------------------------------------+
| [glass] AuthBottomBar                                                           |
|         primary auth action / fallback status                                   |
+--------------------------------------------------------------------------------+
```

Edit anchors:

```text
AuthGateView          -> screen shell
AuthTopBar            -> functional glass layer
AuthHero              -> left content block
AuthInvitePanel       -> auth input/actions
AuthTenantPanel       -> tenant status
AuthStatusRow         -> readiness rows
AuthStore/AuthModels  -> session, invite, env fallback
```

## Activation Summary

Source file: `apps/ios/Sources/PrepFlow/SimulationViews.swift`
Canonical wire: `design/p0-wireframe-activation-liquidglass.png`

```text
+--------------------------------------------------------------------------------+
| [glass] ActivationTopBar                                                        |
|         setup steps: business done -> savings current -> first board pending    |
+--------------------------------------------------------------------------------+
|                                                                                |
| +------------------------------------------------------------------------------+|
| | ActivationNumbers                                                            ||
| | +--------------------+  +--------------------+  +--------------------+       ||
| | | reduction hero     |  | loss saving        |  | hit rate           |       ||
| | +--------------------+  +--------------------+  +--------------------+       ||
| +------------------------------------------------------------------------------+|
|                                                                                |
| +------------------------------------------------------------------------------+|
| | ActivationBars                                                               ||
| | - before recommendation                                                       ||
| | - after recommendation                                                        ||
| | - expected reduction                                                          ||
| +------------------------------------------------------------------------------+|
|                                                                                |
+--------------------------------------------------------------------------------+
| [glass] ActivationBottomBar -> continue to simulation / board                   |
+--------------------------------------------------------------------------------+
```

Edit anchors:

```text
ActivationSummaryView -> screen shell
ActivationTopBar      -> glass progress header
ActivationNumbers     -> KPI cards
ActivationBars        -> comparison bars
ActivationBottomBar   -> navigation action
BoardStore            -> simulation summary and routing progress
```

## Simulation

Source file: `apps/ios/Sources/PrepFlow/SimulationViews.swift`
Canonical wire: `design/p0-wireframe-simulation-liquidglass.png`

```text
+--------------------------------------------------------------------------------+
| [glass] SimulationTopBar                                                        |
|         period / route actions / reservation hub / close loop                   |
+--------------------------------------------------------------------------------+
|                                                                                |
| +--------------------------------+  +-----------------------------------------+ |
| | SimulationKPIGrid              |  | SimulationResultPanel                   | |
| | + KPIBox + KPIBox + KPIBox     |  | - waste log / correction result        | |
| | - recommended vs actual        |  | - board impact summary                 | |
| +--------------------------------+  +-----------------------------------------+ |
|                                                                                |
| +------------------------------------------------------------------------------+|
| | SimulationItemList                                                           ||
| | - SimulationItemRow                                                          ||
| | - SimulationBar: recommended / actual / gap                                  ||
| +------------------------------------------------------------------------------+|
|                                                                                |
| +------------------------------------------------------------------------------+|
| | SimulationStatusBox                                                          ||
| | - local save status                                                          ||
| | - applied coefficient status                                                 ||
| +------------------------------------------------------------------------------+|
+--------------------------------------------------------------------------------+
```

Edit anchors:

```text
SimulationView        -> screen shell and sheets
SimulationTopBar      -> glass function layer
SimulationKPIGrid     -> KPI summary
SimulationItemList    -> rows
SimulationResultPanel -> apply/adjust summary
CloseLoopSheet        -> close flow sheet
ReservationHubSheet   -> reservation diff sheet
```

## Service Setup

Source file: `apps/ios/Sources/PrepFlow/ServiceSetupView.swift`
Canonical wire: `design/p0-wireframe-service-setup-liquidglass.png`

```text
+--------------------------------------------------------------------------------+
| [glass] ServiceTopBar                                                           |
|         date / service period / open time                                       |
+--------------------------------------------------------------------------------+
|                                                                                |
| +------------------------------------------+ +-------------------------------+ |
| | ReservationList                          | | ServiceCoversPanel            | |
| | + ServiceControlStrip                    | | - main covers stepper         | |
| | | - period toggle                        | | - other covers stepper        | |
| | | - open time control (time)             | | - generated board status      | |
| | +--------------------------------------+ | | - generate board action       | |
| | | ReservationRow                         | +-------------------------------+ |
| | | ReservationRow                         |                                   |
| | | add manual reservation                 |                                   |
| | +--------------------------------------+ |                                   |
| +------------------------------------------+                                   |
|                                                                                |
| <sheet> ReservationEditSheet                                                    |
|         covers stepper / note field / delete action                             |
+--------------------------------------------------------------------------------+
```

Edit anchors:

```text
ServiceSetupView        -> screen shell
ServiceTopBar           -> top glass layer
ServiceControlStrip     -> period/open-time controls
ReservationList         -> manual reservation list
ReservationRow          -> row action into edit sheet
ServiceCoversPanel      -> cover totals and board generation
ReservationEditSheet    -> edit/delete sheet
BoardStore              -> service, reservations, board preview
```

## Board: Shared Shell

Source files:

- `apps/ios/Sources/PrepFlow/ContentView.swift`
- `apps/ios/Sources/PrepFlow/BoardChrome.swift`

Canonical wires:

- `design/p0-wireframe-board-liquidglass.png`
- `design/p1-wireframe-board-eta-liquidglass.png`
- `design/p1-wireframe-view-dishes-liquidglass.png`
- `design/p1-wireframe-view-staff-liquidglass.png`

```text
+--------------------------------------------------------------------------------+
| [glass] BoardTopBar                                                             |
|  title + day/covers             [ now | dishes | staff ]     (T-minus island)   |
|  impact badge / settings                                                         |
+--------------------------------------------------------------------------------+
|                                                                                |
|                         selected BoardMode                                      |
|                                                                                |
|      now view                 dishes view                  staff view            |
|         |                         |                          |                  |
|         v                         v                          v                  |
|   NowBoardContent          DishBoardContent            StaffBoardContent         |
|                                                                                |
+--------------------------------------------------------------------------------+
| [glass] BoardBottomBar or LineGateBar                                           |
|  - line gate status                                                             |
|  - guidance action                                                              |
|  - label progression / unresolved check                                         |
+--------------------------------------------------------------------------------+
| <sheet> NowGuidanceSheet                                                        |
| <sheet> LabelOpsSheet                                                           |
+--------------------------------------------------------------------------------+
```

Rules to preserve:

```text
1. Board navigation is top bar + segmented control.
2. Do not replace now/dishes/staff with a sidebar.
3. Progress bars use ink, not time red.
4. Time red is only for T-minus, NOW, delay, deadline, urgent.
5. Glass is only top bar, segment, countdown island, bottom bar, sheets.
```

## Board: Now View

Source file: `apps/ios/Sources/PrepFlow/ContentView.swift`
Main view: `NowBoardContent`

```text
+--------------------------------------------------------------------------------+
| +--------------------------------------+ +------------------------------------+ |
| | Focus area                           | | TimelineRail                       | |
| | - current task title                 | | - T-minus sequence                 | |
| | - quantity / assignee                | | - RailItem rows                    | |
| | - FocusTaskRow list                  | | - status per step                  | |
| | - CheckCircle state                  | |                                    | |
| +--------------------------------------+ +------------------------------------+ |
|                                                                                |
| +--------------------------------------+ +------------------------------------+ |
| | BoardWorkStatePanel                  | | BoardLandingForecastCard           | |
| | - started/hold/readiness             | | - ETACompact                       | |
| | - start/pause/resume/check/complete  | | - delay/shortfall state (time)     | |
| | - assist proposal action             | | - assist apply                     | |
| +--------------------------------------+ +------------------------------------+ |
|                                                                                |
| +------------------------------------------------------------------------------+|
| | BoardImpactRailCard                                                          ||
| | - queued reservation/service/guest/remaining impacts                         ||
| | - apply or dismiss impact                                                    ||
| +------------------------------------------------------------------------------+|
+--------------------------------------------------------------------------------+
```

## Board: Dishes View

Source file: `apps/ios/Sources/PrepFlow/ContentView.swift`
Main view: `DishBoardContent`

```text
+--------------------------------------------------------------------------------+
| DishBoardContent                                                                |
|                                                                                |
| +----------------------+ +----------------------+ +----------------------+     |
| | DishCard             | | DishCard             | | DishCard             |     |
| | - dish title         | | - dish title         | | - dish title         |     |
| | - [ink] ProgressBar  | | - [ink] ProgressBar  | | - [ink] ProgressBar  |     |
| | - DishTaskRow        | | - DishTaskRow        | | - DishTaskRow        |     |
| | - DishImpactRow      | | - DishImpactRow      | | - DishImpactRow      |     |
| +----------------------+ +----------------------+ +----------------------+     |
+--------------------------------------------------------------------------------+
```

## Board: Staff View

Source file: `apps/ios/Sources/PrepFlow/ContentView.swift`
Main view: `StaffBoardContent`

```text
+--------------------------------------------------------------------------------+
| StaffBoardContent                                                               |
|                                                                                |
| +---------------------------+ +---------------------------+ +----------------+ |
| | StaffColumn               | | StaffColumn               | | StaffColumn    | |
| | - operator / workload     | | - operator / workload     | | - operator    | |
| | - StaffTaskCard           | | - StaffTaskCard           | | - task cards  | |
| | - StaffImpactCard         | | - StaffImpactCard         | | - impacts     | |
| +---------------------------+ +---------------------------+ +----------------+ |
+--------------------------------------------------------------------------------+
```

## Now Guidance Sheet

Source file: `apps/ios/Sources/PrepFlow/NowGuidanceSheet.swift`
Canonical wire: `design/p0-wireframe-board-liquidglass.png`

```text
+--------------------------------------------------------------------------------+
| <sheet> NowGuidanceSheet                                                        |
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | GuidanceWorkStatePanel            | | TodayPrepImpactPanel                  | |
| | - active operator                 | | - impact rows                         | |
| | - start/pause/resume              | | - apply/dismiss                       | |
| | - actual minute adjustment        | |                                       | |
| +-----------------------------------+ +---------------------------------------+ |
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | GuidanceReadinessGate             | | AssistProposalCard                    | |
| | - GuidanceCheckRow                | | - late/shortfall proposal             | |
| | - completed check state           | | - apply assist                        | |
| +-----------------------------------+ +---------------------------------------+ |
|                                                                                |
| +------------------------------------------------------------------------------+|
| | GuidanceStepRow list / undo / complete next                                  ||
| +------------------------------------------------------------------------------+|
+--------------------------------------------------------------------------------+
```

## Catalog Editor

Source file: `apps/ios/Sources/PrepFlow/CatalogEditorView.swift`
Canonical wires:

- `design/p1-wireframe-template-editor-liquidglass.png`
- `design/p1-wireframe-prepitem-editor.png`

```text
+--------------------------------------------------------------------------------+
| [glass] CatalogTopBar                                                           |
+--------------------------------------------------------------------------------+
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | CatalogTree                       | | CatalogDetail                         | |
| | - dish rows                       | | - task fields                         | |
| | - component rows                  | | - scale mode                          | |
| | - task rows                       | | - yield / lead / duration             | |
| | - add buttons                     | | - instructions / media placeholder    | |
| +-----------------------------------+ | - CatalogPreview                      | |
|                                       | - CatalogSavedStatus                  | |
|                                       +---------------------------------------+ |
+--------------------------------------------------------------------------------+
```

## Settings Home

Source file: `apps/ios/Sources/PrepFlow/SettingsHomeView.swift`
Canonical wire: `design/p1-wireframe-settings-home-liquidglass.png`

```text
+--------------------------------------------------------------------------------+
| [glass] SettingsTopBar                                                          |
|         back to board / session / sign out                                      |
+--------------------------------------------------------------------------------+
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | SettingsCard: Account             | | SettingsCard: Store / service         | |
| | - auth provider                   | | - service time (time)                 | |
| | - tenant readiness                | | - theme / lock / export               | |
| +-----------------------------------+ +---------------------------------------+ |
|                                                                                |
| +------------------------------------------------------------------------------+|
| | SettingsToast                                                                 ||
| +------------------------------------------------------------------------------+|
+--------------------------------------------------------------------------------+
```

## Close Loop Sheet

Source file: `apps/ios/Sources/PrepFlow/CloseLoopSheet.swift`
Canonical wires:

- `design/p2-wireframe-close-flow-liquidglass.png`
- `design/p2-wireframe-close-nextday-liquidglass.png`

```text
+--------------------------------------------------------------------------------+
| <sheet> CloseLoopSheet                                                          |
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | CloseLoopQtyStepper               | | CloseLoopPreview                      | |
| | - made quantity                   | | - waste / carryover summary          | |
| | - leftover quantity               | | - next-day effect                    | |
| +-----------------------------------+ +---------------------------------------+ |
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | CloseLoopDecisionPicker           | | CloseLoopBatchTable                   | |
| | CloseLoopReasonPicker             | | - CloseLoopBatchRow                  | |
| +-----------------------------------+ +---------------------------------------+ |
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | CloseLoopLearningFeed             | | CloseLoopNextDayPanel                 | |
| | - learning waste records          | | - CloseLoopNextDayRow                | |
| +-----------------------------------+ +---------------------------------------+ |
+--------------------------------------------------------------------------------+
```

## Reservation Hub Sheet

Source file: `apps/ios/Sources/PrepFlow/ReservationHubSheet.swift`
Canonical wire: `design/p2-wireframe-reservation-hub-liquidglass.png`

```text
+--------------------------------------------------------------------------------+
| <sheet> ReservationHubSheet                                                     |
|                                                                                |
| [glass] ReservationHubTopBar                                                    |
|         source chips / resync / apply                                           |
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | ReservationHubList                | | ReservationHubApplyPanel              | |
| | - ReservationHubRow               | | - apply gate status                   | |
| | - duplicate alert                 | | - panel rows                          | |
| | - source status                   | | - applied status                      | |
| +-----------------------------------+ +---------------------------------------+ |
|                                                                                |
| +------------------------------------------------------------------------------+|
| | ReservationConnectorReviewPanel                                             ||
| | - connector diff review rows                                                ||
| | - accept/reject                                                              ||
| +------------------------------------------------------------------------------+|
+--------------------------------------------------------------------------------+
```

## Reservation Omotenashi Panel

Source file: `apps/ios/Sources/PrepFlow/ReservationOmotenashiPanel.swift`
Canonical wires:

- `design/p2-wireframe-special-prep.png`
- `design/p3-wireframe-allergy-message.png`
- `design/p3-wireframe-allergen-labels.png`

```text
+--------------------------------------------------------------------------------+
| ReservationOmotenashiPanel                                                      |
|                                                                                |
| +------------------------------+ +-------------------------------------------+ |
| | ReservationSpecialPrepRow    | | ReservationGuestReplyRecheckRow           | |
| | - special prep task          | | - changed guest reply                     | |
| | - assignment/status          | | - recheck impact                          | |
| +------------------------------+ +-------------------------------------------+ |
|                                                                                |
| +------------------------------------------------------------------------------+|
| | ReservationAllergenPreview                                                  ||
| | - allergen label preview                                                     ||
| | - print/reprint status                                                       ||
| +------------------------------------------------------------------------------+|
+--------------------------------------------------------------------------------+
```

## Label / Larder / QR Sheet

Source file: `apps/ios/Sources/PrepFlow/LabelOpsSheet.swift`
Canonical wires:

- `design/p2-wireframe-label-flow.png`
- `design/p2-wireframe-prep-larder.png`
- `design/p2-wireframe-label-settings.png`
- `design/p2-wireframe-fridge-lens.png`

```text
+--------------------------------------------------------------------------------+
| <sheet> LabelOpsSheet                                                           |
|                                                                                |
| [glass] LabelOpsTopBar                                                          |
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | LabelFlowColumn                   | | PrepLarderPanel                       | |
| | - step 1 completed task preview   | | - larder KPI                          | |
| | - step 2 label preview            | | - printer settings                    | |
| | - step 3 QR remaining/waste       | | - fridge lens                         | |
| | - step 4 carryover preview        | | - larder items                        | |
| +-----------------------------------+ | - FIFO footer                         | |
|                                       +---------------------------------------+ |
+--------------------------------------------------------------------------------+
```

## Direct Booking Sheet

Source file: `apps/ios/Sources/PrepFlow/DirectServiceOpsSheet.swift`
Canonical wire: `design/p3-wireframe-direct-booking.png`

```text
+--------------------------------------------------------------------------------+
| <sheet> DirectBookingOpsSheet                                                   |
|                                                                                |
| +------------------------------+ +-------------------------------------------+ |
| | DirectBrandPanel             | | DirectStepCard stack                      | |
| | - booking source             | | - party card                              | |
| | - allotment / remaining      | | - course card                             | |
| +------------------------------+ | - note card                               | |
|                                  | - payment card                            | |
|                                  +-------------------------------------------+ |
|                                                                                |
| +------------------------------------------------------------------------------+|
| | DirectOpsStatus                                                             ||
| | - checkout / no-show / waitlist / prep impact                               ||
| +------------------------------------------------------------------------------+|
+--------------------------------------------------------------------------------+
```

## Service Pass Sheet

Source file: `apps/ios/Sources/PrepFlow/DirectServiceOpsSheet.swift`
Canonical wire: `design/p4-wireframe-passview.png`

```text
+--------------------------------------------------------------------------------+
| <sheet> ServicePassOpsSheet                                                     |
|                                                                                |
| [glass] ServicePassTopBar                                                       |
|         segmented mode / sync actions                                           |
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | ServicePassMatrix                 | | ServiceRemainingBoard                 | |
| | - ServicePassCell grid            | | - remaining count                     | |
| | - fire / hold / served state      | | - pacing proposal                     | |
| +-----------------------------------+ +---------------------------------------+ |
|                                                                                |
| +-----------------------------------+ +---------------------------------------+ |
| | ServiceFireBanner                 | | ServiceSyncPanel                      | |
| | - urgent fire/hold state          | | - offline flush                       | |
| +-----------------------------------+ | - POS/KDS event replay                | |
|                                       +---------------------------------------+ |
|                                                                                |
| +------------------------------------------------------------------------------+|
| | ServicePassStaffHandoff / ServiceTimelineRow                                 ||
| +------------------------------------------------------------------------------+|
+--------------------------------------------------------------------------------+
```

## Store / Engine / Data Wiring

```text
SwiftUI View
  |
  | user action
  v
BoardStore or AuthStore
  |
  +-- pure calculation --------------------------------------+
  |                                                         |
  |  Engine                                                 |
  |   - calcQty                                             |
  |   - schedule                                            |
  |   - rollup                                              |
  |   - ETA / today-prep                                    |
  |   - close / carryover                                   |
  |   - reservation diff                                    |
  |   - label / larder                                      |
  |   - direct / service sync                               |
  |                                                         |
  +-- local persistence ------------------------------------+
                                                            |
     PrepFlowDatabase (GRDB SQLite)
      - tenant scoped rows
      - event log
      - settings payloads
      - local fallback
      - restore state on relaunch
```

## Edit Workflow

```text
1. Pick the screen or sheet in this document.
2. Open the listed canonical design file in design/.
3. Open the listed Swift source file.
4. Keep the same macro layout:
   - top glass layer
   - opaque content layer
   - bottom/sheet glass layer
5. Use only DesignTokens for color/font/radius/spacing/motion.
6. Use PrepFlowColor.time only for time/NOW/delay/deadline/urgent.
7. Add or keep // time-use: on every PrepFlowColor.time usage.
8. Keep // canonical design comments near every SwiftUI View.
9. Run:
   swiftformat --lint .
   swiftlint --strict
   xcodebuild test ... -only-testing:PrepFlowSnapshotTests
10. If the visual structure intentionally changed:
   update design/ first, render the PNG, then update snapshots/comparisons.
```

## Snapshot Comparison Files

```text
docs/ui-comparisons/testAuthGateMatchesSourceWire.p0-wireframe-onboarding-liquidglass.comparison.png
docs/ui-comparisons/testActivationMatchesSourceWire.p0-wireframe-activation-liquidglass.comparison.png
docs/ui-comparisons/testSimulationMatchesSourceWire.p0-wireframe-simulation-liquidglass.comparison.png
docs/ui-comparisons/testServiceSetupMatchesSourceWire.p0-wireframe-service-setup-liquidglass.comparison.png
docs/ui-comparisons/testBoardNowMatchesSourceWire.p0-wireframe-board-liquidglass.comparison.png
docs/ui-comparisons/testBoardDishesMatchesSourceWire.p1-wireframe-view-dishes-liquidglass.comparison.png
docs/ui-comparisons/testBoardStaffMatchesSourceWire.p1-wireframe-view-staff-liquidglass.comparison.png
docs/ui-comparisons/testCatalogEditorMatchesSourceWire.p1-wireframe-template-editor-liquidglass.comparison.png
docs/ui-comparisons/testSettingsHomeMatchesSourceWire.p1-wireframe-settings-home-liquidglass.comparison.png
```
