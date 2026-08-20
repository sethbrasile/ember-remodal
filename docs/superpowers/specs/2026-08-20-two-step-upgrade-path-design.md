# Two-step 2.x → 3.0 upgrade path (er-f0t) — design

Bead: `er-f0t` (children `er-f0t.1`–`.4`) · date: 2026-08-20 · spec by Fable 5
from the 2026-08-19 Opus scouting notes in the epic.

## Goal

Make the 2.x → 3.0 upgrade a two-step, self-diagnosing path:

1. **ember-remodal 2.19.0** — the user upgrades to the last 2.x release, runs
   their real app, and every 3.0-breaking usage they actually exercise prints a
   `console.warn` naming the change and linking the fix.
2. **A readiness audit prompt** — pasted into any coding assistant, it
   statically audits the app for the breaks runtime warnings cannot see (CSS
   selectors, test selectors, markup assumptions, browser/Ember floors).
3. **Guides** — MIGRATION.md, the demo's migration page, and the README teach
   the two-step path as the recommended route.

The two artifacts cover **disjoint halves** of the break surface; neither is a
wrapper around the other.

## Decisions (locked in this spec)

| # | Open question | Decision | Why |
|---|---|---|---|
| 1 | `console.warn` vs `Ember.deprecate` | **`console.warn`**, via an internal `warnOnce()` util. Every message carries a stable id string (`ember-remodal.<slug>`) so it stays greppable/filterable. | `deprecate()` is stripped from production builds — and "upgrade, run your **real** app, read the console" is the whole point of step 1. `console.warn` also behaves identically across every consumer Ember version 2.12–3.x (`Ember.Logger` is deprecated in 3.2 and gone in 4.0), and it doesn't pollute consumer deprecation-workflow configs or fail `throwOnUnhandled` test setups. |
| 2 | Once-per-id guard | **Module-level id → seen map** inside `warnOnce`. One line per deprecation id per page load, regardless of how many modal instances trigger it; the message embeds first-offender context (arg name, modal `name`) where useful. `_resetWarnings()` is exported for tests. | Migration work is per-pattern, not per-instance — a list of 50 modals must not emit 50 identical lines. Keying by id alone (not id+instance) keeps the console readable; the fix is a grep either way. |
| 3 | Opt-out | **`ENV['ember-remodal'] = { silenceDeprecations: true }`**, read through the existing `config:environment` lookup (`_getConfig()` on the component; same pattern added to the service and er-button). Silences *every* 2.19 warning, including the v3-available pointer. | Apps staying on 2.x deliberately need a one-line off switch. Config-based (not runtime API) so it works before any modal renders. |
| 4 | Version pointer | **Yes** — `ember-remodal.v3-available` fires once from the component's `_checkForDeprecations`, telling the user 3.0 exists and naming the two-step path. | It is the discoverability entry point that makes the whole scheme findable. `forService` usage requires a rendered component, so the component hook covers every real consumer. |
| 5 | Where the readiness prompt lives | **One canonical copy: a fenced code block in MIGRATION.md's new "The two-step upgrade path" section.** The demo migration page inherits it automatically (it renders MIGRATION.md verbatim via the `?highlight` import); the demo additionally grows copy buttons on `.docs-markdown` code blocks. The README links to the section. **No `prompts/` directory** and no second copy anywhere. | Single source of truth by construction — the demo page cannot drift from MIGRATION.md because it *is* MIGRATION.md. GitHub renders fenced blocks with a native copy button, so the raw-file path is copy-friendly for free. A separate file would be a second copy to keep in sync for zero reach gain (MIGRATION.md is not in the 3.0 tarball `files` list either way; distribution is GitHub + the demo site). |
| 6 | Feasibility gate shape | **Three outcomes, not two** (see next section): GO / DEGRADED GO / NO-GO. | `npm pack` on a v1 addon needs no build — origin/master has no prepublish script and ships plain source that the *consumer's* build compiles. So "the 2018 dev toolchain is dead" does not by itself mean "2.19 is impossible"; it means validation moves to a minimal smoke app. |
| 7 | Branch & version | Maintenance branch **`2.x`** cut from `origin/master`; version **2.19.0**; published to the default **`latest`** dist-tag (current `latest` = 2.18.0; 3.0.0-beta.0 is configured for the `beta` tag and not yet published). | 2.19 stays `latest` until 3.0 goes stable — exactly right for a deprecation release. |
| 8 | Release ordering | **2.19 publishes only after MIGRATION.md is reachable at `blob/master/MIGRATION.md`** — i.e. after the modernize branch lands on `master`. | Every warning message links there. MIGRATION.md does not exist on today's `origin/master`; publishing first would ship dead links. |

## Feasibility gate (er-f0t.1) — go/no-go criteria

origin/master is ember-cli ~2.18.2 / ember-cli-babel ^6 / `engines.node: "^4.5
|| 6.* || >= 7.*"` / Travis CI on Node 6 — 2018 tooling. Local facts that make
the check cheap: `~/.nvm/versions/node/` already holds v6.17.1, v8.17.0,
v10.24.1 (and newer); no nvm shell integration is needed — prepend the
version's `bin` to `PATH`.

| Outcome | Criteria | Consequence |
|---|---|---|
| **GO** | Under a pinned old Node, `npm install` resolves and `ember build` succeeds, and the test suite is runnable — `ember test`, or (if modern Chrome breaks old testem) `ember serve` + visiting `/tests`. | Full plan: TDD the warnings against the dummy-app test suite on the `2.x` branch. |
| **DEGRADED GO** | The addon's own dev toolchain won't install/build (its dummy app drags heavy 2018 devDeps — stylus, font-awesome, coverage, github-pages), **but** `npm pack` produces a tarball that a *minimal* era-appropriate smoke app (fresh `ember-cli@2.18` app under the same pinned Node) installs and boots with a rendered `{{ember-remodal}}`. | Same code changes; validation moves to a smoke-app checklist page that exercises every deprecated usage, verified by reading the browser console. No automated test suite for the 2.x branch. |
| **NO-GO** | No pinned Node yields *any* bootable consumer of the packed addon. | Docs-only fallback: no 2.19. The readiness prompt absorbs the entire break surface (the runtime-detectable items become first-class static checks), and MIGRATION.md teaches a one-step, audit-first path. `er-f0t.2` closes as wontfix. |

Known sub-risk, pre-decided: **modern Chrome vs. 2018 testem** may break
`ember test` at browser launch even though the build works. That still counts
as GO if `/tests` runs in a served browser session; it is a runner problem, not
a toolchain death.

The gate's outcome is recorded in a feasibility report
(`docs/superpowers/plans/2026-08-20-feasibility-report.md`) and on the bead
before any 2.19 code is written.

## 2.19 runtime deprecation catalog (er-f0t.2)

Message format, produced by `warnOnce`:

```
[ember-remodal] DEPRECATION (<id>): <message> See https://github.com/sethbrasile/ember-remodal/blob/master/MIGRATION.md#<anchor>
```

| id (`ember-remodal.` prefix) | Fires when | Detection point | MIGRATION.md anchor |
|---|---|---|---|
| `v3-available` | Always, once, on first modal render | `_checkForDeprecations` | `the-two-step-upgrade-path` (new section, Task 7) |
| `string-actions` | Any of `onOpen`/`onClose`/`onConfirm`/`onCancel` is a string | `_checkForDeprecations`: `typeof this.get(name) === 'string'` | `string-actions--function-arguments` |
| `hash-tracking` | `hashTracking` is truthy | `_checkForDeprecations` | `hashtracking-removed` |
| `class-attribute` | `this.get('class')` is present (curly `class=` merge) | `_checkForDeprecations` | `ember-remodal-class-no-longer-merges-class` |
| `service-option-aliases` | Get **or** set of any of the service's 14 option aliases (`title`, `text`, `confirmButton`, `cancelButton`, `disableNativeClose`, `disableForeground`, `disableAnimation`, `buttonClasses`, `modifier`, `closeOnEscape`, `closeOnCancel`, `closeOnConfirm`, `hashTracking`, `closeOnOutsideClick` — the epic said 16; the file has 14) | Each `alias(...)` is replaced by a local `deprecatedOptionAlias()` computed that warns, then delegates with identical get/set semantics | `the-services-property-aliases-are-removed` |
| `component-via-service` | Component `open()`/`close()` called from anywhere but the service | The service passes an `INTERNAL_CALL` sentinel; the component warns when it is absent. Covers the terminal step of every documented reach-through flow (`service.get('name').open()` etc.). Boundary: bare `setProperties`/`set` on the reached component without a subsequent `open()` is *not* runtime-detectable and belongs to the audit prompt's grep list. | `reaching-the-modal-component-through-the-service-is-removed` |
| `modal-property` | External read of the component's `modal` property (the wrapped jQuery remodal instance, incl. `getState()`) | The instance moves to a private `_remodalInstance`; `modal` becomes a warn-then-delegate computed. All internal readers are renamed, so internal use never warns. | `the-modal-property-and-getstate-is-removed` |
| `open-on-unrendered-name` | `service.open()`/`close()` for a name with no rendered modal | `_modalNotSetError`, warning **before** the existing `assert` — the assert is stripped in production builds, so today this case silently no-ops in prod; 3.0 rejects in every build | `serviceopen--close-on-an-unrendered-name-always-reject` |
| `er-button-direct` | `{{ember-remodal/er-button}}` invoked directly rather than via the yielded `m.open`/`m.confirm`/`m.cancel` | The yield hash curries a private `_yielded=true`; er-button warns in `didInsertElement` when it is absent | `er-button-the-import-path-moved-and-both-arguments-were-renamed` |
| `disable-animation-while-testing` | `disableAnimationWhileTesting` found in config (test env only, by nature) | `_checkForTestingEnv` | `disableanimationwhiletesting--classic-resolver-only` |

**Explicitly excluded from runtime detection:** RSVP-specific consumption of
the promises returned by `open()`/`close()` (`instanceof RSVP.Promise` checks,
reliance on autorun/runloop timing in `.then` callbacks). Runtime detection
would be guesswork; this moves wholesale to the audit prompt.

**Untouched:** the pre-existing `Ember.Logger.warn` with the typo'd id
`ember-remodal.close-called-on-unitialized-modal` keeps its 2.x id and channel.
Changing it mid-2.x would break existing `registerWarnHandler` filters; the
typo fix is a documented 3.0 change and the audit prompt greps for filters on
the old spelling.

## Readiness audit prompt (er-f0t.3)

Agent-agnostic (Claude Code / Cursor / Copilot) markdown prompt. Contract:

- **Checks 0a/0b — hard floors first:** Ember >= 5.8 (`package.json`) and the
  browser floor Chrome/Edge 99, Firefox 98, Safari 15.4 (browserslist config).
  Either unmet ⇒ verdict **NOT READY** regardless of everything else — there
  is no polyfill path.
- **Core checks (the runtime-invisible surface):** bare single-word class
  hooks in stylesheets/tests (`.window`, `.close`, `.button`, `.open`,
  `.link`, `.text`, `.outer`, `.inner`, `.title`, `.paragraph`, `.yielded`,
  `.content`, `.native`, `.confirm`, `.cancel`, `.invisible` — flagged only
  when they target ember-remodal markup; `@legacyClassNames={{true}}` named as
  the bridge, per-modal and temporary); `data-remodal-id` selectors;
  `.remodal-overlay` → `dialog.remodal-wrapper::backdrop`; backdrop-dismiss
  tests (3.0 needs `mousedown` *and* `click` on the backdrop); yielded
  `m.open`/`m.confirm`/`m.cancel` blocks with no focusable control; direct
  `er-button` usage (import path, `modalId=` → `@destination` Element,
  `action=` → `@onClick`); confirm/cancel visual conflicts now that
  `remodal-confirm`/`remodal-cancel` styling applies; consumer `!important`
  overrides that now lose to the two layered `!important` declarations (fix:
  declare your own `@layer` after `ember-remodal`); `registerWarnHandler`
  filters on the typo'd warning id; RSVP-specific promise consumption.
- **Appendix — double-check greps** for the runtime-covered items (string
  actions, `hashTracking`, service aliases, service reach-through, curly
  `class=`, `disableAnimationWhileTesting`), so a user who skipped step 1
  still gets full coverage. One grep line each, no prose.
- **Output contract:** a "readiness report" with a verdict — `READY` /
  `READY WITH CHANGES` / `NOT READY` — a per-check table (status, findings as
  `file:line`, fix), and an ordered fix list. Findings require file:line
  evidence; a check with none is marked clear. No maybes.
- **Dogfood target:** the 2.x dummy app on `origin/master`
  (`tests/dummy/`), which exercises most of the old surface. Dogfooding is
  static (greps over a checkout) so it works under every feasibility outcome.

## Guides (er-f0t.4)

- **MIGRATION.md** gains a top section `## The two-step upgrade path` (after
  the intro, before Requirements; added to the TOC): step 1 — upgrade to
  2.19, run the app, fix every `[ember-remodal] DEPRECATION` line (notes:
  warnings survive production builds, fire once per id, and
  `silenceDeprecations` exists); step 2 — run the readiness audit prompt
  (fenced block lives here); then upgrade. The `v3-available` warning links to
  this anchor.
- **README** — the install/upgrade section gets a short "Upgrading from 2.x?"
  pointer to the MIGRATION.md section.
- **Demo** — migration page inherits the MIGRATION.md edit; `.docs-markdown`
  code blocks gain a copy button (clipboard logic reused from
  `demo-example.gts`), covering the prompt block and every other snippet.
- **Anchor integrity:** every anchor used in a 2.19 warning message is
  verified against MIGRATION.md's actual heading slugs before release (the
  plan carries a slug-check step).

## Non-goals

- **No behavior changes in 2.19 beyond warnings.** 2.18 → 2.19 must be a
  zero-risk upgrade; every warning path delegates to the exact pre-existing
  behavior.
- No changes to 3.0 addon code (`src/`) anywhere in this epic.
- No codemod; the audit prompt is the automation story.
- No re-plumbing of the existing `close-called-on-unitialized-modal` warning.

## Risks

- **2018 toolchain rot** — mitigated by the three-outcome gate running first.
- **Modern Chrome vs old testem** — pre-decided above (GO via served `/tests`).
- **Anchor drift** between warning messages (frozen at publish) and
  MIGRATION.md headings (living document) — mitigated by the slug-check step
  and by decision 8's ordering; after 2.19 publishes, renaming those headings
  becomes a breaking docs change.
- **Two-branch drift** — the `2.x` branch and `master` describe the same
  contract from opposite sides; the deprecation catalog table above is the
  single list both sides implement against.
