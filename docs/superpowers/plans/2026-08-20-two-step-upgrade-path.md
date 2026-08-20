# Two-Step 2.x → 3.0 Upgrade Path Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship ember-remodal 2.19.0 (runtime `console.warn` deprecations for every 3.0-breaking usage), an agent readiness-audit prompt for the statically-detectable breaks, and guides that teach the two-step upgrade path — gated on a feasibility check of the 2018-era 2.x toolchain.

**Architecture:** Two worlds. The 2.19 work happens on a new `2.x` branch cut from `origin/master` (classic v1 addon, ember-cli 2.18, npm, old Node pinned via `PATH`), touching only `addon/`. The prompt and guides happen on the modernize branch (`claude/ember-remodal-modernize-he3lc5`, pnpm/Vite), touching only MIGRATION.md, README.md and `demo-app/`. A shared `warnOnce()` util gives every 2.19 warning a stable id, a once-per-id guard, a `silenceDeprecations` opt-out, and a MIGRATION.md deep link.

**Tech Stack:** 2.x branch: Ember 2.18 classic addon, `Component.extend`, qunit/ember-qunit 3 (`setupRenderingTest`), Node 6/8 from `~/.nvm/versions/node/`. Modernize branch: existing `.gts` demo + Shiki `?highlight` pipeline; no new dependencies anywhere.

**Spec:** `docs/superpowers/specs/2026-08-20-two-step-upgrade-path-design.md` — read it first. Its deprecation catalog table (ids, triggers, anchors) is the contract both branches implement against.

**Executor guidance:** Code blocks for the 2.x branch are the intended implementation — copy them, adjusting only to match what you find in the file (line numbers cite `origin/master`). On the modernize branch, follow the contracts and copy conventions from neighbouring files (`demo-app/components/demo-example.gts`, `demo-app/templates/migration.gts`, existing tests under `tests/`). Never modify `src/` on the modernize branch or anything outside `addon/`+`tests/` semantics on the 2.x branch.

## Global Constraints

- **Conditional structure:** Task 1 runs first and alone. Its outcome (GO / DEGRADED GO / NO-GO, defined in the spec) decides the rest: GO → Tasks 2–7; DEGRADED GO → Tasks 2–7 with every "run the test suite" step replaced by the smoke-app verification defined in Task 1; NO-GO → **stop, confirm with Seth**, then Task F instead of Tasks 2–4 and 7.
- **2.x branch is behavior-frozen:** every warning path must delegate to the exact pre-existing behavior. No refactors beyond what a warning needs. 2.18 → 2.19 must be a zero-risk upgrade.
- **2.x syntax budget:** only syntax already present in the codebase — ES modules, `let`/`const`, arrows, template literals, default params. No optional chaining, no `class`, no object spread, no async/await in addon code.
- **Old-world shell prefix** (every command in the 2.x worktree): `export PATH="$HOME/.nvm/versions/node/v8.17.0/bin:$PATH"` (or the Node that Task 1 pinned — read the feasibility report). Use `npm`, never `pnpm`. Do not commit new lockfiles.
- **Warning format (exact):** `[ember-remodal] DEPRECATION (<id>): <message> See https://github.com/sethbrasile/ember-remodal/blob/master/MIGRATION.md#<anchor>` — ids and anchors verbatim from the spec's catalog table.
- **Outward-facing actions are surfaced first:** `npm publish`, pushing the `2.x` branch and the `v2.19.0` tag are proposed to Seth before running (Task 7). Local commits and ordinary pushes of the modernize branch are routine.
- **Release ordering:** 2.19 does not publish until `https://github.com/sethbrasile/ember-remodal/blob/master/MIGRATION.md` returns 200 (modernize branch merged to master).
- **Worktree path:** `/Users/seth/Documents/GitHub/ember-remodal-2x` (created in Task 1, reused by Tasks 2–5 and the dogfood step).

---

### Task 1: Feasibility gate (er-f0t.1)

**Files:**
- Create: `docs/superpowers/plans/2026-08-20-feasibility-report.md` (on the modernize branch)
- No source changes anywhere.

**Interfaces:**
- Produces: the GO / DEGRADED GO / NO-GO verdict, the pinned Node version, and (GO) the working test command — all recorded in the report. Every later task consumes this.

- [ ] **Step 1: Create the 2.x worktree**

```bash
git -C /Users/seth/Documents/GitHub/ember-remodal worktree add --detach /Users/seth/Documents/GitHub/ember-remodal-2x origin/master
```

- [ ] **Step 2: Pin old Node and record versions**

```bash
cd /Users/seth/Documents/GitHub/ember-remodal-2x
export PATH="$HOME/.nvm/versions/node/v8.17.0/bin:$PATH"
node --version && npm --version   # expect v8.17.0 / npm 6.x
```

- [ ] **Step 3: Install** — `npm install`. On failure (node-gyp, dead transitive dep, peer conflict): retry once with `npm install --no-optional`; then retry the whole step under `v6.17.1`, then `v10.24.1`. Record every failure verbatim in the report draft.

- [ ] **Step 4: Build** — `node_modules/.bin/ember build`. Expected: `Built project successfully` into `dist/`.

- [ ] **Step 5: Test runner** — `node_modules/.bin/ember test`. If Chrome fails to launch (old testem vs modern Chrome flags): `node_modules/.bin/ember serve` and load `http://localhost:4200/tests` in a browser instead; a completing qunit run counts. Record which form worked — Tasks 2–4 reuse it.

- [ ] **Step 6: Pack** — `npm pack`; then `tar -tzf ember-remodal-2.18.0.tgz | head -30` — must contain `package/index.js`, `package/addon/`, `package/app/`.

- [ ] **Step 7 (only if 3–5 failed): minimal smoke app** — under the same pinned Node, in the scratchpad: `npx ember-cli@2.18.2 new remodal-smoke --skip-git`, `npm install ../path/to/ember-remodal-2.18.0.tgz`, add `{{ember-remodal openButton='open'}}` to `app/templates/application.hbs`, `ember serve`, confirm the button renders and opens the modal. Success here = DEGRADED GO; this smoke app (kept in the scratchpad, path recorded in the report) becomes the verification vehicle for Tasks 2–4: it gets one route per deprecation exercising the deprecated usage, verified by reading the browser console.

- [ ] **Step 8: Write the report** — `docs/superpowers/plans/2026-08-20-feasibility-report.md`: verdict, pinned Node, working commands, every failure verbatim, smoke-app path if any. Commit on the modernize branch: `git add docs/superpowers/plans/2026-08-20-feasibility-report.md && git commit -m "docs: 2.x feasibility report (er-f0t.1)"`.

- [ ] **Step 9: Close the bead** — `bd close er-f0t.1` with the verdict in the reason. On GO/DEGRADED GO, continue to Task 2. On NO-GO, stop and confirm the docs-only fallback with Seth before Task F.

---

### Task 2: `2.x` branch + `warnOnce` util

**Files:**
- Create: `addon/utils/deprecations.js` (2.x worktree)
- Test: `tests/unit/utils/deprecations-test.js` (2.x worktree)

**Interfaces:**
- Produces: `warnOnce(config, id, message, anchor)` — `config` is the resolved `config:environment` object or null; `id`/`anchor` verbatim from the spec catalog. `_resetWarnings()` clears the seen-map (tests only). `INTERNAL_CALL` — sentinel string consumed by Tasks 3–4. `MIGRATION_GUIDE` — the base URL string.

- [ ] **Step 1: Cut the branch** — in the worktree: `git switch -c 2.x` (from the detached `origin/master` HEAD).

- [ ] **Step 2: Write the failing test** — `tests/unit/utils/deprecations-test.js`:

```js
import { module, test } from 'qunit';
import { warnOnce, _resetWarnings } from 'ember-remodal/utils/deprecations';

module('Unit | Utility | deprecations', function(hooks) {
  let warnings, originalWarn;

  hooks.beforeEach(function() {
    _resetWarnings();
    warnings = [];
    originalWarn = console.warn;
    console.warn = message => warnings.push(message);
  });

  hooks.afterEach(function() {
    console.warn = originalWarn;
  });

  test('formats id, message and anchor link', function(assert) {
    warnOnce(null, 'ember-remodal.test-id', 'Thing is going away.', 'some-anchor');

    assert.deepEqual(warnings, [
      '[ember-remodal] DEPRECATION (ember-remodal.test-id): Thing is going away. See https://github.com/sethbrasile/ember-remodal/blob/master/MIGRATION.md#some-anchor'
    ]);
  });

  test('warns once per id, but separately per distinct id', function(assert) {
    warnOnce(null, 'ember-remodal.a', 'A.', 'a');
    warnOnce(null, 'ember-remodal.a', 'A.', 'a');
    warnOnce(null, 'ember-remodal.b', 'B.', 'b');

    assert.equal(warnings.length, 2);
  });

  test('silenceDeprecations suppresses everything', function(assert) {
    let config = { 'ember-remodal': { silenceDeprecations: true } };
    warnOnce(config, 'ember-remodal.test-id', 'Thing.', 'a');

    assert.equal(warnings.length, 0);
  });

  test('missing anchor links the guide root', function(assert) {
    warnOnce(null, 'ember-remodal.test-id', 'Thing.', null);

    assert.ok(warnings[0].indexOf('MIGRATION.md') === warnings[0].length - 'MIGRATION.md'.length);
  });
});
```

- [ ] **Step 3: Run it, expect failure** — the Task-1 test command; expect module-resolution failure for `ember-remodal/utils/deprecations`. (DEGRADED GO: skip test steps in Tasks 2–4; verify each behavior in the smoke app's console instead.)

- [ ] **Step 4: Implement** — `addon/utils/deprecations.js`:

```js
export const MIGRATION_GUIDE =
  'https://github.com/sethbrasile/ember-remodal/blob/master/MIGRATION.md';

export const INTERNAL_CALL = '__ember-remodal-internal-call__';

let warned = Object.create(null);

// Deliberately console.warn, not Ember.deprecate: these must survive a
// production build, and must behave identically on every consumer Ember
// version this addon supports.
export function warnOnce(config, id, message, anchor) {
  let remodalConfig = config && config['ember-remodal'];

  if (remodalConfig && remodalConfig.silenceDeprecations) {
    return;
  }

  if (warned[id]) {
    return;
  }

  warned[id] = true;

  let link = anchor ? `${MIGRATION_GUIDE}#${anchor}` : MIGRATION_GUIDE;

  console.warn(`[ember-remodal] DEPRECATION (${id}): ${message} See ${link}`);
}

export function _resetWarnings() {
  warned = Object.create(null);
}
```

- [ ] **Step 5: Run tests, expect pass.** If eslint objects to `console.warn`, allow it for this one file with an inline `/* eslint-disable no-console */` at top — the whole point of the file is console output.

- [ ] **Step 6: Commit** — `git add addon/utils/deprecations.js tests/unit/utils/deprecations-test.js && git commit -m "feat: warnOnce deprecation util with once-per-id guard and silenceDeprecations opt-out"`.

---

### Task 3: Component deprecations

**Files:**
- Modify: `addon/components/ember-remodal.js` (2.x worktree)
- Test: `tests/integration/components/ember-remodal-deprecations-test.js` (create)

**Interfaces:**
- Consumes: `warnOnce`, `INTERNAL_CALL` from Task 2.
- Produces: `open(internal)` / `close(internal)` accepting the sentinel (Task 4's service passes it); private `_remodalInstance` replacing the stored instance; `modal` as a deprecated computed.

- [ ] **Step 1: Write failing tests** — `tests/integration/components/ember-remodal-deprecations-test.js`, same console-stub `beforeEach`/`afterEach` as Task 2 (plus `_resetWarnings()`), `setupRenderingTest`, `hbs` imports matching `tests/integration/components/ember-remodal-test.js`. Helper at module scope:

```js
function warningIds(warnings) {
  return warnings.map(w => w.match(/\((ember-remodal\.[a-z-]+)\)/)[1]);
}
```

Test cases (one `test()` each):
1. `await render(hbs`{{ember-remodal}}`)` → `warningIds` contains `ember-remodal.v3-available` exactly once; render a second instance → still once.
2. `{{ember-remodal onOpen="someActionName"}}` → contains `ember-remodal.string-actions`.
3. `{{ember-remodal hashTracking=true}}` → contains `ember-remodal.hash-tracking`.
4. `{{ember-remodal class="custom"}}` → contains `ember-remodal.class-attribute`.
5. `{{ember-remodal forService=true}}`; then `this.owner.lookup('service:remodal').get('ember-remodal.modal')` → contains `ember-remodal.modal-property`.
6. `{{ember-remodal forService=true}}`; `let modal = this.owner.lookup('service:remodal').get('ember-remodal'); modal.open()` → contains `ember-remodal.component-via-service`. *(Will pass fully only after Task 4 wires the sentinel; write it now, expect it red until then if the service half is needed.)*
7. Clean baseline: render `{{ember-remodal openButton='open'}}`, click open, wait for `remodal-is-opened` (copy the wait pattern from the existing test file), click the native close → `warningIds` contains **only** `ember-remodal.v3-available`.
8. `ENV` silence: `{{ember-remodal}}` with `this.owner.resolveRegistration('config:environment')['ember-remodal'] = { silenceDeprecations: true }` set in the test (restore in `afterEach`) → zero warnings.

- [ ] **Step 2: Run, expect failures** (no warnings emitted yet).

- [ ] **Step 3: Implement** in `addon/components/ember-remodal.js`:

a. Import: `import { warnOnce, INTERNAL_CALL } from '../utils/deprecations';`

b. Rename the stored instance — `modal: null` (line ~25) becomes `_remodalInstance: null`, and every internal reference renames with it: the `this.get('modal')` checks in `close()` (line ~85) and `actions.open` (line ~218), the `this.set('modal', modal)` in `_createInstanceAndOpen` (line ~189), and the reads in `_destroyDomElements` (line ~166), `_openModal` (line ~205), `_closeModal` (line ~209). Grep the file for `'modal'` afterwards — the only remaining hits must be the new computed and `modalId`.

c. Add the deprecated `modal` computed (with the existing `computed` import):

```js
modal: computed('_remodalInstance', {
  get() {
    warnOnce(
      this._getConfig(),
      'ember-remodal.modal-property',
      'The "modal" property (the wrapped jQuery remodal instance, including getState()) is removed in 3.0. Use the yielded isOpen / the component\'s state, or data-test-id selectors, instead.',
      'the-modal-property-and-getstate-is-removed'
    );
    return this.get('_remodalInstance');
  }
}),
```

d. Sentinel on the public pair — `open()` and `close()` gain an `internal` param and both start with `this._warnIfExternalCall(internal);`; add:

```js
_warnIfExternalCall(internal) {
  if (internal !== INTERNAL_CALL) {
    warnOnce(
      this._getConfig(),
      'ember-remodal.component-via-service',
      'Reaching the modal component through the service (e.g. this.remodal.get(name).open()) is removed in 3.0. Call service.open(name, options) / service.close(name) instead.',
      'reaching-the-modal-component-through-the-service-is-removed'
    );
  }
},
```

e. Fill `_checkForDeprecations()`:

```js
_checkForDeprecations() {
  let config = this._getConfig();

  warnOnce(
    config,
    'ember-remodal.v3-available',
    'ember-remodal 3.0 is available. Upgrade in two steps: 1) fix every deprecation this release logs, 2) run the readiness audit prompt from the migration guide, then upgrade.',
    'the-two-step-upgrade-path'
  );

  ['onOpen', 'onClose', 'onConfirm', 'onCancel'].forEach(actionName => {
    if (typeof this.get(actionName) === 'string') {
      warnOnce(
        config,
        'ember-remodal.string-actions',
        `"${actionName}" was passed as a string action name (first seen on "${this.get('name')}"). 3.0 only accepts functions — pass a closure action or a method instead.`,
        'string-actions--function-arguments'
      );
    }
  });

  if (this.get('hashTracking')) {
    warnOnce(
      config,
      'ember-remodal.hash-tracking',
      'hashTracking is removed in 3.0 — the router owns the URL in an Ember app. Drive service.open()/close() from a route or query param if you need URL-driven modals.',
      'hashtracking-removed'
    );
  }

  if (this.get('class')) {
    warnOnce(
      config,
      'ember-remodal.class-attribute',
      'class= in curly invocation stops merging onto the element in 3.0 (Glimmer treats it as an ignored argument). Use angle-bracket invocation (<EmberRemodal class="...">), or @modalClasses for the modal card.',
      'ember-remodal-class-no-longer-merges-class'
    );
  }
},
```

f. In `_checkForTestingEnv()`, inside the existing `if (disableAnimation && env === 'test')` block, after the `set`:

```js
warnOnce(
  config,
  'ember-remodal.disable-animation-while-testing',
  'disableAnimationWhileTesting only works with the classic resolver in 3.0. Prefer setupRemodal(hooks, { disableAnimation: true }) from ember-remodal/test-support.',
  'disableanimationwhiletesting--classic-resolver-only'
);
```

(`config` is already in scope there.)

- [ ] **Step 4: Run tests** — all Task 3 cases green except case 6's service half; the pre-existing suite must stay green (behavior-frozen check).

- [ ] **Step 5: Commit** — `git add -A addon tests && git commit -m "feat: 2.19 runtime deprecations on the ember-remodal component"`.

---

### Task 4: Service + er-button deprecations

**Files:**
- Modify: `addon/services/remodal.js`, `addon/components/er-button.js`, `addon/templates/components/ember-remodal.hbs` (2.x worktree)
- Test: extend `tests/integration/components/ember-remodal-deprecations-test.js`

**Interfaces:**
- Consumes: `warnOnce`, `INTERNAL_CALL` (Task 2); `open(internal)`/`close(internal)` (Task 3).

- [ ] **Step 1: Write failing tests** (same file/stub as Task 3):
1. Alias get: render forService modal; `service.get('title')` → contains `ember-remodal.service-option-aliases`.
2. Alias set: `service.set('text', 'x')` → contains `ember-remodal.service-option-aliases`, and afterwards `service.get('ember-remodal.text')` (path get, no alias) returns `'x'` — delegation intact.
3. `service.open()` / `service.close()` round-trip on a rendered forService modal (await the `remodal-is-opened` / `remodal-is-closed` class transitions) → `warningIds` contains only `ember-remodal.v3-available` — the sentinel keeps internal calls silent, and Task 3's case 6 now passes.
4. Unrendered name: `try { service.open('nope'); } catch (e) { /* dev assert */ }` → contains `ember-remodal.open-on-unrendered-name`.
5. Direct er-button: render `{{#ember-remodal/er-button}}x{{/ember-remodal/er-button}}` → contains `ember-remodal.er-button-direct`.
6. Yielded er-buttons stay silent: render block-form `{{#ember-remodal as |m|}}{{#m.open}}<button type="button">o</button>{{/m.open}}{{/ember-remodal}}` → does **not** contain `ember-remodal.er-button-direct`.

- [ ] **Step 2: Run, expect the new cases red.**

- [ ] **Step 3: Implement.**

a. `addon/services/remodal.js` — replace the whole alias block and wire the sentinel:

```js
import { assert } from '@ember/debug';
import { computed } from '@ember/object';
import { getOwner } from '@ember/application';
import Service from '@ember/service';
import { warnOnce, INTERNAL_CALL } from '../utils/deprecations';

function deprecatedOptionAlias(optionName) {
  let dependentKey = `ember-remodal.${optionName}`;

  return computed(dependentKey, {
    get() {
      this._warnOptionAlias(optionName);
      return this.get(dependentKey);
    },
    set(key, value) {
      this._warnOptionAlias(optionName);
      this.set(dependentKey, value);
      return value;
    }
  });
}

export default Service.extend({
  modal: null,
  title: deprecatedOptionAlias('title'),
  text: deprecatedOptionAlias('text'),
  confirmButton: deprecatedOptionAlias('confirmButton'),
  cancelButton: deprecatedOptionAlias('cancelButton'),
  disableNativeClose: deprecatedOptionAlias('disableNativeClose'),
  disableForeground: deprecatedOptionAlias('disableForeground'),
  disableAnimation: deprecatedOptionAlias('disableAnimation'),
  buttonClasses: deprecatedOptionAlias('buttonClasses'),
  modifier: deprecatedOptionAlias('modifier'),
  closeOnEscape: deprecatedOptionAlias('closeOnEscape'),
  closeOnCancel: deprecatedOptionAlias('closeOnCancel'),
  closeOnConfirm: deprecatedOptionAlias('closeOnConfirm'),
  hashTracking: deprecatedOptionAlias('hashTracking'),
  closeOnOutsideClick: deprecatedOptionAlias('closeOnOutsideClick'),

  open(name = 'ember-remodal', opts = null) {
    let modal = this.get(name);

    if (modal) {
      if (opts) {
        modal.setProperties(opts);
      }

      return modal.open(INTERNAL_CALL);
    } else {
      this._modalNotSetError(name);
    }
  },

  close(name = 'ember-remodal') {
    let modal = this.get(name);

    if (modal) {
      return modal.close(INTERNAL_CALL);
    } else {
      this._modalNotSetError(name);
    }
  },

  _warnOptionAlias(optionName) {
    warnOnce(
      this._getConfig(),
      'ember-remodal.service-option-aliases',
      `The service's option alias properties are removed in 3.0 (first seen: "${optionName}"). Pass options through service.open(name, options) instead.`,
      'the-services-property-aliases-are-removed'
    );
  },

  _getConfig() {
    return getOwner(this).resolveRegistration('config:environment');
  },

  _modalNotSetError(name) {
    warnOnce(
      this._getConfig(),
      'ember-remodal.open-on-unrendered-name',
      `open()/close() was called for "${name}", which is not currently rendered. 3.0 returns a rejected promise in every build (2.x throws in development and silently no-ops in production).`,
      'serviceopen--close-on-an-unrendered-name-always-reject'
    );
    assert(
      `The requested modal, "${name}" can not be opened because it is not rendered in the current route. In order to use ember-remodal as a service, an instance of {{ember-remodal}} must currently be rendered, with "forService=true". Try putting it in your application template.`
    );
  }
});
```

(The `assert` message is byte-identical to master — behavior-frozen.)

b. `addon/templates/components/ember-remodal.hbs` — add `_yielded=true` to each of the three `(component 'ember-remodal/er-button' …)` entries in the yield hash.

c. `addon/components/er-button.js` — add imports (`getOwner` from `@ember/application`, `warnOnce` from `../utils/deprecations`) and:

```js
didInsertElement() {
  this._super(...arguments);

  if (this.get('_yielded') !== true) {
    warnOnce(
      getOwner(this).resolveRegistration('config:environment'),
      'ember-remodal.er-button-direct',
      'Invoking ember-remodal/er-button directly is broken by 3.0: the import path moved, modalId= became @destination (an Element, not an id), and action= became @onClick. Prefer the yielded m.open / m.confirm / m.cancel, which bind both for you.',
      'er-button-the-import-path-moved-and-both-arguments-were-renamed'
    );
  }
},
```

- [ ] **Step 4: Run the full suite** — all deprecation cases green, pre-existing suite green.

- [ ] **Step 5: Commit** — `git add -A addon tests && git commit -m "feat: 2.19 runtime deprecations on the remodal service and er-button"`.

---

### Task 5: Readiness audit prompt (er-f0t.3)

**Files:**
- Modify: `MIGRATION.md` (modernize branch) — new `### The readiness audit prompt` subsection (placed inside Task 6's `## The two-step upgrade path` section; if executing before Task 6, add it under a bare `## The two-step upgrade path` heading that Task 6 will flesh out).

**Interfaces:**
- Produces: the fenced prompt block, dogfooded. Task 6 links to it; the demo renders it automatically.

- [ ] **Step 1: Add the prompt.** Full text (fenced as ` ```text ` inside MIGRATION.md; one short intro sentence above it: "Paste everything in the block below into your coding assistant — Claude Code, Cursor, Copilot, or any agent that can search your repository."):

```text
Audit this Ember app for upgrade readiness from ember-remodal 2.x to 3.0.
3.0 is a rewrite on the native <dialog> element. The runtime deprecations in
ember-remodal 2.19 already cover option/API usage the app exercises at
runtime; YOUR job is the breaks that leave no runtime trace: CSS selectors,
test selectors, markup assumptions, and version floors. Search stylesheets
(css/scss/sass/less/styl), templates (hbs/gjs/gts), JS/TS, and tests.

Hard floors — check these first; if either fails the verdict is NOT READY:
0a. package.json: ember-source must be >= 5.8.
0b. Browser floor Chrome/Edge 99, Firefox 98, Safari 15.4 (needs
    dialog.showModal() and CSS @layer; no polyfill). Check browserslist
    config ("browserslist" in package.json or .browserslistrc).

Core checks — for each, report every finding as file:line plus the fix:
1. Bare single-word class hooks in stylesheets and tests: .window .close
   .button .open .link .text .outer .inner .title .paragraph .yielded
   .content .native .confirm .cancel .invisible. Flag ONLY selectors that
   target ember-remodal markup (compounded with .ember-remodal or .remodal*,
   or used in tests that interact with the modal) — these tokens are common,
   so judge context, don't just count grep hits. Fix: the ember-remodal-
   prefixed replacements (see "the bare single-word class hooks are retired"
   in MIGRATION.md). @legacyClassNames={{true}} re-emits the old tokens
   per-modal as a temporary bridge.
2. [data-remodal-id] selectors → [data-test-id="modalWindow"] or @dataTestId.
3. .remodal-overlay → dialog.remodal-wrapper::backdrop (there is no overlay
   element anymore).
4. Tests that dismiss the modal by clicking outside/on the overlay: 3.0
   dismisses only when mousedown AND click both land on the backdrop, so a
   synthetic click alone may stop working — flag for press+release semantics.
5. Yielded m.open / m.confirm / m.cancel blocks (any block-param name) whose
   block contains no focusable control (button, a[href], input, [tabindex]).
   3.0 warns in development; keyboard users can't reach them. Fix: wrap the
   label in <button type="button">.
6. Direct er-button usage: imports of ember-remodal/components/er-button and
   template invocations of ember-remodal/er-button or <ErButton>. The import
   path moved, modalId= became @destination (an Element, not an id string),
   action= became @onClick — and nothing fails at build time. Fix: prefer
   the yielded m.open / m.confirm / m.cancel.
7. Modals passing confirmButton/cancelButton (as arguments or via
   service.open options): those buttons are now actually styled
   (remodal-confirm / remodal-cancel, flat green/red). Flag for a visual
   check; @confirmButtonClasses / @cancelButtonClasses still apply.
8. !important overrides targeting .remodal-close::before font-family, or
   visibility on the modal card: the 3.0 stylesheet ships in @layer
   ember-remodal and its two !important declarations now beat unlayered
   !important. Fix: declare your own layer after it —
   @layer ember-remodal, my-overrides; — and override inside it.
9. registerWarnHandler filters on
   "ember-remodal.close-called-on-unitialized-modal" (2.x typo): 3.0 spells
   it "...-uninitialized-...", so the filter stops matching.
10. RSVP-specific handling of promises returned by open()/close():
    "instanceof RSVP.Promise" checks (now false), and .then callbacks that
    rely on RSVP's autorun to land inside a runloop (native promise
    callbacks don't; wrap in Ember's runloop yourself if needed).

Appendix — the 2.19 runtime warnings cover these, but if the app skipped
that step, grep for them too: string action names (onOpen="name" etc.),
hashTracking, service option properties (this.remodal.set('title', ...) /
.get('title')), reaching modals through the service
(this.remodal.get('someModalName')), curly {{ember-remodal class="..."}},
and disableAnimationWhileTesting in config/environment.js.

Report format — produce exactly this, then stop:
# ember-remodal 3.0 readiness report
Verdict: READY | READY WITH CHANGES | NOT READY
(NOT READY only for a failed hard floor; READY only with zero findings.)
| # | Check | Status (clear / needs change) | Findings (file:line) | Fix |
...one row per check 0a-10...
Then "Fix order:" — a short ordered list, floors first, then test-breaking
changes, then cosmetic. Only report findings you located with file:line
evidence; mark checks with no findings as clear; do not pad with maybes.
```

- [ ] **Step 2: Dogfood against the 2.x dummy app.** In the Task-1 worktree (`/Users/seth/Documents/GitHub/ember-remodal-2x`), execute the prompt's instructions yourself (or via a dispatched subagent given only the prompt text and that directory) against `tests/dummy/`. Expected: hard floors fail (it's an Ember 2.18 app — verdict NOT READY proves check 0 works), and the core checks surface real hits (the dummy templates/tests use the old surface, e.g. bare class hooks and `data-test-id` interactions). Sanity-check: no check errors out, the report format is followed, no finding lacks file:line.

- [ ] **Step 3: Fix what dogfooding exposes** (ambiguous instruction, check that can't be executed as written, noisy false positives — tighten wording in the prompt block, re-dogfood the changed checks).

- [ ] **Step 4: Commit** (modernize branch) — `git add MIGRATION.md && git commit -m "docs: 2.x->3.0 readiness audit prompt (er-f0t.3)"`. `bd close er-f0t.3`.

---

### Task 6: Guides (er-f0t.4)

**Files:**
- Modify: `MIGRATION.md`, `README.md` (modernize branch)
- Create: `demo-app/modifiers/copy-code.ts` (or follow whatever modifier convention exists in `demo-app/`)
- Modify: `demo-app/templates/migration.gts`
- Test: the existing demo rendering suite under `tests/` (extend where the migration page is covered)

**Interfaces:**
- Consumes: Task 5's prompt subsection; the spec's anchor list.

- [ ] **Step 1: MIGRATION.md two-step section.** Insert `## The two-step upgrade path` after the intro paragraph, before `## Requirements`, and add it to the TOC list. Content contract (write as prose matching the document's voice): **Step 1** — upgrade to `ember-remodal@2.19`, run the app (a real build, not just tests — the warnings are `console.warn` precisely so they survive production builds), exercise your modals, and fix every `[ember-remodal] DEPRECATION` line; each names its id and links its section here; warnings fire once per id per page load; `ENV['ember-remodal'] = { silenceDeprecations: true }` turns them all off for apps staying on 2.x. **Step 2** — run the readiness audit prompt (Task 5's subsection lives here) to catch what runtime can't see: CSS/test selectors, markup assumptions, and the version floors. Then upgrade per the rest of this guide.

- [ ] **Step 2: Anchor integrity check.** Extract every heading from MIGRATION.md, slugify GitHub-style, and confirm all ten anchors from the spec's catalog table exist:

```bash
grep -E '^#{2,3} ' MIGRATION.md | sed -E 's/^#+ //; s/[`(),:!"'"'"'={}\/\.…→—]//g; s/[[:space:]]/-/g' | tr '[:upper:]' '[:lower:]' | sort > /tmp/anchors.txt
for a in the-two-step-upgrade-path string-actions--function-arguments hashtracking-removed ember-remodal-class-no-longer-merges-class the-services-property-aliases-are-removed reaching-the-modal-component-through-the-service-is-removed the-modal-property-and-getstate-is-removed serviceopen--close-on-an-unrendered-name-always-reject er-button-the-import-path-moved-and-both-arguments-were-renamed disableanimationwhiletesting--classic-resolver-only; do grep -qx "$a" /tmp/anchors.txt || echo "MISSING: $a"; done
```

Expected: no `MISSING:` lines. If the sed approximation misfires on a heading, verify that one anchor manually against the rendered GitHub page and correct whichever side is wrong (heading or the 2.x branch's anchor string — they must match exactly; fix the 2.x branch before Task 7 if it's the warning that's wrong).

- [ ] **Step 3: README.** In the install section, add an "Upgrading from 2.x?" paragraph: link `MIGRATION.md#the-two-step-upgrade-path`, one sentence naming the two steps. Nothing else.

- [ ] **Step 4: Demo copy buttons.** Add a `copy-code` modifier applied to the `<article class="docs-markdown">` element in `migration.gts`: on install, for each `pre` child, append a `<button type="button" class="demo-copy">Copy</button>` that writes the `pre`'s `textContent` to `navigator.clipboard` and flips its label to `Copied!` for 2s — port the exact clipboard/label logic from `demo-app/components/demo-example.gts` (lines ~24–40) rather than inventing new handling, and reuse the existing `demo-copy` class so styling comes free. Position the button via the same pattern demo-example uses.

- [ ] **Step 5: Test.** Extend the demo rendering suite where the migration page renders: assert the page contains the string `The two-step upgrade path` and at least one `.docs-markdown .demo-copy` button. Run the suite per repo convention (`pnpm test` / existing test script) — expect green, plus `pnpm lint` clean.

- [ ] **Step 6: Commit** — `git add -A MIGRATION.md README.md demo-app tests && git commit -m "docs: teach the two-step 2.x->3.0 upgrade path (er-f0t.4)"`. `bd close er-f0t.4`. Ordinary push of the modernize branch is fine.

---

### Task 7: Release 2.19.0 (gated + surfaced)

**Files:**
- Modify: `package.json` (2.x worktree — version only)

- [ ] **Step 1: Preflight.** All Task 2–4 tests green (or smoke-app checklist verified under DEGRADED GO). Then the ordering gate: `curl -s -o /dev/null -w '%{http_code}' https://github.com/sethbrasile/ember-remodal/blob/master/MIGRATION.md` must print `200` (modernize branch merged). If not: hold here and say so — do not publish.

- [ ] **Step 2: Version bump** — in the 2.x worktree set `"version": "2.19.0"`, commit `git commit -am "release: 2.19.0"`, tag `git tag v2.19.0`.

- [ ] **Step 3: Pack sanity** — `npm pack`; confirm the tarball contains `package/addon/utils/deprecations.js` and version 2.19.0 in `package/package.json`.

- [ ] **Step 4: SURFACE TO SETH — do not run unprompted:** `npm publish` (lands on dist-tag `latest`), `git push origin 2.x --tags`. Present both commands, the pack contents summary, and the test evidence; wait for the nod.

- [ ] **Step 5: After publish** — smoke-verify `npm view ember-remodal dist-tags` shows `latest: 2.19.0`; `bd close er-f0t.2`; draft a GitHub release for `v2.19.0` from the deprecation catalog table (creation is outward-facing — include it in the same surfaced batch or a follow-up nod). Remove the worktree when everything is done: `git worktree remove /Users/seth/Documents/GitHub/ember-remodal-2x`.

---

### Task F (only on NO-GO, after confirming with Seth): docs-only fallback

**Files:**
- Modify: `MIGRATION.md`, `README.md` (modernize branch)

- [ ] **Step 1:** In Task 5's prompt, promote the "Appendix" greps to first-class checks 11–16 (same one-line-each format, now with the fix text from the spec catalog's message column), and delete the appendix framing.
- [ ] **Step 2:** Write Task 6's MIGRATION.md section as a **one-step, audit-first** path (no 2.19: "run the audit prompt, fix its report, then upgrade"), and Task 6's README pointer accordingly. Tasks 5/6's dogfood, anchor-check, copy-button, and test steps all still apply.
- [ ] **Step 3:** `bd close er-f0t.2` with reason `wontfix: 2.x toolchain NO-GO, see feasibility report`; close `.3`/`.4` as delivered; note the outcome on `er-f0t`.

---

## Execution order

```
Task 1 (feasibility) ──┬─ GO / DEGRADED ─→ Tasks 2→3→4 (2.x branch)   ─┐
                       │                   Tasks 5→6 (modernize branch)─┴→ Task 7 (release, gated + surfaced)
                       └─ NO-GO (confirm) → Tasks 5→6 via Task F
```

Tasks 2–4 and 5–6 touch different branches and can run in parallel. Task 7 is last, always.
