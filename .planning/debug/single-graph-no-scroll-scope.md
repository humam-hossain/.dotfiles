---
status: diagnosed
trigger: "Diagnose UAT gap for Phase 54.3-interactive-multi-metric-hourly-graph-component. Goal: find_root_cause_only. Test 4: user reports no scrolling and only one graph, expected multiple graphs (recalls multi-tab Temp/Rain/Wind/AQI/Baro/UV)."
created: 2026-10-15T08:00:00Z
updated: 2026-10-15T08:00:00Z
---

## Current Focus

hypothesis: Scope/expectation conflict, not a rendering bug — Plan 04 intentionally collapsed 6 switchable graph views into one locked composite canvas per explicit user request ("i don't want tabs"); user now misremembers tabs as stacked graphs. "No scrolling" is correct Flickable behavior when content fits the 85%-viewport cap.
test: Code-structure inspection (popup composition, graph instance count, paint-branch presence, Flickable geometry bindings) + planning-artifact trace (DISCUSSION-LOG, 04-PLAN/SUMMARY, VERIFICATION superseded-notes, prior debug session g-54-3-1)
expecting: Single WeatherGraph instance in popup; tab chrome + non-thermal paint branches deleted by design; scroll bindings structurally correct
next_action: "Write ROOT CAUSE FOUND (find_root_cause_only — no fix here)"

## Symptoms

expected: Every popup card stacks cleanly — no collapsed cards, no content painting over siblings; scrolling reaches the bottom card fully. User recalls multi-tab graphs (Temp/Rain/Wind/AQI/Baro/UV) and now sees only one graph.
actual: User reported: there is no scrolling; everything is there apart from just one graph. Expected a lot of graphs (previously from tabs there were multiple tabs, so supposed to get multiple graphs). Only one graph visible now.
errors: None reported
reproduction: Test 4 in UAT — open weather popup, scroll top to bottom, count graph cards
started: Discovered during UAT 2026-10-15

## Eliminated

- hypothesis: Graph/card rendering bug — additional graph instances exist but fail to render (QML error, zero-height collapse, overlap/clipping hiding them)
  evidence: WeatherPopup.qml contains exactly ONE WeatherGraph instance (L55-59); there is no second graph component to fail. All five stat cards (hero, atmospheric, wind, AQI, astronomy) plus alert banner are present by user's own report ("everything is there"). Plan 06 converted every card to layout-driven sizing with harness-gated fillWidth asserts (85 PASS, 0 FAIL strict run). No missing-render path exists.
  timestamp: 2026-10-15T08:00:00Z
- hypothesis: Scroll mechanism broken (Flickable misconfigured, contentHeight wrong, scroll physically impossible)
  evidence: WeatherPopup.qml L29-35 — StyledFlickable has contentWidth/contentHeight bound to content width/column implicitHeight, clip:true, implicitHeight capped at 85% screen height. This is the correct pattern: scrollbar appears only when stacked content exceeds the cap. With one 400px graph + compact stat cards, content plausibly fits — absent scrolling is the correct idle state, not a breakage. (Pixel-level overflow-vs-fit cannot be proven headless — noted as blind spot — but no structural defect found.)
  timestamp: 2026-10-15T08:00:00Z
- hypothesis: Stale quickshell session (user viewing pre-fix UI, as in G-54.3-1)
  evidence: User describes EXACTLY the current post-Plan-04 UI — single locked composite graph, all cards present, static title era. A stale pre-Plan-04 session would show the 6-pill tab row; a stale pre-tab session would show unexplained curves without legend. Neither matches. Session is current.
  timestamp: 2026-10-15T08:00:00Z

## Evidence

- timestamp: 2026-10-15T08:00:00Z
  checked: WeatherPopup.qml (full read, 98 lines)
  found: Popup composes exactly 5 content blocks — alert banner, hero card, ONE WeatherGraph (L55-59), paired grid atmospheric+wind, paired grid AQI+astronomy. Single graph instance by construction; there was never a stacked-multi-graph layout in any revision.
  implication: "Only one graph" is the designed composition, not a dropped component.
- timestamp: 2026-10-15T08:00:00Z
  checked: DISCUSSION-LOG.md + 54.3-04-PLAN.md + prior debug session g-54-3-1-no-tab-selector.md
  found: Original design was ONE canvas with a 6-pill tab-switcher selecting which metric paints (single visible metric at a time — never stacked graphs). User verdict: "i don't want tabs either". Plan 04 (commits ca050376, 10d9d691) deleted the entire tab chrome block (tabBarContainer/tabsRepeater/tabHighlight/activeTabPill — all grep-count 0), locked activeMetric to "temp" with zero runtime writes, and pruned unreachable rain/baro/uv guideline + wind/aqi/baro/uv lower-bar paint branches.
  implication: The 6 "graphs" the user remembers were 6 switchable views of ONE canvas — now collapsed to 1 fixed view by explicit user request. Expectation of stacked graphs matches no shipped revision.
- timestamp: 2026-10-15T08:00:00Z
  checked: WeatherGraph.qml grep (activeMetric/Canvas/tabBar)
  found: Exactly one `Canvas {` (L584 graphCanvas); one `property string activeMetric: "temp"` (L11) with zero write-forms; static title "Hourly Temperature and Rain Outlook" (L38). getMetricY/formatTooltipMetric switch bodies retained byte-for-byte as uncalled helpers (per 04-SUMMARY key-decision, for Section 3 Node harness). Wind branch at L728 and temp||rain bar condition at L837 are dead under the lock.
  implication: Other-metric graph code is deleted-or-dead by design; helpers retained only for harness extraction. Restoring per-metric graphs requires re-adding paint branches, not flipping a flag.
- timestamp: 2026-10-15T08:00:00Z
  checked: 54.3-VERIFICATION.md superseded-notes + 54.3-06-SUMMARY.md
  found: VERIFICATION explicitly retires Plans 02/03 tab truths ("superseded by gap-closure intent, not failed") but Test 4's truth ("all expected graphs/cards present") was never redefined against the single-composite scope — it still carries the tab-era plural "graphs". Plan 06 verified stacking/scroll structure (no popup-container edit needed; Flickable follows column implicit height by construction) with D3 human-visual glance still outstanding.
  implication: The UAT truth itself is stale: it asserts a plural-graph expectation the locked scope deliberately removed. Gap G-54.3-4's truth needs rewriting, not just code.
- timestamp: 2026-10-15T08:00:00Z
  checked: Where non-thermal metrics surface now
  found: Wind, AQI, pressure/visibility, sun/moon live as dedicated stat cards (WeatherWindCard, WeatherAqiCard, WeatherAtmosphericCard, WeatherAstronomyCard) — text/stat presentation, not graphs. User confirms "everything is there apart from just one graph".
  implication: No data/coverage is lost — only the graphical time-series form of 5 metrics was removed with the tabs. Fix direction hinges on whether user wants time-series graphs back (stacked or tabbed) or accepts stat cards.

## Resolution

root_cause: Requirements/scope conflict — Plan 04 intentionally collapsed the 6-view tab-switched single canvas into one locked temp/feels-like/rain composite per the user's explicit "i don't want tabs" rejection, deleting tab chrome and pruning non-thermal paint branches; the user's Test 4 expectation (multiple stacked graphs, scrolling to reach them) matches no shipped revision — the remembered "multiple graphs" were switchable views of one canvas, never stacked instances (WeatherPopup.qml has exactly one WeatherGraph block). The Test 4 UAT truth still carries the tab-era plural-"graphs" wording and was never redefined against the locked scope. "No scrolling" is correct Flickable behavior (contentHeight follows implicitHeight, viewport capped at 85% screen — no overflow means no scrollbar), not a breakage; it amplifies the impression that content is missing.
fix: ""
verification: ""
files_changed: []
