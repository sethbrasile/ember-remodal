# 2.x Toolchain Feasibility Report

**Date:** 2026-08-20 (revised same day — see "Revision" below)
**Task:** er-f0t.1 (Feasibility gate)
**Repo:** ember-remodal 2.18.0 (from origin/master)

---

## Verdict

**GO**

The 2018 toolchain builds and the full test suite passes (116/116) under a
pinned Node with the era-exact dependency tree from the committed `yarn.lock`.

- **Pinned Node:** v8.17.0 (`~/.nvm/versions/node/v8.17.0`)
- **Install command:** `yarn install --frozen-lockfile --ignore-engines --ignore-optional --non-interactive` (yarn 1.22.19, installed globally under the pinned Node)
- **Build command:** `./node_modules/.bin/ember build` — succeeds
- **Working test command:** `./node_modules/.bin/ember test` — 116 pass, 0 fail (Chrome 151, headless)
- **Worktree:** `/Users/seth/Documents/GitHub/ember-remodal-2x`

### Required local change: testem.js Chrome args

2018-era testem (2.12.0) launch args do not work with modern Chrome on this
machine (Apple Silicon, Chrome 151). One-line change, must be carried onto the
`2.x` branch:

```diff
-        '--headless',
+        '--headless=new', '--no-sandbox', '--user-data-dir=/tmp/testem-chrome-profile', '--disable-dev-shm-usage',
```

Without `--user-data-dir` pointing at a throwaway profile, Chrome starts but
never connects to testem ("Browser failed to connect within 30s").

---

## Revision: why the first pass said NO-GO

The initial run concluded NO-GO after `npm install` + `ember build` failed on
Node 6/8/10 (mktemp@2.0.3 `require('node:fs')`, `npm ERR! Unsupported URL
Type: npm:wrap-ansi@^7.0.0`). Those observations were real but the method was
wrong: **`npm install` ignores the committed `yarn.lock`** and fresh-resolved
every semver range to 2026 versions. The drifted tree pulled in mktemp 2.x and
packages using the `npm:` alias protocol — none of which exist in the locked
2018 tree (`yarn.lock` pins `mktemp@0.4.0` via `quick-temp`, plain `fs` API,
Node-8-safe).

Installing with yarn 1.x and `--frozen-lockfile` reproduces the era tree
exactly; the registry still serves every pinned tarball. Install completes in
~26s with only peer-dependency warnings, and build + tests pass.

Original NO-GO findings preserved below for the record.

---

## Step-by-Step Results (corrected run, Node v8.17.0)

1. **Worktree** — ✅ `/Users/seth/Documents/GitHub/ember-remodal-2x`
2. **Pin Node** — ✅ v8.17.0 / npm 6.13.4 / yarn 1.22.19
3. **Install** — ✅ `yarn install --frozen-lockfile --ignore-engines --ignore-optional` clean in 26s (peer-dep warnings only; fsevents skipped via `--ignore-optional`)
4. **Build** — ✅ `ember build` succeeds ("Could not start watchman" notice is harmless)
5. **Test runner** — ✅ `ember test`: 116 pass / 0 fail after the testem.js Chrome-args fix above
6. **Pack** — ✅ `npm pack` produces `ember-remodal-2.18.0.tgz` with `package/index.js`, `package/addon/`, `package/app/` (18.3 kB unpacked)
7. **Smoke app** — not needed (GO path: steps 3–5 all green). If ever needed, note `npx ember-cli@2.18.2 new` hits the same drift problem — an era consumer must be built from a locked tree, not fresh resolution.

## Consequences for later tasks

- GO path per plan: Tasks 2–7 proceed, test suite is the verification vehicle.
- The testem.js diff must be committed on the `2.x` branch (Task 2).
- All 2.x-branch work must install with yarn `--frozen-lockfile` under Node
  v8.17.0. Never run `npm install` in the 2x worktree; it clobbers the tree.
  New devDependencies (if any) must be added via `yarn add` under the pinned
  Node so `yarn.lock` stays consistent.

---

## Appendix: original (superseded) NO-GO findings

Method: `npm install` (no lockfile respected) on pinned Nodes, then `ember build`.

### Node v8.17.0 — npm 6.13.4
- install completed (1645 packages) with fsevents build failure; `ember build` failed: `Error: Cannot find module 'node:fs'` from `mktemp/dist/creation.cjs` (mktemp@2.0.3 requires Node 12.4+)

### Node v6.17.1 — npm 3.10.10
- install failed: `npm ERR! Unsupported URL Type: npm:wrap-ansi@^7.0.0` (npm 3 predates the `npm:` alias protocol)

### Node v10.24.1 — npm 6.14.12
- same mktemp `node:fs` failure on build and on `npx ember-cli@2.18.2 new`

Root cause in all cases: fresh npm resolution drifted the transitive tree to
2026 versions. Not a property of the 2018 toolchain itself.
