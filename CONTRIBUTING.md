# How To Contribute

ember-remodal 3.x is a [v2 addon](https://rfcs.emberjs.com/id/0507-embroider-v2-addon-format/):
the build is rollup + `@embroider/addon-dev`, the demo app and the test suite are
served by Vite, and the suite runs under testem. There is no ember-cli in the
development loop.

## Installation

- `git clone <repository-url>`
- `cd ember-remodal`
- `pnpm install`

pnpm is required — the version is pinned in `package.json#packageManager`, and CI
installs with `--frozen-lockfile`.

## Repository layout

| Path                | What it is                                                     |
| ------------------- | -------------------------------------------------------------- |
| `src/`              | The addon itself. Everything published lives here              |
| `src/test-support/` | The published `ember-remodal/test-support` entry point         |
| `src/styles/`       | The ported Remodal theme, imported by the component            |
| `tests/`            | The test suite (rendering + unit), run against the built addon |
| `demo-app/`         | The Vite-served demo application                               |
| `scripts/`          | Build, lint and release helpers — see below                    |
| `.try.mjs`          | The `@embroider/try` compatibility scenarios CI runs           |

`scripts/` holds `link-self.mjs` (used by `pnpm test`),
`check-declaration-deps.mjs` (used by `lint:publish`),
`css-mutation-selftest.mjs` (`verify:css-deviations`, below),
`assert-clean-tree.mjs` (`prepublishOnly`),
`verify-published-package.mjs` and the `publish-gate/` consumer smoke tests.

## Linting

- `pnpm lint` — runs all six checks in parallel: `lint:audit`, `lint:format`,
  `lint:hbs`, `lint:js`, `lint:publish`, `lint:types`
- `pnpm lint:fix`
- `pnpm lint:publish` — builds, then runs `publint`, `attw --pack .`, and
  `scripts/check-declaration-deps.mjs` (which fails if any specifier in
  `declarations/` is reachable only from a `devDependency` — the gap `attw`
  cannot see)

## Building the addon

- `pnpm build` — the full build, including the declaration emit
- `pnpm build:dist` — the same build with declarations skipped
  (`SKIP_DECLARATIONS:true`), which is what `pnpm test` uses

## Running tests

- `pnpm test` — runs the suite in headless Chrome

`pnpm test` first runs `build:dist` and then `scripts/link-self.mjs`, which links
the package into its own `node_modules`. That is what lets the suite import the
addon by package name (`ember-remodal`, `ember-remodal/test-support`,
`ember-remodal/_app_/…`) and so exercise the `exports` map and the app-tree
re-exports, rather than only reaching `src/` through the `#src/*` import alias. A
cold `pnpm install && pnpm test` therefore works with no extra steps.

Every rendering module calls `setupRemodal(hooks)` from the addon's own
test-support entry point. The scroll lock is module-level state that lives outside
`#ember-testing`, and that hook is what keeps a leak from cascading through the
rest of the run.

### The CSS mutation corpus

- `pnpm verify:css-deviations` — `scripts/css-mutation-selftest.mjs`

For every entry in the deviation registry in `CHANGELOG.md` (between the
`<!-- deviation-registry:start/end -->` markers) and for every published WCAG
figure, it deletes or neutralises the backing CSS, rebuilds, re-runs the theme
module and requires the pinning test to go **red**. A pinning test that stays
green under its own mutation is a failure. Three meta-checks run first, so the
corpus cannot rot: every registry id must be claimed by a mutation, every corpus
id must exist in the registry, and every test in the theme module must be killed
by some mutation. That is why a twelfth deviation cannot be added without a test
that would notice its loss — and why those markers and the numbered entries
between them should not be reformatted without re-running the script.

It is a release gate, not a per-commit one: 26 mutations at a rebuild plus a
full suite each, roughly ten minutes serialised. `.github/workflows/css-mutation-corpus.yml`
runs it on `workflow_dispatch` and on `v*` tag pushes rather than on every push.
Note that GitHub only registers a `workflow_dispatch` trigger once the workflow
file exists on the default branch, so the manual button does not appear for this
workflow until the branch adding it is merged; run the script locally until
then.

Touched `src/styles/` or `tests/rendering/ember-remodal-theme-test.gts`? Run it
before you push.

## Running the demo application

- `pnpm start`
- Vite prints the URL it chose; by default that is
  [http://localhost:5173](http://localhost:5173).

## Compatibility scenarios

CI runs the eight `@embroider/try` scenarios declared in `.try.mjs`:
`glimmer-component-1.1.2` (which pins the declared `@glimmer/component >= 1.1.2`
floor against Ember 5.8, since every other scenario leaves it at the repo's
`^2.0.0`), `ember-lts-5.8`, `ember-lts-5.12`, `ember-lts-6.4`, `ember-lts-6.12`,
`ember-latest`, `ember-beta` and `ember-alpha`. The first three set
`ENABLE_COMPAT_BUILD` and build through `@embroider/compat`; 6.4 and up build
natively. To reproduce one locally:

```sh
pnpm exec try list
pnpm exec try apply ember-lts-5.12
pnpm install --no-lockfile
pnpm test
```

`pnpm exec try apply` rewrites `package.json`, so revert it when you are done.

## Further reading

- [Embroider v2 addon format](https://github.com/embroider-build/embroider/blob/main/docs/v2-faq.md)
- [`@embroider/addon-dev`](https://github.com/embroider-build/embroider/tree/main/packages/addon-dev)
- [Vite guide](https://vite.dev/guide/)
