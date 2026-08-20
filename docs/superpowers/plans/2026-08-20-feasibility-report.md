# 2.x Toolchain Feasibility Report

**Date:** 2026-08-20
**Task:** er-f0t.1 (Feasibility gate)
**Repo:** ember-remodal 2.18.0 (from origin/master)

---

## Verdict

**NO-GO**

No pinned Node version yields any bootable consumer of the addon tarball. Even the era-appropriate ember-cli@2.18.2 itself fails to install/run due to transitive dependencies requiring Node 12+.

---

## Pinned Node Versions Tested

### Node v8.17.0
- **npm version:** 6.13.4
- **npm install:** Completed (1645 packages) with fsevents build failure (Python 3 `collections.MutableSet` incompatibility) and mktemp engine warning
- **ember build:** Failed with `Error: Cannot find module 'node:fs'` from mktemp/dist/creation.cjs
- **Failure root cause:** mktemp@2.0.3 uses `require('node:fs')` syntax requiring Node 12.4+

### Node v6.17.1
- **npm version:** 3.10.10
- **npm install:** Failed immediately with `npm ERR! Unsupported URL Type: npm:wrap-ansi@^7.0.0`
- **Failure root cause:** npm v3 doesn't support the `npm:` protocol introduced in npm v6

### Node v10.24.1
- **npm version:** 6.14.12
- **npm install:** Completed (1645 packages) with fsevents build failure (Python 3 `open(build_file_path, 'rU')` incompatibility) and mktemp engine warning
- **ember build:** Failed with `Error: Cannot find module 'node:fs'` from mktemp/dist/creation.cjs
- **Smoke app creation:** Failed with same mktemp error when running `npx ember-cli@2.18.2 new`
- **Failure root cause:** mktemp@2.0.3 uses `require('node:fs')` syntax requiring Node 12.4+

---

## Step-by-Step Results

### Step 1: Create the 2.x worktree
✅ Success - worktree created at `/Users/seth/Documents/GitHub/ember-remodal-2x`

### Step 2: Pin old Node and record versions
✅ Success - Node v8.17.0 / npm 6.13.4 as expected

### Step 3: Install
⚠️ Partial success - `npm install` completes on v8.17.0 and v10.24.1 (with warnings and fsevents build failure), but fails on v6.17.1

### Step 4: Build
❌ Failed - `ember build` fails on both v8.17.0 and v10.24.1 with mktemp `node:fs` error

### Step 5: Test runner
❌ Skipped - Cannot test due to build failure

### Step 6: Pack
✅ Success - `npm pack` produces `ember-remodal-2.18.0.tgz` with correct structure:
- Contains `package/index.js`
- Contains `package/addon/` directory
- Contains `package/app/` directory
- Unpacked size: 18.3 kB

### Step 7: Minimal smoke app
❌ Failed - `npx ember-cli@2.18.2 new remodal-smoke --skip-git` fails with same mktemp error
- Cannot create any era-appropriate consumer app to verify the tarball

---

## Failures Verbatim

### v8.17.0 build failure:
```
module.js:550
    throw err;
    ^
Error: Cannot find module 'node:fs'
    at Function.Module._resolveFilename (module.js:548:15)
    at Function.Module._load (module.js:475:25)
    at Module.require (module.js:597:17)
    at require (internal/module.js:11:18)
    at Module.<anonymous> (/Users/seth/Documents/GitHub/ember-remodal-2x/node_modules/mktemp/dist/creation.cjs:4:15)
```

### v6.17.1 install failure:
```
npm ERR! Unsupported URL Type: npm:wrap-ansi@^7.0.0
```

### v10.24.1 build failure (same as v8.17.0):
```
internal/modules/cjs/loader.js:638
    throw err;
    ^
Error: Cannot find module 'node:fs'
    at Function.Module._resolveFilename (internal/modules/cjs/loader.js:636:15)
```

### v10.24.1 smoke app failure:
```
Error: Cannot find module 'node:fs'
    at Function.Module._resolveFilename (internal/modules/cjs/loader.js:636:15)
    at Module.require (internal/modules/cjs/loader.js:692:17)
    at require (internal/modules/cjs/helpers.js:25:18)
    at Module.<anonymous> (/<npx cache>/lib/node_modules/ember-cli/node_modules/mktemp/dist/creation.cjs:4:15)
```

---

## Analysis

The blocker is mktemp@2.0.3, a transitive dependency of ember-cli, which:
- Declares `"engines": {"node": "20 || 22 || 24"}` in its package.json
- Uses `require('node:fs')` syntax (introduced in Node 12.4)

This dependency chain makes ember-cli@2.18.2 (the era-appropriate CLI) impossible to run on any Node version prior to 12.4, which contradicts the original ember-cli 2.x engine support (`"^4.5 || 6.* || >= 7.*"`).

The addon tarball itself is correctly structured and should work in a functioning ember-cli@2.18 environment, but such an environment cannot be provisioned today due to dependency drift in the transitive ecosystem (mktemp upgraded to 2.0.3 sometime after 2018).

---

## Conclusion

This is a **NO-GO** outcome per the spec criteria:
- Neither GO (build + test) nor DEGRADED GO (smoke app boots) achieved
- No pinned Node yields any bootable consumer of the packed addon
- The 2018 dev toolchain is dead not just for the dummy app, but for ember-cli@2.18.2 itself

**Next action:** Confirm with Seth, then proceed to Task F (docs-only fallback) instead of Tasks 2–4 and 7.