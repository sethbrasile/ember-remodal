# Demo Docs Site Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single-page `demo-app/` with a 16-route documentation site (persistent sidebar, every live example beside its highlighted source, action hooks visualised, state/promise demos), built with Vite and deployed to GitHub Pages from `master`.

**Architecture:** The demo stays a strict-resolver Ember app under `demo-app/` (entry `index.html` → `demo-app/app.gts`). Each example is a self-contained `.gts` component under `demo-app/examples/`, imported by a page once to render and once through a `?highlight` Vite plugin (Shiki, build-time) to display. A `DocsShell` component provides nav + toast region; pages are route templates under `demo-app/templates/`. A `demo` Vite mode builds to `dist-demo/` with `base: /ember-remodal/`; a Pages workflow deploys it.

**Tech Stack:** Ember 6 / Glimmer `.gts`, `ember-strict-application-resolver`, Vite 7 + `@embroider/vite`, Shiki 4 (`glimmer-ts` grammar), `marked` 18 (Migration page), GitHub Actions Pages deploy. No new Ember addons.

**Spec:** `docs/superpowers/specs/2026-08-19-demo-docs-site-design.md` — read it first; this plan implements it section by section.

**Executor guidance:** This plan intentionally gives contracts (file paths, export names, signatures, markup/class names, behaviors, exact commands and expected results) rather than finished code. Follow the contracts literally; where a detail is not specified, copy the conventions of the neighbouring existing code (`demo-app/templates/application.gts` before you delete it, `tests/rendering/ember-remodal-rendering-test.gts`, `src/components/ember-remodal.gts`). Do not modify anything under `src/`.

## Global Constraints

- **`src/` is read-only for this plan.** No addon behavior, style, or type changes.
- **Every code/source shown on the site comes through `?highlight`** from the same file that renders. No pasted code strings in page templates, ever. (Short inline `<code>` mentions of an arg name in prose are fine.)
- **Source-of-truth files for facts:** arg names/defaults → `src/components/ember-remodal.gts` (interface `EmberRemodalOptions` lines 19–83, defaults in the `get` accessors around lines 410–575; `closeButtonLabel` default `'Close Modal'`; `name` default `'ember-remodal'`); service API → `src/services/remodal.ts` (`open(name = 'ember-remodal', opts?)`, `close(name = 'ember-remodal')`, both return `Promise<EmberRemodal>` and **reject** if no modal with that name is rendered); test helpers → `src/test-support/index.ts` (JSDoc on each export); 3.0 changes → `MIGRATION.md`; palette tokens → `src/styles/ember-remodal.css` lines 86–120; CSS media blocks → same file lines 436–490. `CloseReason` is `'confirmation' | 'cancellation'`; `onClose` receives `undefined` for Escape, backdrop click, the ✕ button, and `service.close()`.
- **Lint/format gates:** `pnpm lint` (eslint, template-lint, prettier, tsc, audit) must pass at the end of every task. Run `pnpm format` before committing. Fix lint findings by changing code, never by disabling rules (`{{! template-lint-disable }}` / `eslint-disable` are not allowed in this plan). Template-lint forbids `{{{triple-curlies}}}`: render trusted HTML with `htmlSafe` from `@ember/template`.
- **Tarball:** `package.json#files` is an allowlist (`addon-main.cjs`, `declarations`, `dist`, `src`). Nothing in this plan touches it. `shiki` and `marked` go in `devDependencies` only. Run `pnpm audit --audit-level=high` right after adding each dependency; if it reports high/critical in the new package, stop and report instead of continuing.
- **Routing:** Router `location = 'history'`, `rootURL = import.meta.env.BASE_URL`. Vite sets `BASE_URL` to `/` in dev/test and to `/ember-remodal/` in `demo` mode.
- **Strict resolver:** route templates live at `demo-app/templates/<route path>.gts` and are picked up by the existing `import.meta.glob('./templates/**/*', { eager: true })` in `demo-app/app.gts`. Nested route templates: `templates/usage/inline.gts` ⇒ route `usage.inline`. Parent routes (`usage`, `service`, `options`) need **no** template file — Ember renders `{{outlet}}` by default. The `/` page is `templates/index.gts`; `/service` is `templates/service/index.gts`. Services live at `demo-app/services/<name>.ts` and are picked up by the existing `./services/**/*` glob.
- **Component/page authoring:** `.gts` files with `<template>` tags, `@glimmer/component` where state is needed, plain template-only components otherwise. Import addon pieces via `#src/...` (e.g. `import EmberRemodal from '#src/components/ember-remodal.gts'`), exactly as the current demo does. Import `LinkTo` from `@ember/routing`, `on` from `@ember/modifier`, `service` from `@ember/service`, `pageTitle` from `ember-page-title`.
- **Accessibility of the demo itself:** every interactive element is a real `<button type="button">` / `<a>` / `<input>`; every `<input>` has a `<label>`; every image has `alt`; the toast region is `role="status" aria-live="polite"`.
- **Commits:** one commit per task (conventional message given in each task). Push is not part of this plan.
- **Verification vocabulary used below:** "`pnpm start` shows …" means: run `pnpm start`, open the printed URL in a browser (or use the browser tools), navigate, and confirm the statement; stop the dev server afterwards. `pnpm test` runs the whole suite headless (takes a couple of minutes) and must end with `# ok` / 0 failures.

---

### Task 1: Router, docs shell, and 16 scaffold pages

**Files:**
- Modify: `demo-app/app.gts` (router map, `rootURL`)
- Modify: `demo-app/templates/application.gts` (replace contents with the shell; the current six sections are **re-created as examples in later tasks**, so keep a copy of the file in your scratchpad for reference, then overwrite)
- Create: `demo-app/components/docs-shell.gts`, `demo-app/components/sidebar-nav.gts`
- Create: 16 route templates (list below), each a scaffold
- Modify: `demo-app/styles.css` (shell/sidebar rules appended)
- Modify: `vite.config.mjs` (expose the version via `define`)
- Modify: `unpublished-development-types/index.d.ts` (type for the version)

**Interfaces:**
- Produces: route names and URLs (used by every later task):

  | Route name | URL | Template file |
  |---|---|---|
  | `index` | `/` | `templates/index.gts` |
  | `install` | `/install` | `templates/install.gts` |
  | `usage.inline` | `/usage/inline` | `templates/usage/inline.gts` |
  | `usage.block` | `/usage/block` | `templates/usage/block.gts` |
  | `usage.yielded` | `/usage/yielded` | `templates/usage/yielded.gts` |
  | `service.index` | `/service` | `templates/service/index.gts` |
  | `service.promises` | `/service/promises` | `templates/service/promises.gts` |
  | `state` | `/state` | `templates/state.gts` |
  | `options.content` | `/options/content` | `templates/options/content.gts` |
  | `options.behavior` | `/options/behavior` | `templates/options/behavior.gts` |
  | `options.classes` | `/options/classes` | `templates/options/classes.gts` |
  | `options.actions` | `/options/actions` | `templates/options/actions.gts` |
  | `styling` | `/styling` | `templates/styling.gts` |
  | `accessibility` | `/accessibility` | `templates/accessibility.gts` |
  | `testing` | `/testing` | `templates/testing.gts` |
  | `migration` | `/migration` | `templates/migration.gts` |

- Produces: `DocsShell` (default export of `components/docs-shell.gts`) — a component with a default block; renders the top bar, `SidebarNav`, `<main class="docs-main">{{yield}}</main>`, footer. (Task 3 adds the toast region inside it.)
- Produces: `SidebarNav` (default export of `components/sidebar-nav.gts`) — no args; renders the grouped nav. Groups and labels, in order: **Getting started** (Home→`index`, Install→`install`); **Usage** (Inline→`usage.inline`, Block→`usage.block`, Yielded controls→`usage.yielded`); **Service & state** (Service→`service.index`, Promises→`service.promises`, State-driven→`state`); **Options** (Content→`options.content`, Behavior→`options.behavior`, Classes→`options.classes`, Actions→`options.actions`); **Styling** (Styling & theming→`styling`); **Accessibility** (Accessibility→`accessibility`); **Testing** (Testing→`testing`); **Migration** (Migrating from 2.x→`migration`).
- Produces: `import.meta.env.DEMO_VERSION: string` — the `package.json` version, injected by Vite `define`.

- [ ] **Step 1: Router.** In `demo-app/app.gts` set `rootURL = import.meta.env.BASE_URL` and fill `Router.map` with the 16 routes above (`this.route('usage', function () { this.route('inline'); … })`; `service` has `promises` as its only child so `/service` resolves to `service.index`). Keep `location = 'history'`.
- [ ] **Step 2: Version define.** In `vite.config.mjs` read `package.json` (`readFileSync` + `JSON.parse`, or `createRequire`) and add `define: { 'import.meta.env.DEMO_VERSION': JSON.stringify(pkg.version) }`. In `unpublished-development-types/index.d.ts` add a global augmentation `interface ImportMetaEnv { readonly DEMO_VERSION: string }` (Vite's `ImportMetaEnv` is an open interface; keep the existing `declare module '*.css'`).
- [ ] **Step 3: SidebarNav.** `<nav class="docs-nav" aria-label="Documentation">`; each group is a `<div class="docs-nav-group">` with a `<h2 class="docs-nav-heading">` and a `<ul>`; each item is `<li><LinkTo @route="…">Label</LinkTo></li>`. `LinkTo` adds `class="active"` on the current route automatically — style that. Below 900 px the nav is hidden behind a `<button type="button" class="docs-nav-toggle" aria-expanded aria-controls>` that toggles a tracked `open` flag (class `is-open` on the nav); above 900 px it is always visible and the toggle is hidden via CSS.
- [ ] **Step 4: DocsShell.** Structure: `<header class="docs-topbar">` with `<a class="docs-brand" href={{rootURL}}>ember-remodal</a>` (use `<LinkTo @route="index">` instead of a raw href), a `<span class="docs-version">v{{version}}</span>` reading `import.meta.env.DEMO_VERSION`, and links "GitHub" → `https://github.com/sethbrasile/ember-remodal` and "npm" → `https://www.npmjs.com/package/ember-remodal` (`target="_blank" rel="noreferrer"`). Then `<div class="docs-layout">` containing `<SidebarNav />` and `<main class="docs-main">{{yield}}</main>`. Footer: keep the current footer text ("MIT licensed. Styles ported from Remodal by Ilya Makarov." with the link).
- [ ] **Step 5: application.gts.** Replace the file with: `{{pageTitle "ember-remodal"}}` and `<DocsShell>{{outlet}}</DocsShell>`. Nothing else.
- [ ] **Step 6: Scaffold pages.** Create all 16 templates. Each contains exactly: `{{pageTitle "<Page title>"}}`, `<h1>` with the page title, and one `<p class="docs-lede">` sentence saying what the page will cover (later tasks replace these). Page titles: Home → `ember-remodal` (the index page uses `<h1>ember-remodal</h1>` plus tagline), Install, Inline usage, Block usage, Yielded controls, The remodal service, Promises, State-driven modals, Content options, Behavior options, Class options, Action hooks, Styling & theming, Accessibility, Testing, Migrating from 2.x.
- [ ] **Step 7: Styles.** Append to `demo-app/styles.css` (keep everything already there; the `.demo` max-width wrapper rule may be removed since pages now live in `.docs-main`): `.docs-topbar` (sticky top, surface background, bottom border, flex, gap), `.docs-brand` (bold, ink colour, no underline), `.docs-version` (muted, monospace), `.docs-layout` (CSS grid `16rem 1fr` at ≥ 900 px, single column below), `.docs-nav` (sticky under the topbar, scrollable, padding), `.docs-nav-heading` (uppercase, 0.75rem, muted, letter-spacing), `.docs-nav a` (block, padding, ink, no underline) and `.docs-nav a.active` (accent colour + left border or background tint), `.docs-nav-toggle` (hidden ≥ 900 px; below: visible button, nav hidden unless `.is-open`), `.docs-main` (max-width 52rem, padding 2rem 1.25rem 4rem), `.docs-lede` (muted, 1.1rem). Reuse the existing `--demo-*` tokens.
- [ ] **Step 8: Verify.** `pnpm lint` passes. `pnpm start` shows: the top bar with version `v3.0.0-beta.0`, the sidebar with 8 groups / 16 links, clicking each link changes the URL (no full reload) and renders the right `<h1>`; the browser tab title reads e.g. `Inline usage | ember-remodal`; at a 600 px-wide window the nav collapses behind the toggle and opens when clicked.
- [ ] **Step 9: Commit.** `feat(demo): router, docs shell, and scaffold pages for the docs site`

---

### Task 2: `?highlight` Vite plugin and `DemoExample`

**Files:**
- Create: `demo-app/vite/highlight.mjs`
- Modify: `vite.config.mjs` (register the plugin)
- Modify: `unpublished-development-types/index.d.ts` (module type for `*?highlight`)
- Modify: `package.json` (devDependencies `shiki`, `marked`)
- Create: `demo-app/components/demo-example.gts`
- Create: `demo-app/examples/usage/inline-simple.gts` (first real example, proves the pipeline)
- Modify: `demo-app/templates/usage/inline.gts` (renders that example)
- Modify: `demo-app/styles.css` (example/source panel rules)

**Interfaces:**
- Produces: importing `'<path>.gts?highlight'`, `'<path>.ts?highlight'`, `'<path>.css?highlight'` or `'<path>.md?highlight'` yields a module whose default export is `{ html: string; text: string; lang: string }`:
  - for code files: `html` is Shiki's output (`<pre class="shiki …"><code>…`), `text` is the (marker-stripped) source, `lang` is `glimmer-ts` / `typescript` / `css`;
  - for `.md`: `html` is the markdown rendered to HTML with fenced code blocks highlighted by Shiki, `text` is the raw markdown, `lang` is `markdown`.
- Produces: global type `HighlightedSource` = that object shape, declared at top level (global scope) in `unpublished-development-types/index.d.ts`, so `.gts` files use it without importing. (A wildcard module cannot be imported from by name, which is why the type is global rather than exported from `'*?highlight'`.)
- Produces: `DemoExample` (default export of `components/demo-example.gts`) with `Args: { title: string; description?: string; component?: ComponentLike; source: HighlightedSource }` where `ComponentLike` is imported from `@glint/template` (`import type { ComponentLike } from '@glint/template'`). Usage by pages: `<DemoExample @title="…" @description="…" @component={{InlineSimple}} @source={{inlineSimpleSrc}} />`. When `@component` is omitted the live panel is not rendered and the source panel spans the full width ("source-only" mode, used by the Install, Styling and Testing pages).
- Produces: marker convention — inside an example file, every line from a line that is exactly `// demo-hide` through the next line that is exactly `// demo-show` (both inclusive) is removed from `text`/`html` but still runs. Use only for demo-toast/demo-log wiring; never for addon usage.

- [ ] **Step 1: Dependencies.** `pnpm add -D shiki@^4 marked@^18`, then `pnpm audit --audit-level=high`. (Verified: shiki 4.x exports `createHighlighter` and `bundledLanguages` containing `glimmer-ts`, `glimmer-js`, `typescript`, `markdown`, `bash`, `css`; `marked` exports `marked.parse` and `marked.use`.)
- [ ] **Step 2: Plugin contract.** `demo-app/vite/highlight.mjs` default-exports a function returning a Vite plugin `{ name: 'demo-highlight', enforce: 'pre', resolveId, load }`:
  - `resolveId(source, importer)`: if `source` ends with `?highlight`, strip the query, resolve the remaining path relative to `importer` with `this.resolve(stripped, importer, { skipSelf: true })`, and return `'\0demo-highlight:' + resolved.id`. (The `\0` prefix is the Rollup/Vite convention that stops other plugins — including `@embroider/vite` and Babel — from treating the virtual module as a `.gts` file.) Otherwise return `null`.
  - `load(id)`: if `id` starts with `'\0demo-highlight:'`, take the file path after the prefix, call `this.addWatchFile(path)` (so edits hot-reload), read it with `fs.readFileSync(path, 'utf8')`, and produce a JS module string: `export const html = <json>; export const text = <json>; export const lang = <json>; export default { html, text, lang };` (use `JSON.stringify` for each value). Otherwise return `null`.
  - Language by extension: `.gts`→`glimmer-ts`, `.gjs`→`glimmer-js`, `.ts`→`typescript`, `.js`→`javascript`, `.css`→`css`, `.md`→markdown path (below). Anything else → throw an Error naming the file (fail the build; do not silently fall back).
  - Highlighter: one lazily created, module-level `createHighlighter({ themes: ['github-dark'], langs: ['glimmer-ts','glimmer-js','typescript','javascript','css','bash','handlebars','json','diff','html','markdown'] })` promise, awaited in `load`. Code → `highlighter.codeToHtml(text, { lang, theme: 'github-dark' })`.
  - Marker stripping (code files only): apply the `// demo-hide` / `// demo-show` rule from Interfaces before highlighting; `text` is the stripped source. If a `// demo-hide` has no matching `// demo-show`, throw (name the file).
  - Markdown path: `marked.use({ renderer: { code(token) {…} } })` (marked 18's renderer receives a token object with `text` and `lang`); the renderer returns Shiki HTML when `lang` is one of the loaded languages, otherwise an escaped `<pre><code>` block. Then `html = marked.parse(text)` (await it — `parse` may return a promise when async extensions are used; `await` is always safe). `lang = 'markdown'`.
- [ ] **Step 3: Register.** In `vite.config.mjs` import the plugin and add it **first** in `plugins`. It must be present in every mode (dev, test build, demo build) — it is inert unless something imports `?highlight`.
- [ ] **Step 4: Types.** In `unpublished-development-types/index.d.ts` add, at top level, `interface HighlightedSource { html: string; text: string; lang: string }` and then `declare module '*?highlight' { const source: HighlightedSource; export default source; }`.
- [ ] **Step 5: DemoExample markup contract.** `<section class="demo-example">` → `<header class="demo-example-header">` with `<h3 class="demo-example-title">{{@title}}</h3>` and, if provided, `<p class="demo-example-description">{{@description}}</p>`; then `<div class="demo-example-body">` (add class `is-source-only` when `@component` is absent) containing — only when `@component` is present — `<div class="demo-example-live"><@component /></div>`, and always `<div class="demo-example-source">` with a toolbar `<div class="demo-example-toolbar"><span class="demo-example-lang">{{@source.lang}}</span><button type="button" class="demo-copy">Copy</button></div>` and the highlighted HTML rendered via `htmlSafe(@source.html)` (write a tiny local helper function in the component file that wraps `htmlSafe`, and call it in the template — no triple curlies). Copy button: `navigator.clipboard.writeText(this.args.source.text)`, then label "Copied" for 1500 ms, then back to "Copy"; if `navigator.clipboard` is unavailable, label "Copy failed" for 1500 ms.
- [ ] **Step 6: First example.** `demo-app/examples/usage/inline-simple.gts`: a template-only component rendering one `<EmberRemodal>` with `@openButton="Open inline modal"`, `@openButtonClasses="demo-button"`, `@title`, `@text`, `@confirmButton`, `@cancelButton` (port the existing "Inline modal" section verbatim). Render it on `templates/usage/inline.gts` through `DemoExample` (title "Simple inline modal").
- [ ] **Step 7: Styles.** Append: `.demo-example` (card like `.demo-section`: surface, border, radius, margin-top), `.demo-example-body` (grid, two equal columns ≥ 900 px, one column below; `.is-source-only` is always one column), `.demo-example-live` (padding, centred content, min-height 6rem), `.demo-example-source` (dark `#24292e` background to match `github-dark`, radius, overflow hidden), `.demo-example-toolbar` (flex, space-between, small muted monospace text, bottom border), `.demo-copy` (small ghost button, light text), `.demo-example-source pre` (margin 0, padding 1rem, overflow-x auto, font-size 0.85rem, line-height 1.5) — Shiki sets colours inline, do not override them.
- [ ] **Step 8: Verify.** `pnpm lint` passes (including `lint:types` — the `?highlight` import must type-check). `pnpm start` shows `/usage/inline` with the live modal on the left and its highlighted source (template tag, args coloured) on the right; the Copy button copies the source; editing the example file hot-updates both panels. Also run `pnpm test` once now to prove the plugin does not disturb the test build (expected: all green, same count as before).
- [ ] **Step 9: Commit.** `feat(demo): build-time ?highlight plugin and DemoExample panel`

---

### Task 3: Demo-local services and helpers (toasts, log, options table, stamp)

**Files:**
- Create: `demo-app/services/demo-toasts.ts`
- Create: `demo-app/components/demo-toasts.gts`, `demo-app/components/demo-log.gts`, `demo-app/components/options-table.gts`
- Create: `demo-app/utils/stamp.ts`
- Modify: `demo-app/components/docs-shell.gts` (mount `<DemoToasts />` once, after `</main>`)
- Modify: `demo-app/styles.css` (toast, log, table rules)

**Interfaces:**
- Produces: `DemoToastsService` (default export, `demo-app/services/demo-toasts.ts`, registered automatically by the `./services/**/*` glob under the name `demo-toasts`): `export interface DemoToast { id: number; message: string; badge?: string }`; `@tracked toasts: readonly DemoToast[]`; `push(message: string, options?: { badge?: string }): void` (appends, auto-removes after 4000 ms, ids from an incrementing counter); `dismiss(id: number): void`; `clear(): void`. Inject in components with `@service('demo-toasts') declare toasts: DemoToastsService;`.
- Produces: `DemoToasts` component (no args): `<div class="demo-toasts" role="status" aria-live="polite">` → one `<div class="demo-toast">` per toast with `<span class="demo-toast-message">` and, when present, `<span class="demo-toast-badge">`, plus a `<button type="button" class="demo-toast-dismiss" aria-label="Dismiss">×</button>`.
- Produces: `DemoLog` component, `Args: { entries: readonly string[]; onClear: () => void }`: `<div class="demo-log-panel">` → toolbar with "Event log" label and a `<button type="button" class="demo-log-clear">Clear</button>` (disabled when empty) → `<ol class="demo-log">` of entries, or `<p class="demo-log-empty">Nothing yet — try the buttons above.</p>` when empty.
- Produces: `OptionsTable` component, `Args: { rows: readonly OptionRow[] }` with `export interface OptionRow { name: string; type: string; default: string; description: string }` exported from the component file: `<table class="demo-options">` with `<thead>` Name / Type / Default / Description and one row per entry; `name`, `type`, `default` in `<code>`.
- Produces: `stamp(message: string): string` (`demo-app/utils/stamp.ts`) → `"${new Date().toLocaleTimeString()}  ${message}"`. Examples build log entries with it.

- [ ] **Step 1: Service + DemoToasts.** Implement per contract; mount `<DemoToasts />` in `DocsShell` after `</main>` (inside the shell root, so it exists on every page). Toasts stack bottom-right, newest last.
- [ ] **Step 2: DemoLog, OptionsTable, stamp.** Implement per contract.
- [ ] **Step 3: Styles.** `.demo-toasts` (fixed, bottom 1rem, right 1rem, flex column, gap, max-width 22rem, `z-index` above the dialog's **open button** but note the `<dialog>` top layer always paints above everything — that is expected; toasts will be visible once the modal closes, and while a modal is open they appear behind the backdrop — acceptable and worth a one-line note on the Actions page), `.demo-toast` (ink background, light text, radius, padding, flex, gap, small), `.demo-toast-badge` (accent background pill, monospace), `.demo-toast-dismiss` (ghost), `.demo-log-panel` (reuse/extend the existing `.demo-log` rule — keep its dark green-on-black look), `.demo-log-empty` (muted), `.demo-options` (full width, collapse, cell padding, header muted uppercase, zebra rows, `overflow-x: auto` wrapper on narrow screens — wrap the table in `<div class="demo-options-wrap">`).
- [ ] **Step 4: Temporary verification hook.** To verify visually without any page using them yet, temporarily drop `<DemoLog @entries={{…}} @onClear={{…}} />` and a toast-pushing button into `templates/usage/inline.gts`, check in `pnpm start`, then **remove** the temporary markup before committing (Task 4 adds the real uses). Check: a toast appears bottom-right and disappears after ~4 s; the dismiss button removes it immediately; the log renders and clears.
- [ ] **Step 5: Verify.** `pnpm lint` passes; `git status` shows only the files listed for this task.
- [ ] **Step 6: Commit.** `feat(demo): toast service, event log, options table helpers`

---

### Task 4: Getting started pages (`/`, `/install`)

**Files:**
- Create: `demo-app/examples/getting-started/hero-modal.gts`
- Modify: `demo-app/templates/index.gts`, `demo-app/templates/install.gts`
- Modify: `demo-app/styles.css` (hero tweaks if needed)

**Interfaces:**
- Consumes: `DemoExample`, `?highlight`, route names (Task 1–2).
- Produces: nothing new for later tasks.

- [ ] **Step 1: Hero example.** `hero-modal.gts`: block-form `<EmberRemodal @title="Hello from 3.0">` whose `m.open` wraps a `demo-button` "Open the demo modal", and whose body has an `<img>` (`https://picsum.photos/seed/ember-remodal/640/400`, `width="640" height="400"`, `alt="A placeholder photograph"`, `style="max-width:100%;height:auto"` via a class) plus a sentence and `m.confirm`/`m.cancel` buttons (`remodal-confirm` / `remodal-cancel` classes, as the current block example does).
- [ ] **Step 2: Index page.** Keep the existing hero (`.demo-hero`, `<h1>ember-remodal</h1>`, the existing tagline text), then: the hero example through `DemoExample` (title "Try it"), then a `<section class="docs-section">` "Install" with a `<pre><code>pnpm add ember-remodal</code></pre>` line (a plain install line is the one permitted non-`?highlight` code block on the site) and a `<LinkTo @route="install">` "Full install guide →", then "What's new in 3.0" as a `<ul>` with these exact bullets: native `<dialog>` (top layer, focus containment, Escape), no jQuery, `m.isOpen` lazy content and `m.openAction`/`m.closeAction`/`m.confirmAction`/`m.cancelAction`, `@onBeforeOpen` veto, naming options (`@ariaLabel`, `@ariaLabelledBy`, `@closeButtonLabel`), `CloseReason` on `onClose`, stacked modals, `ember-remodal/test-support`, reduced-motion + forced-colors CSS, full TypeScript/Glint types — each with a `<LinkTo>` to the page that covers it. End with links to GitHub, npm, and `<LinkTo @route="migration">`.
- [ ] **Step 3: Install page.** Sections (each `<section class="docs-section">` with an `<h2>`):
  - **Requirements** — copy the facts from `MIGRATION.md` "Requirements" (ember-source floor, v2 addon, etc.). Do not invent requirements.
  - **Install** — `pnpm add ember-remodal` (plain `<pre><code>` line, same allowance as the index page).
  - **Stylesheet** — prose: the theme is imported from `ember-remodal/ember-remodal.css` (write the import line in inline `<code>`), it ships inside `@layer ember-remodal`, so unlayered app CSS overrides it without specificity fights. Link `styling`.
  - **Registration in a strict-resolver app** — render the demo's own `../app.gts` through `DemoExample` in source-only mode (`@source` = `import appSrc from '../app.gts?highlight'`, no `@component`), with prose pointing at the `./services/remodal` entry in its `modules` block.
  - **Classic (ember-cli) apps** — one paragraph: v2 addon, auto-discovered by ember-cli/Embroider, no registration needed.
- [ ] **Step 4: Verify.** `pnpm lint`; `pnpm start` shows `/` with the hero modal working (image visible inside), all bullets linking to existing routes; `/install` shows the `app.gts` source highlighted, full width.
- [ ] **Step 5: Commit.** `feat(demo): getting-started and install pages`

---

### Task 5: Usage pages (`/usage/inline`, `/usage/block`, `/usage/yielded`)

**Files:**
- Create under `demo-app/examples/usage/`: `inline-styled.gts`, `inline-actions.gts`, `block-basic.gts`, `block-lazy.gts`, `yielded-buttons.gts`, `yielded-actions.gts`, `er-button-direct.gts` (plus `inline-simple.gts` from Task 2)
- Modify: `demo-app/templates/usage/inline.gts`, `block.gts`, `yielded.gts`

**Interfaces:**
- Consumes: `DemoExample`, `DemoToastsService`, `DemoLog`, `stamp`.
- Produces: nothing new.

- [ ] **Step 1: Inline page.** Three examples: `inline-simple` (exists); `inline-styled` — same shape plus `@modifier="demo-midnight"` and custom `@confirmButtonClasses`/`@cancelButtonClasses` (add two small demo classes in `styles.css` if you want visible difference, e.g. `.demo-pill` rounded); `inline-actions` — a Glimmer component passing `@onOpen`, `@onConfirm`, `@onCancel`, `@onClose` functions that push toasts (`// demo-hide`/`// demo-show` around the `demo-toasts` import + injection only; the `@onX={{this.handler}}` bindings must remain visible), and `@onClose` includes the reason in the toast badge (`reason ?? 'none'`). Prose for the page: what inline form is, that the trigger (`@openButton`) renders with the modal, that the open button is portaled outside the dialog, and that actions are functions in 3.0 (link `migration`).
- [ ] **Step 2: Block page.** `block-basic` — port the current "Block usage" section (yielded `m.open`/`m.confirm`/`m.cancel` with own markup); `block-lazy` — port "Lazy content" (`{{#if m.isOpen}}`). Prose: block form, what `m` yields (list all eight keys of `EmberRemodalYield`), portal note, lazy pattern.
- [ ] **Step 3: Yielded page.** Three examples:
  - `yielded-buttons` — block modal using `<m.open>`, `<m.confirm>`, `<m.cancel>`, each wrapping a `<button type="button">` with a visible label; prose: these are `ErButton` instances with `onClick` (and, for `open`, `destination`) pre-bound.
  - `yielded-actions` — block modal opened with `<m.open>` as usual, but the **body** uses plain buttons wired with `{{on "click" m.closeAction}}`, `{{on "click" m.confirmAction}}`, `{{on "click" m.cancelAction}}` (no yielded button components in the body). Default behavior options only (do not pass `@closeOnEscape` / `@hasCustomKeyboardExit` here; that belongs to the behavior and accessibility pages).
  - `er-button-direct` — `import { ErButton } from '#src/index.ts'`; render `<ErButton @onClick={{this.handleClick}}>Say hello</ErButton>` where `handleClick` pushes a toast (hide only the toast wiring with the markers). `ErButtonSignature.Args` is `{ destination?: Element | null; onClick: (event?: Event) => unknown }`; it yields a default block and its element is a `<span>` — state this in prose.
  Page prose: list the eight yielded keys (`open`, `confirm`, `cancel`, `isOpen`, `openAction`, `closeAction`, `confirmAction`, `cancelAction`), when to use components vs bare actions, and the rule from `MIGRATION.md` "Yielded `m.open` / `m.confirm` / `m.cancel` blocks must contain a focusable control".
- [ ] **Step 4: Verify.** `pnpm lint`; `pnpm start`: every example opens/closes; on `/usage/inline` the actions example produces toasts for open/confirm/cancel/close with the badge `confirmation` / `cancellation` / `none` as appropriate (Escape → `none`).
- [ ] **Step 5: Commit.** `feat(demo): usage pages (inline, block, yielded)`

---

### Task 6: Service & state pages (`/service`, `/service/promises`, `/state`)

**Files:**
- Create under `demo-app/examples/service/`: `service-basic.gts`, `service-options.gts`, `service-missing.gts`, `promise-chain.gts`, `promise-stacked.gts`, `promise-await-then-mutate.gts`
- Create: `demo-app/examples/state/dog-list.gts`
- Modify: `demo-app/templates/service/index.gts`, `service/promises.gts`, `state.gts`

**Interfaces:**
- Consumes: `DemoExample`, `DemoLog`, `stamp`, `DemoToastsService`, `RemodalService` (`#src/services/remodal.ts`).
- Produces: nothing new.

**Rules for all service examples:** each example renders its own `<EmberRemodal @forService={{true}} @name="<unique-name>" />` **inside the example file** (names must be unique across the whole site, prefix them `demo-…`), injects `@service declare remodal: RemodalService;`, and uses `void this.remodal.open(name, …)` / `.close(name)` (mark floating promises with `void`, as the current demo does). Never call `open()` without a name.

- [ ] **Step 1: `/service`.** `service-basic` — one button, `remodal.open('demo-service-basic')`, log "open() resolved" via `DemoLog` when the promise resolves (`DemoLog` rendered in the example, entries tracked in the component). `service-options` — two buttons opening the same named modal with different `{ title, text, confirmButton }` option objects (shows options-at-open merging). `service-missing` — a button calling `remodal.open('demo-does-not-exist')` and logging the rejection message (`.catch((e) => log(stamp(e.message)))`) — demonstrates the 3.0 rule "open()/close() on an unrendered name always reject" (`MIGRATION.md`). Prose: where to render the `@forService` modal (application template), naming, options merge precedence (service overrides > `@options` > direct args — this is literally what `opt()` in the component does), both methods return `Promise<EmberRemodal>` resolving after the animation.
- [ ] **Step 2: `/service/promises`.** `promise-chain` — port the current "Open, then auto-close" (open → wait 1 s → `modal.close()` → log). `promise-stacked` — button opens modal A (`demo-stack-a`), whose block content contains a button that opens modal B (`demo-stack-b`) on top (both `@forService` rendered in the file); log each resolve; prose notes the top layer and reference-counted scroll lock. `promise-await-then-mutate` — `await remodal.open(name)`, then set a tracked `message` that the modal body displays (shows the modal re-rendering while open). Each example has its own `DemoLog`.
- [ ] **Step 3: `/state`.** `dog-list.gts`: tracked `selectedDog: Dog | null`; a `<ul class="demo-dogs">` of 4 dogs `{ name, breed, imageSeed }` (use `https://picsum.photos/seed/<seed>/320/200`, `width/height`, `alt` = name); clicking a dog's button sets `selectedDog` then `void this.remodal.open('demo-dog-detail')`; one `<EmberRemodal @forService={{true}} @name="demo-dog-detail" @ariaLabelledBy="demo-dog-heading">` whose body renders `<h2 id="demo-dog-heading">{{this.selectedDog.name}}</h2>`, the image, the breed, and a close button via `m.closeAction`. Guard the body with `{{#if this.selectedDog}}`. Prose: the thesis — keep state in the owner, one modal many contents; `@ariaLabelledBy` names the dialog from your own heading.
- [ ] **Step 4: Verify.** `pnpm lint`; `pnpm start`: all three pages behave as described; the missing-name example logs an error message mentioning the name; the dog modal shows the clicked dog.
- [ ] **Step 5: Commit.** `feat(demo): service, promises, and state-driven pages`

---

### Task 7: Options reference pages (`/options/content|behavior|classes|actions`)

**Files:**
- Create under `demo-app/examples/options/`: `content-options.gts`, `behavior-toggles.gts`, `class-hooks.gts`, `action-hooks.gts`, `close-reasons.gts`
- Modify: `demo-app/templates/options/content.gts`, `behavior.gts`, `classes.gts`, `actions.gts`

**Interfaces:**
- Consumes: `OptionsTable` + `OptionRow`, `DemoExample`, `DemoToastsService`, `DemoLog`, `stamp`.
- Produces: nothing new.

**Rules:** Each page starts with an `<OptionsTable @rows={{ROWS}} />` whose rows are a `const ROWS: OptionRow[]` defined at the top of the page file, **one row per option in the group, copied from `EmberRemodalOptions`** with the default taken from the component's `get` accessors (write `—` when there is no default, e.g. `title`). Types as written in the interface (`string`, `boolean`, `() => void`, `(reason?: CloseReason) => void`, `() => unknown`). Descriptions: one sentence each, derived from the comments in `src/components/ember-remodal.gts` where present.

Groups (exact membership):
- **content:** `title`, `text`, `confirmButton`, `cancelButton`, `openButton`, `openLink`, `linkButton`, `closeButtonLabel` (default `Close Modal`), `ariaLabel`, `ariaLabelledBy`, `name` (default `ember-remodal`), `forService` (default `false`), `dataTestId`, `options`.
- **behavior:** `closeOnEscape` (`true`), `hasCustomKeyboardExit` (`false`), `closeOnCancel` (`true`), `closeOnConfirm` (`true`), `closeOnOutsideClick` (`true`), `disableNativeClose` (default: same as `disableForeground`), `disableForeground` (`false`), `disableAnimation` (`false`).
- **classes:** `modifier`, `modalClasses`, `buttonClasses`, `outerButtonClasses`, `innerButtonClasses`, `openButtonClasses`, `openLinkClasses`, `cancelButtonClasses`, `confirmButtonClasses`, `legacyClassNames` (`false`).
- **actions:** `onBeforeOpen`, `onOpen`, `onConfirm`, `onCancel`, `onClose`.

- [ ] **Step 1: Content page.** `content-options` — one modal using `@title`, `@text`, `@confirmButton`, `@cancelButton`, `@openLink` (the link-style opener) **and** a second modal using `@openButton`, `@closeButtonLabel="Dismiss"` and `@ariaLabel` (no title) — two `<EmberRemodal>` in one example file is fine. Prose: `title` vs `ariaLabel` vs `ariaLabelledBy` precedence (accname order: `ariaLabelledBy` > `ariaLabel` > `title`), `@options` hash alternative.
- [ ] **Step 2: Behavior page.** `behavior-toggles` — a Glimmer component with four labelled `<input type="checkbox">` (closeOnEscape, closeOnOutsideClick, closeOnConfirm, closeOnCancel), each bound to a tracked boolean, feeding one `<EmberRemodal>`; when `closeOnEscape` is unchecked, also pass `@hasCustomKeyboardExit={{true}}` and include a body button wired to `m.closeAction` (otherwise Escape is never suppressed — say so in prose, citing `MIGRATION.md` "`@closeOnEscape={{false}}` is conditional now"). Plus a second, static example inside the same file: `@disableForeground={{true}}` + `@ariaLabel` (port the current "Frameless" section) and `@disableAnimation={{true}}` on a third modal. Prose per option, including that `disableNativeClose` defaults to `disableForeground`.
- [ ] **Step 3: Classes page.** `class-hooks` — one modal with `@modifier="demo-midnight"`, `@modalClasses`, `@openButtonClasses="demo-button"`, `@confirmButtonClasses`/`@cancelButtonClasses` and a second with `@legacyClassNames={{true}}`; prose explains each hook's target element (wrapper/card/buttons — read the template in `src/components/ember-remodal.gts` ~line 1200+ to state where each class lands) and links `styling`; `legacyClassNames` explained per `MIGRATION.md` "the bare single-word class hooks are retired".
- [ ] **Step 4: Actions page.** `action-hooks` — modal with all five hooks; each pushes a toast named after the hook; `onBeforeOpen` has a labelled checkbox "Veto opening" — when checked the handler returns `false` and the modal must not open (toast "onBeforeOpen returned false"). `close-reasons` — a modal with confirm + cancel buttons and default close paths; `onClose` pushes a toast whose badge is `reason ?? 'none'`; prose lists every close path and what reason it yields: confirm → `confirmation`; cancel → `cancellation`; Escape / backdrop / ✕ / `service.close()` → `undefined`. Add the one-line note that toasts render behind an open modal's backdrop (top layer) and are visible once it closes.
- [ ] **Step 5: Verify.** `pnpm lint`; `pnpm start`: every table row present (count against the group lists above), toggles change behavior live, veto checkbox blocks opening, reasons badge matches the path used.
- [ ] **Step 6: Commit.** `feat(demo): options reference pages with live examples`

---

### Task 8: Styling, accessibility, testing pages

**Files:**
- Create: `demo-app/examples/styling/theme-midnight.gts`, `demo-app/examples/styling/reduced-motion.gts`, `demo-app/examples/styling/backdrop-and-parts.gts`
- Create: `demo-app/examples/accessibility/named-dialog.gts`, `demo-app/examples/accessibility/escape-rules.gts`
- Create: `demo-app/examples/testing/example-test.ts` (a **real-looking test file that is never run**, see below)
- Modify: `demo-app/templates/styling.gts`, `accessibility.gts`, `testing.gts`, `demo-app/styles.css`

**Interfaces:**
- Consumes: `DemoExample` (with and without `@component`), `?highlight` (`.gts`, `.ts`, `.css`).
- Produces: nothing new.

- [ ] **Step 1: Styling page.** First, restructure the demo CSS so the shown CSS is the applied CSS: create `demo-app/styles/demo-midnight.css` (move the existing `.remodal.demo-midnight { … }` and `dialog.remodal-wrapper.demo-midnight::backdrop { … }` rules there, with their comments) and `demo-app/styles/demo-outline.css` (new: `.remodal.demo-outline` — light card with a 3px accent border and square corners; `dialog.remodal-wrapper.demo-outline::backdrop` — a semi-transparent accent tint; `.remodal.demo-outline .remodal-close` — accent colour; `.remodal.demo-outline .remodal-confirm` / `.remodal-cancel` — outlined buttons via the addon's custom properties where one exists, direct declarations otherwise). Add `@import './styles/demo-midnight.css'; @import './styles/demo-outline.css';` at the very top of `demo-app/styles.css` (`@import` must precede all other rules). Then the page sections:
  - **How the theme ships** — `@layer ember-remodal`; unlayered app CSS wins without specificity fights (cite `MIGRATION.md` "the stylesheet ships inside `@layer ember-remodal`").
  - **Custom properties** — `DemoExample` source-only with `@source` = `'#src/styles/ember-remodal.css?highlight'`, prose: "the palette block near the top lists every token; override them on `.remodal` or on a `@modifier` class".
  - **A custom theme** — `theme-midnight` example (port the current "Theming with @modifier" section, `@modifier="demo-midnight"`) followed by `DemoExample` source-only with `@source` = `'../styles/demo-midnight.css?highlight'` (path relative to `templates/`).
  - **Targeting parts** — `backdrop-and-parts` example (`@modifier="demo-outline"`, title, text, confirm + cancel) followed by source-only `'../styles/demo-outline.css?highlight'`; prose names each part: `dialog.remodal-wrapper` (+ `::backdrop`), `.remodal` (card), `.remodal-close`, `.remodal-confirm`, `.remodal-cancel`, `.remodal-title`, `.remodal-text`.
  - **Reduced motion** — `reduced-motion` example: a labelled `<input type="checkbox">` "Simulate prefers-reduced-motion" toggling class `demo-reduced-motion` on a wrapper `<div>` around one `<EmberRemodal>`; add unlayered demo CSS in `styles.css` that, under `.demo-reduced-motion`, sets `animation: none` on `.remodal.remodal-is-opening`, `.remodal.remodal-is-closing`, `dialog.remodal-wrapper.remodal-is-opening::backdrop`, `dialog.remodal-wrapper.remodal-is-closing::backdrop`, and `transition: none` on `.remodal-close, .remodal-confirm, .remodal-cancel` — mirroring `src/styles/ember-remodal.css` lines 473–486. Prose: the addon does this automatically under the media query; `@disableAnimation` is the per-modal switch.
  - **Forced colors** — prose only: what the addon does under `forced-colors: active` (card border, button borders, dashed cancel border, `Highlight` focus outline — from lines 436–470) and how to preview it (Chrome DevTools → Rendering → "Emulate CSS media feature forced-colors").
- [ ] **Step 2: Accessibility page.** Prose sections drawn from `MIGRATION.md` "Accessibility behavior changes" and the `ariaLabel`/`ariaLabelledBy` comments: native `<dialog>` + `showModal()` (top layer, focus containment, Escape), **naming** — `named-dialog` example showing three modals: titled (`@title`), `@ariaLabel`, `@ariaLabelledBy` pointing at a heading in the block; **Escape rules** — `escape-rules` example: `@closeOnEscape={{false}}` with `@hasCustomKeyboardExit={{true}}` and a body close button; prose states the conditional rule and that Escape can force-close anyway when the addon detects no keyboard exit (cite the MIGRATION sections "`@closeOnEscape={{false}}` is conditional now" and "Escape can force-close regardless…"); **focusable control rule** for yielded blocks; **naming attributes** on the rendered markup (section "The rendered markup gained naming attributes"); **motion and contrast** link to `styling`.
- [ ] **Step 3: Testing page.** Create `demo-app/examples/testing/example-test.ts` — a complete, realistic QUnit rendering test module using `setupRemodal(hooks, { disableAnimation: true })`, `render`, `click`, `remodalDialog()`; it imports from `'ember-remodal'` and `'ember-remodal/test-support'` **as a consumer would** (package names, not `#src`). It is **not** under `tests/` and is never executed; it is shown source-only on the page. It still must pass `lint:types`: the tsconfig `paths` map `ember-remodal` and `ember-remodal/test-support` to `src/`, so the imports resolve; `@ember/test-helpers`/`ember-qunit`/`qunit` types are present as devDependencies. Page prose: each helper from `src/test-support/index.ts` (`setupRemodal`, `resetRemodalScrollLock`, `setRemodalAnimationDisabled`, `remodalDialog`, `remodalDialogs`) with one sentence from its JSDoc; "animations are awaited automatically" and "`disableAnimationWhileTesting` — classic resolver only" from `MIGRATION.md`; selector updates (`[data-test-id="modalWrapper"]` is the dialog).
- [ ] **Step 4: Verify.** `pnpm lint` (the `.ts` example must type-check; the `?highlight` of `.css` must work); `pnpm start`: the midnight and outline themes apply and their CSS panels match; the reduced-motion checkbox makes open/close instantaneous; the testing page shows the test file highlighted.
- [ ] **Step 5: Commit.** `feat(demo): styling, accessibility, and testing pages`

---

### Task 9: Migration page (markdown path)

**Files:**
- Modify: `demo-app/templates/migration.gts`, `demo-app/styles.css`

**Interfaces:**
- Consumes: `'../../MIGRATION.md?highlight'` (markdown path of the plugin, Task 2).
- Produces: nothing new.

- [ ] **Step 1: Render.** Import `MIGRATION.md` via `?highlight` (relative path from `demo-app/templates/`) and render `html` inside `<article class="docs-markdown">` using the same `htmlSafe` pattern. Keep the page `<h1>` ("Migrating from 2.x") and a lede linking to the file on GitHub (`https://github.com/sethbrasile/ember-remodal/blob/master/MIGRATION.md`); the markdown's own `# Migrating from ember-remodal 2.x to 3.0` heading will render as an `<h1>` too — hide the first `h1` inside `.docs-markdown` with CSS (`.docs-markdown > h1:first-child { display: none }`) rather than editing the markdown.
- [ ] **Step 2: Styles.** `.docs-markdown` typography: headings spacing, `p` max-width, `code` (inline) reuse the existing `code` rule, `pre.shiki` (padding, radius, overflow-x auto, font-size 0.85rem), tables (reuse `.demo-options` look via a shared rule for `.docs-markdown table`), blockquote muted border.
- [ ] **Step 3: Verify.** `pnpm lint`; `pnpm start`: `/migration` shows the whole guide, fenced blocks (`hbs`, `js`, `ts`, `css`, `diff`) are highlighted — note `hbs` fences: map `hbs` to Shiki's `handlebars` in the markdown renderer (add that alias in the plugin: `hbs` → `handlebars`, `gjs`→`glimmer-js`, `gts`→`glimmer-ts`, `sh`/`shell`→`bash`). Check that heading anchors are not required (no TOC).
- [ ] **Step 4: Commit.** `feat(demo): migration page rendered from MIGRATION.md`

---

### Task 10: Example smoke test

**Files:**
- Create: `tests/rendering/demo-examples-test.gts`

**Interfaces:**
- Consumes: every `demo-app/examples/**/*.gts` default export (components with no required args); `DemoToastsService` (`demo-app/services/demo-toasts.ts`).
- Produces: the convention that **an example that intentionally renders no `<dialog>` exports `export const noDialog = true`** (none of the planned examples need it; the convention exists so the test's assertion is explicit).

- [ ] **Step 1: Write the test.** Module `'Rendering | demo examples'` with `setupRenderingTest(hooks)` and `setupRemodal(hooks, { disableAnimation: true })` (import from `#src/test-support/index.ts`, like the other tests). In `hooks.beforeEach`, register the demo toast service: `this.owner.register('service:demo-toasts', DemoToastsService)`. Collect examples with `import.meta.glob('../../demo-app/examples/**/*.gts', { eager: true })` typed as `Record<string, { default: ComponentLike; noDialog?: boolean }>`. For each `[path, mod]` entry, declare one `test(path, …)` that: assigns `const Example = mod.default;`, renders `<template><Example /></template>`, and asserts `assert.dom('[data-test-id="modalWrapper"]').exists()` unless `mod.noDialog === true`, in which case it asserts the rendered container is not empty (`assert.dom(this.element).exists()` plus a non-empty `innerHTML` check). Examples that use `setTimeout` (the promise-chain one) are only rendered, not driven, so no waiter issues arise.
- [ ] **Step 2: Run.** `pnpm test` — expected: the new module lists one passing test per example file (count them: it must equal `find demo-app/examples -name '*.gts' | wc -l`), suite green. If an example fails here, fix the example (e.g. a missing `type="button"`, a runtime error), not the test.
- [ ] **Step 3: Commit.** `test(demo): render every demo example in the rendering suite`

---

### Task 11: Demo build mode, Pages deploy, CI job, README link

**Files:**
- Modify: `vite.config.mjs` (`demo` mode), `package.json` (`build:demo` script), `.gitignore` (`dist-demo/`)
- Create: `scripts/emit-demo-404.mjs`, `.github/workflows/deploy-demo.yml`
- Modify: `.github/workflows/ci.yml` (new `demo` job), `README.md` (top link + Demo section)

**Interfaces:**
- Consumes: everything above.
- Produces: `pnpm build:demo` → `dist-demo/` containing `index.html`, `404.html`, hashed assets, all URLs prefixed `/ember-remodal/`.

- [ ] **Step 1: Vite demo mode.** Change `vite.config.mjs` to `defineConfig(({ mode }) => ({ … }))`. When `mode === 'demo'`: `base: '/ember-remodal/'` and `build.rollupOptions.input: 'index.html'`; otherwise keep the current `tests/index.html` input and default base. Everything else (plugins, define) unchanged.
- [ ] **Step 2: Scripts.** `package.json`: `"build:demo": "vite build --mode=demo --out-dir dist-demo && node ./scripts/emit-demo-404.mjs"`. `scripts/emit-demo-404.mjs`: copies `dist-demo/index.html` to `dist-demo/404.html` (fail loudly if `index.html` is missing); add a header comment explaining it is the GitHub Pages SPA fallback for `history` routing. Add `dist-demo/` to `.gitignore` under "compiled output".
- [ ] **Step 3: Local verification of the build.** `pnpm build:demo` succeeds; `grep -c '/ember-remodal/assets/' dist-demo/index.html` ≥ 1; `test -f dist-demo/404.html`; serve it to check routing with `pnpm vite preview --mode=demo --outDir dist-demo` (do not use `npx serve`; it ignores `base`) and open `http://localhost:4173/ember-remodal/options/actions` directly: the page loads at that deep URL and the sidebar works. Also confirm `pnpm start` still serves the demo at `/` and `pnpm test` still builds tests (the default mode is unchanged).
- [ ] **Step 4: Deploy workflow.** `.github/workflows/deploy-demo.yml`: `name: Deploy demo`; `on: push: branches: [master]` and `workflow_dispatch: {}`; top-level `permissions: {}`; `concurrency: { group: pages, cancel-in-progress: false }`; one job `deploy` with `permissions: { pages: write, id-token: write, contents: read }`, `environment: { name: github-pages, url: ${{ steps.deployment.outputs.page_url }} }`, `runs-on: ubuntu-latest`, `timeout-minutes: 10`; steps: `actions/checkout` (with `persist-credentials: false`), `pnpm/action-setup`, `actions/setup-node` (node 22, cache pnpm), `pnpm install --frozen-lockfile`, `pnpm build:demo`, `actions/configure-pages`, `actions/upload-pages-artifact` with `path: dist-demo`, `actions/deploy-pages` with `id: deployment`. **Every `uses:` must be pinned to a full commit SHA with a `# vX.Y.Z` comment**, exactly like `.github/workflows/push-dist.yml`: copy the three SHAs already in that file for checkout / pnpm/action-setup / setup-node; for the three Pages actions resolve the SHA of their latest `v*` major tag with `gh api repos/actions/<name>/commits/<tag> --jq .sha` (e.g. `gh api repos/actions/deploy-pages/commits/v4 --jq .sha`) and record the tag in the comment. Add a header comment mirroring `push-dist.yml`'s explanation of why actions are pinned.
- [ ] **Step 5: CI job.** In `.github/workflows/ci.yml` add a job `demo` (`name: "Demo build"`) shaped like the `lint` job (same checkout/pnpm/node steps, `pnpm install --frozen-lockfile`) whose last step is `pnpm build:demo`. Use the same unpinned `@v4` style as the other jobs in that file (it is read-only; consistency with the file wins).
- [ ] **Step 6: README.** Directly under the npm badge line add: `**[Interactive demo & documentation →](https://sethbrasile.github.io/ember-remodal)**` on its own line. Add a short `## Demo` section near the end (before License or Contributing, wherever fits the existing heading order): one paragraph — the demo is `demo-app/`, `pnpm start` runs it, `pnpm build:demo` builds it, it deploys from `master` via `.github/workflows/deploy-demo.yml`.
- [ ] **Step 7: Lint the workflow.** If `actionlint` is installed (`which actionlint`), run it on both workflow files and fix findings. In all cases `pnpm lint` must pass (prettier covers the YAML via `lint:format`).
- [ ] **Step 8: Commit.** `ci(demo): demo build mode, GitHub Pages deploy workflow, CI job, README link`

---

### Task 12: Final verification and hand-off

**Files:** none new (fixes only if something fails).

- [ ] **Step 1: Full gates.** Run, in order, and record the outcomes: `pnpm lint` · `pnpm test` · `pnpm build:demo` · `pnpm verify:published-package` · `pnpm lint:publish`. All must pass. Then `git status` must be clean except for intended changes, and `git diff --exit-code package.json` after `lint:publish` must show no change (the `app-js` map is untouched by this plan).
- [ ] **Step 2: Tarball check.** `pnpm pack --pack-destination /tmp` then `tar -tzf /tmp/ember-remodal-*.tgz | grep -E 'demo-app|dist-demo|docs/|vite/highlight' ` must print **nothing**. Delete the tarball.
- [ ] **Step 3: Route walk.** With `pnpm start`, visit all 16 URLs and confirm: `<h1>` present, at least one example (or source panel) on every page except `/migration` (markdown) and confirm the browser console shows no errors or Ember warnings (a `ember-remodal.modal-without-accessible-name` warning means an example is missing `@ariaLabel`/`@title` — fix the example).
- [ ] **Step 4: Acceptance checklist** (from the spec; tick each in the commit message body or the bead):
  - 16 routes + persistent sidebar; every 2.x section has a 3.0 counterpart plus the 3.0-only pages.
  - Every example is rendered from the same file that is shown, via `?highlight`.
  - Action hooks and `CloseReason` visualised via toasts.
  - State-driven (dog list) and promise playground present.
  - `build:demo` + `deploy-demo.yml` + README link + Migration surfaced.
  - `pnpm start`, `pnpm test`, `pnpm lint`, `pnpm build:demo` green; tarball unchanged.
- [ ] **Step 5: Commit (if anything changed).** `chore(demo): final verification fixes`
- [ ] **Step 6: Report.** In the final message list: what passed (with the counts from `pnpm test`), the one manual step remaining for Seth — **GitHub repo Settings → Pages → Source = "GitHub Actions"** before the first deploy succeeds — and that deleting the legacy `gh-pages` branch is a remote delete to be decided separately. Do not push; do not delete branches.
