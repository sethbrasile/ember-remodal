# Demo app: interactive docs site (er-1u2) — design

Bead: `er-1u2` · blocks PR #59 merge · date: 2026-08-19

## Goal

Replace the single-page `demo-app/` with a multi-route documentation site that
meets or exceeds the 2.x dummy app (9 sections / 25 routes, live example beside
highlighted source on every page, action hooks visualised, state-driven and
promise-chain demos, deployed to GitHub Pages and linked from the README), and
additionally documents what is new in 3.0 (native `<dialog>`, a11y naming,
`CloseReason`, `@layer` theming, reduced-motion, forced-colors, lazy content).

## Decisions (locked in brainstorming)

| Decision | Choice | Why |
|---|---|---|
| IA | Modern task-oriented IA, full coverage of every 2.x topic; 2.x URLs not preserved | Better for 3.0 users; every 2.x section still has a home |
| Example authoring | One `.gts` file per example, imported once to render and once via `?highlight` to display | Source-beside-example is enforced by construction; no drift |
| Highlighter | Shiki at build time through a small Vite plugin (`glimmer-ts` grammar) | Correct .gts highlighting, zero runtime JS, devDependency only |
| Shell | Left-sidebar docs shell; extend existing `demo-app/styles.css` (hero, `demo-midnight`); no CSS framework | Scales to ~16 pages; modal theme stays the star |
| Deploy | GitHub Pages via Actions from `master`, `history` location + `404.html` fallback | Clean URLs; matches 2.x "deployed and linked" |

## Non-goals

- No changes to `src/` (addon behavior, styles, types) — this is demo/docs only.
- No markdown docs framework (docfy/kolay), no ember-notify, no Bootstrap.
- No user-editable playground; source panels are read-only with a copy button.
- No preservation of 2.x demo URLs.

## 1. Information architecture

Base URL: `https://sethbrasile.github.io/ember-remodal/`. Routes are kebab-case;
sidebar groups in this order. 16 routes.

| Group | Route | Contents (prose + live examples) |
|---|---|---|
| Getting started | `/` | Hero with a live modal (image inside), install snippet, "What's new in 3.0" bullets, links to npm / GitHub / Migration |
| | `/install` | Install, CSS import (`ember-remodal/ember-remodal.css`, `@layer ember-remodal` note), strict-resolver registration (the demo's own `app.gts` `modules` block is the example) vs classic app |
| Usage | `/usage/inline` | `@title`/`@text`/`@openButton`; with classes/modifier; with function actions |
| | `/usage/block` | Block form; lazy content via `m.isOpen` (3.0-only) |
| | `/usage/yielded` | `m.open` / `m.confirm` / `m.cancel`; `openAction`/`closeAction`/`confirmAction`/`cancelAction` bare functions; direct `ErButton` import |
| Service & state | `/service` | `@forService`, `open(name, options)`, named modals, options passed at open, rejection on unrendered name |
| | `/service/promises` | Promise playground: open→close chain; open-over-open; await open then mutate — three buttons + event log |
| | `/state` | Dog list → `selectedDog` → one `@forService` modal whose content is driven by state |
| Options reference | `/options/content` | title, text, confirmButton, cancelButton, openButton, openLink, linkButton, closeButtonLabel, ariaLabel, ariaLabelledBy, name, dataTestId — table + example |
| | `/options/behavior` | closeOnEscape, hasCustomKeyboardExit, closeOnCancel, closeOnConfirm, closeOnOutsideClick, disableNativeClose, disableAnimation, disableForeground — table + toggleable example |
| | `/options/classes` | modalClasses, buttonClasses, outerButtonClasses, innerButtonClasses, openButtonClasses, openLinkClasses, cancelButtonClasses, confirmButtonClasses, modifier, legacyClassNames — table + example |
| | `/options/actions` | onBeforeOpen, onOpen, onConfirm, onCancel, onClose(reason) — every hook fires a toast; `CloseReason` values enumerated and each demonstrable (Escape, backdrop, ✕, cancel, confirm, service `close()`) |
| Styling | `/styling` | `@layer ember-remodal`, targeting `::backdrop` / dialog / buttons, the `demo-midnight` `@modifier` theme, reduced-motion and forced-colors demos |
| Accessibility | `/accessibility` | Native `<dialog>`, naming attributes, focus behavior, Escape force-close rules, focusable-control requirement in yielded blocks |
| Testing | `/testing` | `ember-remodal/test-support` helpers, awaited animations, selector updates, `disableAnimationWhileTesting` note |
| Migration | `/migration` | `MIGRATION.md` rendered at build time (single source) |

Each options-reference table row: name · type · default · one-line description,
hand-maintained in the page (the types in `src/components/ember-remodal.gts`
are the source of truth; the `lint:types` pass catches a renamed arg because the
examples use them).

Dropped from 2.x deliberately: the standalone "legacy" component page (covered
by `legacyClassNames` on `/options/classes`), the PayPal "buy Seth a beer" form,
the `example` page (superseded by per-page examples).

## 2. Example mechanism

### Files

```
demo-app/
  app.gts                      # router map + modules (existing)
  styles.css                   # extended, not replaced
  vite/highlight.mjs           # ?highlight Vite plugin (dev-only)
  components/
    docs-shell.gts             # top bar + sidebar + main + footer + toast region
    sidebar-nav.gts
    demo-example.gts           # live panel + source panel + copy button
    demo-toasts.gts            # renders the demo-toasts service queue
    demo-log.gts               # timestamped event log with clear
    options-table.gts          # name/type/default/description table
  services/
    demo-toasts.ts             # push(message, {badge?}) ; auto-dismiss
  examples/
    <group>/<name>.gts         # one real component per example
  templates/
    application.gts            # <DocsShell>{{outlet}}</DocsShell>
    index.gts, install.gts
    usage/{inline,block,yielded}.gts
    service/{index,promises}.gts
    state.gts
    options/{content,behavior,classes,actions}.gts
    styling.gts, accessibility.gts, testing.gts, migration.gts
```

Routes/templates follow the strict-resolver `./templates/**` glob already in
`app.gts`; `Router.map` lists the 16 routes.

### Rendering an example

```ts
import InlineSimple from '../../examples/usage/inline-simple.gts';
import inlineSimpleSrc from '../../examples/usage/inline-simple.gts?highlight';

<DemoExample @title="Simple inline modal" @component={{InlineSimple}} @source={{inlineSimpleSrc}} />
```

`DemoExample` is the only component that renders code on the site, so every
shown source is the literal file that runs. Layout: live panel and source panel
side by side at ≥ 900 px, stacked with a Live/Source tab switch below that.
Copy button uses `source.text`.

### `?highlight` Vite plugin

`demo-app/vite/highlight.mjs`, registered only in `vite.config.mjs` (never in
rollup/publish config). Behavior:

- Matches `*.gts|*.ts|*.md` with query `?highlight`.
- Reads the file from disk. For code: strips a leading `// demo-hide … // demo-show` block if present (demo-only glue that should not appear in the source panel).
- Shiki `codeToHtml` with lang `glimmer-ts` / `typescript` / `markdown`, one dark theme chosen to sit with the demo palette.
- For `.md`: markdown → HTML via `marked`, fenced code blocks highlighted by the same Shiki instance (a single shared highlighter instance, created lazily).
- Exports `{ html: string, text: string, lang: string }`.
- Declares the virtual module types in `unpublished-development-types/` (`declare module '*?highlight'`).

New devDependencies: `shiki`, `marked`. Both audited (`pnpm audit`) before
adding.

## 3. Shell and interactive components

- **DocsShell**: top bar (package name, version read from `package.json` at build time, GitHub and npm links), left `SidebarNav` (grouped `<LinkTo>`s, current-route highlight, collapses behind a disclosure button < 900 px), `<main>` with `{{outlet}}`, footer, `<DemoToasts>` live region. `ember-page-title` per page.
- **DemoToasts** service + component: `push(message, { badge? })`, auto-dismiss ~4 s, `aria-live="polite"`. Used by `/options/actions`, `/service`, `/service/promises` to visualise `onBeforeOpen/onOpen/onConfirm/onCancel/onClose(reason)`; the `CloseReason` is rendered as a badge.
- **DemoLog**: timestamped lines, clear button; used by promise playground and state page.
- **State demo**: list of dogs (name, breed, image), clicking one sets `selectedDog` and calls `remodal.open('dog-detail')`; a single `@forService` modal renders `selectedDog`.
- **Reduced-motion / forced-colors**: demo-local toggles add classes on the example container that mirror the media-query rules, so the behavior is visible without OS changes (the addon CSS is not modified; the demo CSS re-states the rule under the class).
- Styles: extend `demo-app/styles.css` with shell, sidebar, example-panel, code-panel, toast, log, table rules, reusing the existing tokens and `demo-midnight` theme.

## 4. Build, deploy, README

- `vite.config.mjs`: add `demo` mode — `base: '/ember-remodal/'`, `rollupOptions.input: 'index.html'`, `outDir: 'dist-demo'`; register the highlight plugin in all modes (it is inert unless imported). Default mode unchanged (tests input).
- `demo-app/app.gts`: `rootURL = import.meta.env.BASE_URL` (`/` under `pnpm start`, `/ember-remodal/` under the Pages build).
- `package.json` scripts: `build:demo` → `vite build --mode=demo && node ./scripts/emit-demo-404.mjs` (copies `dist-demo/index.html` to `dist-demo/404.html` — GitHub Pages SPA fallback for `history` location).
- `.gitignore`: add `dist-demo/`.
- `.github/workflows/deploy-demo.yml`: `on: push (master)` + `workflow_dispatch`; top-level `permissions: {}`; job `permissions: pages: write, id-token: write`; concurrency group `pages`; every action pinned to a commit SHA (same rule as `push-dist.yml`); steps: checkout (`persist-credentials: false`) → pnpm setup → setup-node 22 → `pnpm install --frozen-lockfile` → `pnpm build:demo` → `actions/configure-pages` → `actions/upload-pages-artifact` (`dist-demo`) → `actions/deploy-pages`.
- **Manual, one-time (Seth):** GitHub repo Settings → Pages → Build and deployment → Source = "GitHub Actions". Deleting the legacy `gh-pages` branch is a remote delete — surface separately, never automatic.
- `README.md`: restore a top line under the badge: `**[Interactive demo & documentation](https://sethbrasile.github.io/ember-remodal)**`.
- `MIGRATION.md` is rendered by `/migration`; no duplication.

## 5. Verification

- `ci.yml`: new `Demo` job — install, `pnpm build:demo`; fails on any broken route/import/highlight.
- `tests/rendering/demo-examples-test.gts`: `import.meta.glob('../../demo-app/examples/**/*.gts', { eager: true })`, renders each exported component, asserts render succeeds and a `dialog` element is present (or the example is marked `noDialog` via a named export). One test covers every example forever.
- Existing `lint:types` / `lint:js` / `lint:hbs` / `lint:format` already include `demo-app/` (tsconfig `include` has it).
- Tarball: `package.json#files` is an allowlist — `demo-app/`, `dist-demo/`, `docs/`, the Vite plugin are excluded by construction; `verify:published-package` and `lint:publish` must stay green; `shiki`/`marked` are devDependencies.
- `pnpm start` still serves the demo at `/` with hot reload.

## Acceptance (from er-1u2, restated)

- [ ] 16 routes with persistent sidebar nav; every 2.x section has a 3.0 counterpart plus the 3.0-only pages.
- [ ] Every live example sits beside its highlighted source, imported from the same file.
- [ ] Action hooks and `CloseReason` visualised via toasts.
- [ ] State-driven (dog list) and promise-chain playground reproduced.
- [ ] Deployed to GitHub Pages via Actions from `master`, linked at the top of README; MIGRATION surfaced.
- [ ] `pnpm start`, `pnpm test`, `pnpm lint`, `pnpm build:demo` all green in CI; published tarball unchanged.
