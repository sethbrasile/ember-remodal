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

| Path                | What it is                                                           |
| ------------------- | -------------------------------------------------------------------- |
| `src/`              | The addon itself. Everything published lives here                     |
| `src/test-support/` | The published `ember-remodal/test-support` entry point                |
| `src/styles/`       | The ported Remodal theme, imported by the component                  |
| `tests/`            | The test suite (rendering + unit), run against the built addon        |
| `demo-app/`         | The Vite-served demo application                                     |
| `scripts/`          | `link-self.mjs` (used by `pnpm test`) and `check-declaration-deps.mjs` |
| `.try.mjs`          | The `@embroider/try` compatibility scenarios CI runs                  |

## Linting

- `pnpm lint` — runs format, template-lint, ESLint, types and publish checks in
  parallel
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

## Running the demo application

- `pnpm start`
- Vite prints the URL it chose; by default that is
  [http://localhost:5173](http://localhost:5173).

## Compatibility scenarios

CI runs the `@embroider/try` scenarios declared in `.try.mjs` — Ember 5.8, 5.12,
6.4, 6.12, `latest`, `beta` and `alpha`, with the two LTS scenarios building
through `@embroider/compat`. To reproduce one locally:

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
