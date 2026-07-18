# ember-remodal v3 modernization — plan &amp; progress

_Working notes for the modernization effort on branch `claude/ember-remodal-modernize-he3lc5`. Not part of the published addon; safe to delete before merging the final PR._

Last updated: 2026-07-18 (mid fix-pass, resuming after a model switch).

## Goal

Bring `ember-remodal` up to current (July 2026) Ember/Ember CLI addon standards and make it work with modern Ember, while preserving the "remodal" look, feel, and public API as closely as possible. Original request also authorized a full reimplementation if the underlying `remodal` library itself turned out to be a blocker.

## Research findings (done)

**remodal (the wrapped jQuery library) — verdict: reimplement, don't wrap.**
- Explicitly abandoned by its author since Jan 2017 ("no longer maintained... not interested to maintain jQuery plugins anymore"). 61 open issues, no maintained fork, no jQuery-free successor exists anywhere.
- It does still *function* on jQuery 3.x/4.x by API-surface analysis, but shipping jQuery + a 9-year-dead dependency is not viable for a "modern" addon.
- Its entire look and feel is ~320 lines of plain MIT-licensed CSS (no preprocessor) — fully portable: dark slate `rgba(43,46,56,.9)` backdrop, flat white card (no border-radius/shadow), 0.3s scale+opacity open/close keyframes, top-left 35×35 `×` close glyph, green `#81c784`/red `#e57373` confirm/cancel buttons, 700px max-width, mobile full-width.
- The only "clever" JS bit (animation-synced state via counted `animationstart`/`animationend`) is trivially replaced by the Web Animations API (`element.getAnimations()` + `.finished`).
- Remodal itself has zero accessibility (no `role="dialog"`, no `aria-modal`, no focus trap/restore) — worth improving on, not preserving.

**Modern Ember addon practices (July 2026) — verdict: rebuild as a v2 addon.**
- v2 ("Embroider spec") addon format is standard; official blueprint is now `@ember/addon-blueprint` (the old `@embroider/addon-blueprint` monorepo blueprint is retired/replaced). Single-package layout: `src/` (addon source) + `tests/` + `demo-app/` (dev-only Vite-served app), not the old `addon/`+`test-app/` monorepo split.
- `ember-source` current stable 7.1, current LTS 6.12; addon should target `ember-source >= 5.8` as a peer dependency.
- gts (`<template>` tag, strict mode) is the recommended default component format; TypeScript via `--typescript` blueprint flag, type-checked with `@glint/ember-tsc`.
- CSS ships via rollup's `keepAssets` plugin + a plain side-effect `import './foo.css'` in the component module — `app.import`/`treeForVendor` don't exist for v2 addons.
- Native `<dialog>` is the recommended foundation for modals in 2026 (what `ember-primitives`' `Dialog` and `@zestia/ember-modal-dialog` v5 do) — gives top-layer rendering, focus containment, and Esc handling for free, replacing the historic need for `ember-wormhole`/tether-style portal libraries. `{{in-element}}` (built into Ember core since 3.20) is the modern replacement for `ember-wormhole` where a portal is still needed (the yielded open-trigger button).
- Testing: Vite + Testem + QUnit + `@ember/test-helpers`; `@embroider/try` (not classic `ember-try`) drives the LTS/latest/beta/alpha matrix; GitHub Actions, not Travis.
- Legacy → modern API swaps applied throughout: `Ember.Logger` → `console`/`@ember/debug` `warn`; `sendAction`/closure actions → function args; jQuery → native DOM; `ember-wormhole` → `{{in-element}}`; computed properties → `@tracked` + native getters; `scheduleOnce`/runloop → `async`/`await` + `@ember/test-waiters`; RSVP → native `Promise`.

## Prior-art check (done, per explicit user request)

Checked all remote branches and open GitHub issues/PRs before starting the rewrite, since the user suspected an earlier abandoned attempt:
- Branches: `master` (df25509, last real activity), `legacy` (pre-2.3 Ember, dead-end, not relevant), `gh-pages` (docs site only). **No prior "remove remodal" branch or WIP exists** — the modernization had not been previously started.
- Open issues on `sethbrasile/ember-remodal` that this rewrite addresses: #55 (Ember 4.x incompatibility — jQuery-integration deprecation), #45 (Ember 3.x), #44 (`modal.close()` promise never resolves — root-caused to a remodal upstream bug), #43 (ember-cli-babel 5.x deprecated), #42 (FastBoot 1.0 breakage), #40 (lazy rendering of block content), #36 (confirm/cancel actions in the yielded hash), #34 (stacked-modal / background-blur interaction bug), #23 (missing `beforeOpen` hook), #17 (author's own wishlist: remove `ember-wormhole`), #16 (author's own wishlist: remove promises / support rapid open-close).
- Open PR #54 (draft, external contributor, "bump Ember to 3.28") — superseded by this rewrite; not merged, not built upon.
- **Every one of these was designed into the new implementation** (see "Old → new API mapping" below), so the rewrite isn't just a technical upgrade, it's also a backlog clear-out.

## Architecture decisions

| Concern | Old (v1, 2.18.0) | New (v3) |
|---|---|---|
| Addon format | v1 classic (broccoli) | v2 (`@embroider/addon-dev` + rollup), official `@ember/addon-blueprint` scaffold |
| Language | JS (loose mode) | TypeScript, `.gts` strict-mode templates |
| Modal engine | `remodal` (jQuery) | Native `<dialog>` + Web Animations API |
| Portal (open-trigger button) | `ember-wormhole` | Built-in `{{in-element}}`, eagerly-created stable target element |
| State | Ember `Component.extend` + string actions/`sendAction` | `@glimmer/component` + `@tracked` state machine (`closed/opening/opened/closing`) |
| Scheduling | `@ember/runloop` `scheduleOnce`/`next` | `async`/`await`, `requestAnimationFrame`, `@ember/test-waiters` |
| Promises | RSVP | Native `Promise` |
| Styling | Full remodal CSS + addon's small CSS extras, shipped via `treeForVendor`/`app.import` | Remodal theme ported verbatim into `src/styles/ember-remodal.css`, shipped via rollup `keepAssets` + side-effect import |
| Test runner | `ember-cli-qunit`, `ember-try`, Travis | Vite + Testem + QUnit, `@embroider/try`, GitHub Actions |

Public API is preserved wherever practical (see mapping below); breaking changes are deliberate and documented in `MIGRATION.md`.

### Old → new API mapping (what's preserved, what's new, what's dropped)

**Preserved:** all component args and their defaults (`title`, `text`, `confirmButton`, `cancelButton`, `openButton`, `openLink`, `linkButton`, `name`, `forService`, `dataTestId`, `modifier`, `*Classes` args, `closeOnEscape/Cancel/Confirm/OutsideClick`, `disableForeground`, `disableNativeClose`, `disableAnimation`, `options` hash); the yielded `m.open`/`m.confirm`/`m.cancel` button components; the `remodal` service's `open(name, opts)`/`close(name)` API and its "not registered" assertion message; promise-returning component `open()`/`close()`; every `remodal-*` / `ember-remodal` CSS class and `data-test-id` used by consuming apps' tests; `disableAnimationWhileTesting` environment config.

**New (additive):** `m.isOpen` (yielded, addresses #40 lazy-rendering ask — content can be gated with `{{#if m.isOpen}}`), `m.openAction`/`m.closeAction`/`m.confirmAction`/`m.cancelAction` plain zero-arg functions (addresses #36), `@onBeforeOpen` veto hook (addresses #23), modals now stack correctly when opened from inside another modal (addresses #34), no more `ember-wormhole` dependency (addresses #17), promise semantics hardened against the never-resolves bug (addresses #16, #44).

**Deliberately dropped (documented in MIGRATION.md):** `hashTracking` (URL-hash deep-linking) — the router owns the URL in a modern Ember app, this is out of scope for a modal addon; jQuery/remodal/`ember-wormhole` as dependencies; Ember &lt; 5.8 support; string-based `sendAction` actions (now function args, e.g. `@onOpen={{this.doThing}}`); the old service's `alias()` passthrough properties (`service.title`, `service.set(...)`, etc.) — options now flow only through `service.open(name, opts)`.

## Progress tracking

### Phase 1 — Scaffold (✅ done, committed)
Commit `9c0580b`: regenerated the addon from the official `@ember/addon-blueprint` (TypeScript, pnpm) — single-package `src/`+`tests/`+`demo-app/` layout, rollup + `@embroider/addon-dev` build, `@embroider/try` CI matrix on GitHub Actions. Verified green (build + scaffold smoke test) before committing.

### Phase 2 — Core reimplementation (✅ done, committed)
Commit `d4730c6`: `src/components/ember-remodal.gts` (native-`<dialog>` component with open/close/confirm/cancel state machine), `src/components/ember-remodal/er-button.gts` (portal button via `{{in-element}}`), `src/services/remodal.ts`, `src/styles/ember-remodal.css` (ported remodal theme). Reviewed personally (2 fixes applied: `ErButton` wrapper had a spurious `role="button"`; service overrides needed to persist, not just apply once) before committing. Verified: build, `lint:types`, `lint:js`, full test suite green at commit time.

### Phase 3 — Tests, demo app, docs (✅ done, committed)
Commit `be07967`: 48 rendering/unit tests, one-page Vite demo app, rewritten `README.md` + new `MIGRATION.md`. All green at commit time (49 tests incl. scaffold smoke test; full `pnpm lint` suite; `pnpm build`).

### Phase 4 — Adversarial code review (✅ done)
Ran an 8-angle parallel review (`code-review` skill, high effort) over the full `master...HEAD` diff: line-by-line scan, removed-behavior audit (old v1 API vs new), cross-file contract tracer, reuse, simplification, efficiency, altitude, and CLAUDE.md conventions (none apply — no CLAUDE.md files exist in this repo). 12 findings survived verification (one empirically reproduced with a throwaway failing test — see below), all CONFIRMED or PLAUSIBLE. Findings reported via `ReportFindings`. Summary, most severe first:

1. **CONFIRMED, empirically reproduced.** Native `<dialog>` fires its `close` event from a *queued* task. `modal.close().then(m => m.open())` (a natural reopen pattern) let the queued stale `close` event arrive after the reopen had already started, clobbering it: dialog left visibly open but internal state forced to `closed`, scroll lock released. Reproduced with a temporary test (`not ok ... close().then(open()) reopen survives the queued native close event`) before being handed to the fix pass; test was deleted after confirming.
2. **CONFIRMED.** `RemodalService.open(name, opts)` replaced `serviceOverrides` wholesale instead of merging — old v1 addon's `setProperties` merged/persisted options cumulatively across calls; a comment in the new code even claimed parity it didn't have.
3. **CONFIRMED.** `@options` hash precedence was inverted vs v1 (v1's `setProperties(options)` ran after direct attrs and won; the rewrite had direct args winning).
4. **CONFIRMED.** `open()` silently no-op'd (resolved without opening, no warning) if called before the `<dialog>` element had been captured by its modifier — e.g. `service.open()` fired during the same render pass that creates the modal. v1 tolerated this via `afterRender` scheduling.
5. **CONFIRMED.** In production builds (where `@ember/debug`'s `assert` is a stripped no-op), `service.open('unregistered-name')` threw a bare synchronous `TypeError` instead of a helpful error/rejected promise.
6. **CONFIRMED.** Registering under `this.name` in the constructor but unregistering under the (possibly since-changed) `this.name` getter in `willDestroy` could strand a destroyed instance in the service registry under its original name.
7. **CONFIRMED.** `ErButton`'s click handler unconditionally called `preventDefault()` — v1's confirm/cancel buttons never did this (only the open-trigger path did), so e.g. a checkbox or `<label>` inside `{{#m.confirm}}` would stop working after upgrade.
8. **CONFIRMED.** Yielded `m.isOpen` excluded the `'closing'` state, so the documented lazy-content pattern (`{{#if m.isOpen}}`) tore content out at the instant `close()` was called — visibly collapsing mid-animation instead of after it.
9. **CONFIRMED.** `disableForeground`'s "invisible" card still spans the full 700px box and intercepted clicks meant to fall through to the backdrop (`closeOnOutsideClick`).
10. **PLAUSIBLE.** An interrupt landing inside the two-`requestAnimationFrame` priming window before animation-cancellation could take effect left the superseded transition's promise waiting on the *new* transition's animations instead of settling on its own.
11. **PLAUSIBLE.** Chromium's close-watcher "abuse guard" only honors one `preventDefault()` on the dialog's `cancel` event per user-activation gesture — a double-tap Escape can force-close a dialog even with `@closeOnEscape={{false}}`. Platform limitation, not fixable in userspace; needs documentation.
12. **CONFIRMED (efficiency, non-correctness).** The portal-target element for `m.open` was created lazily via a microtask-deferred tracked write, causing every open-trigger button to render twice (once inline inside the closed dialog, then torn down and rebuilt in the portal) on first render.

Several additional cleanup-tier findings (getter boilerplate, duplicated test helpers, `console.warn` vs `@ember/debug` `warn`, scroll-lock bookkeeping split across two mechanisms, `transitionId` redundant with deferred-slot identity, animation-scoping robustness) were folded into the same fix pass since they were cheap to do alongside the correctness fixes.

### Phase 5 — Apply fixes (🔶 in progress — paused at the user's request)

A 27-item fix spec was written to `/tmp/claude-0/.../scratchpad/FIXES.md` covering all 12 findings above plus the cleanup-tier items. A subagent began applying it but **died mid-task** (hit a Fable-5 usage-credit limit, not a real failure — the session model has since been switched to `claude-sonnet-5`). Its partial work landed uncommitted in the working tree; I resumed by hand after the model switch and have completed items 1–25. Paused here at the user's explicit request ("stop developing, I just wanted progress/plan documented") before starting items 26–27 and before the final commit/push.

**Confirmed done (present in the working tree right now, per file inspection):**
- Item 1 — stale `close` event guard (`handleDialogClose` checks `dialog.open` before treating the event as real)
- Item 2 — shared `finalizeClose()` teardown used by both `close()` and the native-close desync path
- Item 3 — `open()` waits (bounded, test-waiter-wrapped) for the dialog element if called before render
- Item 4 — `@options` precedence fixed (`serviceOverrides ?? options ?? args`)
- Item 5 — `isOpen` now spans `opening|opened|closing`
- Item 6 — registration name snapshotted at register time, used symmetrically at unregister
- Item 7 — close-when-never-opened warning now uses `@ember/debug` `warn` and only fires when the modal truly never opened (`hasOpened` flag)
- Item 8 — staleness re-checked after each `await` inside the animation wait
- Item 9 — animation scoping tightened to `CSSAnimation` instances whose name starts with `remodal-` (guards against a consumer's infinite custom animation hanging `open()`/`close()`)
- Item 10 — scroll lock rewritten as a `Set`-based holder registry driven by one `setState()` funnel (no more separate `holdsScrollLock` boolean / counter-clamp)
- Item 11 — open-button portal target created eagerly in the constructor (not tracked, not deferred) — the double-render is gone
- Item 12 — `disableAnimationWhileTesting`/environment config resolved once in the constructor, not per-render
- Item 13 — animation wait short-circuits immediately when `disableAnimation` is true
- Item 14 — the `waitForTransition` wrapper was folded into `animationsSettled`
- Item 15 — `disable-animation` class spelling unified (both dialog and card now use `this.animationState`)
- Item 16 — the ~16 pass-through option getters collapsed into one bound `opt(key)` helper, invoked from the template as `{{this.opt "title"}}` etc.; getters kept only where real logic lives (`name`, `forService`, `modifier`, `closeOn*`, `disable*`, `stateClass`, `isOpen`)
- Item 17 — `m.open`'s curried `onClick` now points at `handleOpenClick` (which preventDefaults) instead of raw `open`
- Item 18 — `ErButton.handleClick` no longer calls `preventDefault()` (confirmed via system-reminder showing the file diff)
- Item 19 — `RemodalService.open` now merges (`{ ...modal.serviceOverrides, ...opts }`) instead of replacing (confirmed via system-reminder)
- Item 20 — `RemodalService.lookup` returns `undefined` on miss and both `open`/`close` reject with a real `Error` carrying the diagnostic message when `assert` is stripped in production (confirmed via system-reminder)
- Item 21 — `.invisible.remodal.window` CSS now uses `pointer-events: none` + `pointer-events: auto` on children so outside-clicks fall through the invisible card (confirmed via file read)
- Item 22 — `testem.cjs`'s `--no-sandbox` flag now triggers on `CI || CHROME_BIN`, not just `CI` (confirmed via system-reminder)

**Also done, completed by hand after the model switch:**
- The two blocking TypeScript errors were fixed: `acquireScrollLock`'s redundant `lockHolders.size === 1` recheck (TS narrowed it to an impossible comparison — simplified to just `if (wasEmpty)`), and `handleOpenClick`'s parameter widened to optional (`event?: Event`) so its signature satisfies `ErButtonSignature['onClick']` now that item 17 routes `m.open` through it.
- Item 23 — created `tests/helpers/remodal-test-helpers.ts` exporting `dialog()`, `lookupService()`, `pressEscape()`; all four test files (`ember-remodal-open-close-test.gts`, `ember-remodal-confirm-cancel-test.gts`, `remodal-service-test.gts`, `unit/remodal-service-test.ts`) now import from it instead of redefining. Manual `classList.contains` assertions converted to `qunit-dom` (`assert.dom(...).hasClass/doesNotHaveClass`); manual `assert.ok(find(...))` converted to `assert.dom(...).exists()`.
- Item 24 — regression tests added for every CONFIRMED finding: chained reopen surviving the stale queued `close` event; `service.open()` called during the initial render pass; `isOpen` staying true through `'closing'` (asserted directly on the getter, synchronously before/after `close()`'s first await — DOM/qunit-dom timing turned out to be unreliable for this one since `click()` awaits the whole transition internally); a checkbox inside `m.confirm` keeping its native toggle; service-override merge behavior (both a rendering-level and a unit-level test); the registry name-snapshot behavior (register as "snap", override name via service, close, unrender, then assert `service.open('snap')` still throws instead of resolving against a stranded destroyed instance).
- Item 25 — found and fixed one existing test that asserted the *old, incorrect* precedence ("direct args take precedence over @options"); flipped its expectation and renamed it to match the corrected v1-parity behavior fixed in item 4.
- **Not attempted**: a dedicated test for item 20's production-build rejected-promise behavior — `@ember/debug`'s `assert` is not stripped in this test environment (`isDevelopingApp()` is true), so the dev-mode `assert.throws(...)` path is what's actually exercised; simulating a stripped-assert production build would need a separate build-mode test setup, judged not worth the complexity for this pass.

**Verified state of the working tree (uncommitted) as of this pause:**
- `pnpm lint:types` — **green** (0 errors)
- `pnpm lint:js` — **green**
- `pnpm lint:hbs` — **green** (after adding a `<label>` around the new regression test's checkbox to satisfy `require-input-label`)
- `pnpm format` — **applied** (reflowed a few files; no logic changes)
- `pnpm build` — **green**
- `CI=1 CHROME_BIN=/opt/pw-browsers/chromium pnpm test` — **green, 56/56 passing** (up from 49; +7 new regression tests, 1 existing test corrected)
- `pnpm lint:format` and `pnpm lint:publish` — **not re-run this pass**, should be checked in Phase 6 alongside a final full `pnpm lint`

**NOT yet done (still pending — paused here):**
- Item 26 — `MIGRATION.md` additions: removed service alias properties, production-build rejected-promise behavior change, the Chromium double-Escape platform caveat, explicit statement of `@options` precedence
- Item 27 — `README.md` additions: custom open/close animations must keep the `remodal-` keyframe-name prefix to be awaited; brief mention of the Escape caveat in the accessibility section
- A personal review pass over the full fix-pass diff (same rigor as Phase 2/4) — not yet done since this pass was paused before reaching Phase 6
- Committing and pushing

### Phase 6 — Final verification, commit, push (⬜ not started)
- Complete Phase 5 items 26–27 (MIGRATION.md / README.md updates).
- Run the full `pnpm lint` suite (format/hbs/js/types/publish) once more end to end, plus `pnpm build` and the test suite, as a final gate.
- Review the fix-pass diff personally (same rigor as Phase 2) before committing.
- Commit (message should reference the review findings fixed, similar style to the two prior commits).
- Delete this `PLAN.md` before the final push (working notes, not part of the addon) — or ask the user first if they'd like it kept as a design doc.
- Push to `claude/ember-remodal-modernize-he3lc5` with `git push -u origin claude/ember-remodal-modernize-he3lc5`.
- Do **not** open a PR unless the user explicitly asks.

**Next action when development resumes:** items 26–27 (doc updates), then Phase 6.

## Commits so far

```
be07967 Add test suite, demo app, and rewritten docs
d4730c6 Reimplement modal on native <dialog>, dropping remodal and jQuery
9c0580b Replace v1 addon scaffolding with official v2 addon blueprint
df25509 Merge pull request #52 from luma-institute/master   <- branch point (origin/master)
```
Plus the uncommitted Phase 5 fix-pass described above, currently non-type-checking.

## Environment notes
- Package manager: pnpm (matches the blueprint's `--pnpm` scaffold choice; pnpm 10.33 available).
- Chrome for headless testing: `/opt/pw-browsers/chromium` (Playwright's bundled Chromium) — pass via `CHROME_BIN=/opt/pw-browsers/chromium` env var, which `testem.cjs` was extended to honor (Phase 2/5).
- No CLAUDE.md exists anywhere in this repo or its ancestors — confirmed during the Phase 4 review's conventions-angle pass, so no project-specific conventions apply beyond what's captured here.
