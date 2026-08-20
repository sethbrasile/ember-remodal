/**
 * The RUNTIME half of the publish gate: imports every entry point of the
 * INSTALLED package and asserts what each one actually hands back.
 *
 * Runs inside the throwaway fixture project that
 * `scripts/verify-published-package.mjs` builds, against `ember-remodal`
 * installed from a real `npm pack` tarball — never against `src/`, never
 * against this repo's `node_modules`. Every specifier below is written the way
 * a consumer writes it, so `package.json#exports` is what resolves them.
 *
 * `ENTRIES` is also the gate's coverage ledger: the runner enumerates every
 * entry point the packed tarball exposes (literal `exports` keys plus every
 * file the `./*` and `./*.css` patterns can serve) and fails if any of them is
 * missing from this table. Adding a file to `dist/` without adding it here is
 * therefore a red gate, not a silent gap.
 */
import { createRequire } from 'node:module';
import { readFile } from 'node:fs/promises';
import { fileURLToPath, pathToFileURL } from 'node:url';

/**
 * @typedef {'module' | 'app-reexport' | 'types-only' | 'asset' | 'json' | 'cjs-hook'} EntryKind
 */

/** Every entry point a consumer can reach, and what it must provide. */
export const ENTRIES = [
  {
    specifier: 'ember-remodal',
    kind: 'module',
    exports: {
      default: 'function',
      EmberRemodal: 'function',
      ErButton: 'function',
      RemodalService: 'function',
    },
  },
  {
    // The same module through the `./*` pattern rather than the `.` key.
    specifier: 'ember-remodal/index',
    kind: 'module',
    exports: { default: 'function', RemodalService: 'function' },
  },
  {
    specifier: 'ember-remodal/test-support',
    kind: 'module',
    exports: {
      remodalDialog: 'function',
      remodalDialogs: 'function',
      resetRemodalScrollLock: 'function',
      setRemodalAnimationDisabled: 'function',
      setupRemodal: 'function',
    },
  },
  {
    specifier: 'ember-remodal/test-support/index',
    kind: 'module',
    exports: { setupRemodal: 'function' },
  },
  {
    specifier: 'ember-remodal/components/ember-remodal',
    kind: 'module',
    exports: { default: 'function' },
  },
  {
    specifier: 'ember-remodal/components/ember-remodal/er-button',
    kind: 'module',
    exports: { default: 'function' },
  },
  {
    specifier: 'ember-remodal/services/remodal',
    kind: 'module',
    exports: { default: 'function' },
  },
  // The classic app-tree re-exports. They import the addon BY PACKAGE NAME, so
  // importing them proves the published package can resolve itself through its
  // own `exports` — the failure mode that ships as "works in the repo, throws
  // in the app".
  {
    specifier: 'ember-remodal/_app_/components/ember-remodal',
    kind: 'app-reexport',
  },
  {
    specifier: 'ember-remodal/_app_/components/ember-remodal/er-button',
    kind: 'app-reexport',
  },
  {
    specifier: 'ember-remodal/_app_/services/remodal',
    kind: 'app-reexport',
  },
  {
    // Types-only by design: `template-registry.ts` is excluded from the rollup
    // entry points because building it emits an empty chunk. The assertion is
    // that it stays types-only — a runtime module appearing here would mean the
    // build started shipping something `consumer-types.ts` does not describe.
    specifier: 'ember-remodal/template-registry',
    kind: 'types-only',
  },
  {
    // README tells consumers to import this specifier directly.
    specifier: 'ember-remodal/styles/ember-remodal.css',
    kind: 'asset',
    // Identity only, not appearance: the theme's own contents are pinned by
    // the test suite, and a gate that restates them just breaks twice.
    contains: ['.remodal', '--ember-remodal-'],
  },
  { specifier: 'ember-remodal/package.json', kind: 'json' },
  { specifier: 'ember-remodal/addon-main.js', kind: 'cjs-hook' },
];

const require = createRequire(import.meta.url);
const failures = [];
const checked = [];

function check(label, condition, detail) {
  if (condition) {
    checked.push(label);
  } else {
    failures.push(`${label}: ${detail}`);
  }
}

async function checkModule(entry) {
  const namespace = await import(entry.specifier);
  for (const [name, expectedType] of Object.entries(entry.exports)) {
    check(
      `${entry.specifier} → ${name}`,
      typeof namespace[name] === expectedType,
      `expected a ${expectedType}, got ${typeof namespace[name]}`,
    );
  }
}

async function checkAppReexport(entry) {
  const namespace = await import(entry.specifier);
  check(
    `${entry.specifier} → default`,
    typeof namespace.default === 'function',
    `expected the re-exported class, got ${typeof namespace.default}`,
  );
}

async function checkTypesOnly(entry) {
  let resolved = true;
  try {
    await import(entry.specifier);
  } catch (error) {
    resolved = false;
    check(
      `${entry.specifier} (types-only)`,
      error.code === 'ERR_MODULE_NOT_FOUND' ||
        error.code === 'ERR_PACKAGE_PATH_NOT_EXPORTED',
      `expected no runtime module behind a types-only entry, got ${error.code}: ${error.message}`,
    );
  }
  if (resolved) {
    failures.push(
      `${entry.specifier} (types-only): a runtime module now exists behind this entry — either ship it deliberately (and change its kind here) or keep it out of dist/.`,
    );
  }
}

async function checkAsset(entry) {
  const url = import.meta.resolve(entry.specifier);
  const contents = await readFile(fileURLToPath(url), 'utf8');
  check(
    `${entry.specifier} (asset)`,
    contents.length > 0,
    'resolved to an empty file',
  );
  for (const needle of entry.contains) {
    check(
      `${entry.specifier} contains ${needle}`,
      contents.includes(needle),
      'the published stylesheet no longer contains it',
    );
  }
}

async function checkJson(entry) {
  const manifest = await import(entry.specifier, { with: { type: 'json' } });
  check(
    entry.specifier,
    manifest.default?.name === 'ember-remodal',
    `expected the addon manifest, got name=${manifest.default?.name}`,
  );
}

function checkCjsHook(entry) {
  const shim = require(entry.specifier);
  check(
    entry.specifier,
    typeof shim === 'object' && shim !== null && shim.name === 'ember-remodal',
    `expected the v1 addon shim descriptor, got ${JSON.stringify(shim)?.slice(0, 120)}`,
  );
}

/**
 * The service's registry is the behavior this major version rewrote, so the
 * gate exercises it through `dist/` rather than asserting the class is truthy:
 * register two modals under one name, prove the newest wins, prove unregistering
 * it uncovers the one it shadowed, and prove an unknown name rejects.
 */
async function checkServiceRegistry() {
  const { RemodalService } = await import('ember-remodal');
  const service = new RemodalService();

  const first = { open: () => Promise.resolve('first') };
  const second = { open: () => Promise.resolve('second') };

  service.register('checkout', first);
  service.register('checkout', second);
  check(
    'RemodalService: newest registration wins',
    (await service.open('checkout')) === 'second',
    'open() did not resolve through the most recently registered modal',
  );

  service.unregister('checkout', second);
  check(
    'RemodalService: unregistering uncovers the shadowed modal',
    (await service.open('checkout')) === 'first',
    'open() did not fall back to the modal that was shadowed',
  );

  service.unregister('checkout', first);
  let rejected = false;
  await service.open('checkout').catch((error) => {
    rejected = /can not be opened because it is not rendered/.test(
      error.message,
    );
  });
  check(
    'RemodalService: unknown name rejects',
    rejected,
    'open() on an empty registry did not reject with the diagnostic',
  );
}

async function main() {
  // Registered here rather than at module scope so that the runner can import
  // this file purely to read `ENTRIES` for its coverage check.
  const { register } = await import('node:module');
  register('./ember-runtime-stubs.mjs', import.meta.url);

  for (const entry of ENTRIES) {
    try {
      switch (entry.kind) {
        case 'module':
          await checkModule(entry);
          break;
        case 'app-reexport':
          await checkAppReexport(entry);
          break;
        case 'types-only':
          await checkTypesOnly(entry);
          break;
        case 'asset':
          await checkAsset(entry);
          break;
        case 'json':
          await checkJson(entry);
          break;
        case 'cjs-hook':
          checkCjsHook(entry);
          break;
        default:
          failures.push(`${entry.specifier}: unknown entry kind`);
      }
    } catch (error) {
      failures.push(
        `${entry.specifier}: ${error.code ?? error.name} — ${error.message.split('\n')[0]}`,
      );
    }
  }

  try {
    await checkServiceRegistry();
  } catch (error) {
    failures.push(
      `RemodalService registry: ${error.code ?? error.name} — ${error.message.split('\n')[0]}`,
    );
  }

  if (failures.length > 0) {
    console.error(
      `\nsmoke: ${failures.length} failure(s) importing the published package:\n`,
    );
    for (const failure of failures) console.error(`  ✗ ${failure}`);
    process.exitCode = 1;
    return;
  }

  console.log(
    `smoke: ${checked.length} assertions passed across ${ENTRIES.length} published entry points.`,
  );
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(process.argv[1]).href
) {
  await main();
}
