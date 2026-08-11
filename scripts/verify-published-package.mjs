/**
 * The publish gate: makes the TARBALL the unit under test.
 *
 * Everything else in this repo verifies build *inputs*. `pnpm test` runs against
 * `src` (with one specifier pointed at `dist`), `lint:types` type-checks `src`
 * through a `paths` mapping that sends `ember-remodal*` right back to `src`, and
 * `attw`/`publint`/`check-declaration-deps` check that entry points *resolve* —
 * not that what they resolve to is correct. The gap that leaves is the one this
 * closes: a published `.d.ts` that is semantically broken, an `exports` entry
 * whose file was never built, or a named export that quietly vanished from
 * `dist/` all pass every one of those checks.
 *
 * So: `npm pack`, install the tarball into a throwaway project OUTSIDE this
 * repo, and there —
 *
 *   1. check coverage: every entry point the tarball exposes (literal `exports`
 *      keys plus every file the `./*` and `./*.css` patterns can serve) must be
 *      imported by both fixture files. A new file in `dist/` that nothing
 *      imports fails the gate rather than shipping unverified;
 *   2. type-check `consumer-types.ts` with `skipLibCheck: false`, reporting the
 *      diagnostics that belong to the fixture or to `ember-remodal` itself;
 *   3. run `consumer-smoke.mjs`, which imports every entry at runtime and
 *      asserts what each one hands back.
 *
 * Usage:
 *   node ./scripts/verify-published-package.mjs [--keep]
 *
 * `--keep` leaves the fixture project on disk and prints its path, which is how
 * you debug a red gate.
 */
import { execFileSync } from 'node:child_process';
import { mkdtempSync, rmSync } from 'node:fs';
import { copyFile, readdir, readFile, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const gateDir = join(root, 'scripts', 'publish-gate');
const keep = process.argv.includes('--keep');

const FIXTURE_FILES = [
  'consumer-types.ts',
  'consumer-smoke.mjs',
  'ember-runtime-stubs.mjs',
  'tsconfig.json',
];

/**
 * Versions the fixture installs alongside the tarball, pinned to whatever THIS
 * repo resolved. A floating range here would make the gate's result depend on
 * the day it ran; taking the repo's own versions means CI (a `--frozen-lockfile`
 * install) and a local run check the same thing.
 *
 * `@glint/ember-tsc` matters more than it looks: it exact-pins its own copy of
 * `@glint/template`, and two copies of that package in one tree are nominally
 * distinct types. That is why `@glint/template` is an OPTIONAL PEER of this
 * addon rather than a dependency — as a dependency it resolved independently,
 * and the second copy turned every `WithBoundArgs` in the published yield type
 * into a `TS2344` for anyone type-checking with `skipLibCheck: false`.
 */
const FIXTURE_DEPENDENCIES = [
  '@ember/app-tsconfig',
  '@glimmer/component',
  '@glint/ember-tsc',
  'ember-source',
  'typescript',
];

function run(command, args, options = {}) {
  return execFileSync(command, args, {
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
    ...options,
  });
}

/** Thrown rather than `process.exit`ed, so the fixture still gets cleaned up. */
class GateFailure extends Error {
  constructor(heading, details) {
    super(heading);
    this.name = 'GateFailure';
    this.details = details;
  }
}

function fail(heading, details) {
  throw new GateFailure(heading, details);
}

/** The version of `name` this repo actually installed. */
async function installedVersion(name) {
  const manifest = JSON.parse(
    await readFile(join(root, 'node_modules', name, 'package.json'), 'utf8'),
  );
  return manifest.version;
}

async function filesUnder(dir) {
  const entries = await readdir(dir, { recursive: true, withFileTypes: true });
  return entries
    .filter((entry) => entry.isFile())
    .map((entry) =>
      relative(dir, join(entry.parentPath, entry.name)).split(sep).join('/'),
    );
}

/**
 * Every specifier a consumer can write against this package, derived from the
 * packed tarball rather than from a hand-maintained list: literal `exports`
 * keys, plus — for each wildcard key — one specifier per file its target can
 * actually serve.
 */
async function publishedSpecifiers(packageDir, manifest) {
  const files = await filesUnder(packageDir);
  const specifiers = new Set();

  for (const [key, value] of Object.entries(manifest.exports)) {
    const subpath = key === '.' ? '' : `/${key.slice(2)}`;

    if (!key.includes('*')) {
      specifiers.add(`${manifest.name}${subpath}`);
      continue;
    }

    const targets = typeof value === 'string' ? [value] : Object.values(value);
    for (const target of targets) {
      const [prefix, suffix] = target.slice(2).split('*');
      for (const file of files) {
        if (!file.startsWith(prefix) || !file.endsWith(suffix)) continue;
        const star = file.slice(prefix.length, file.length - suffix.length);
        if (!star) continue;
        specifiers.add(`${manifest.name}${subpath.replace('*', star)}`);
      }
    }
  }

  return [...specifiers].sort();
}

/**
 * Specifiers `consumer-types.ts` imports WITH A BINDING.
 *
 * The binding requirement is not pedantry: TypeScript does not report an
 * unresolvable module for a side-effect-only `import 'x'`, so that form is a
 * gate that cannot fail. Verified: `import 'ember-remodal/styles/nope.css'`
 * and `import 'totally-not-real-pkg'` both type-check clean.
 */
function boundImports(source) {
  const bound = new Set();
  const sideEffectOnly = new Set();

  for (const [, clause, specifier] of source.matchAll(
    /\b(?:import|export)\s+([^'";]*?)\s*from\s*['"]([^'"]+)['"]/g,
  )) {
    if (clause.trim()) bound.add(specifier);
  }
  for (const [, specifier] of source.matchAll(/\bimport\s*['"]([^'"]+)['"]/g)) {
    sideEffectOnly.add(specifier);
  }

  return { bound, sideEffectOnly };
}

async function main() {
  console.log('publish gate: packing…');
  const packDir = mkdtempSync(join(tmpdir(), 'ember-remodal-pack-'));
  const packed = JSON.parse(
    run('npm', ['pack', '--json', '--pack-destination', packDir], {
      cwd: root,
    }),
  );
  const tarball = join(packDir, packed[0].filename);
  console.log(
    `publish gate: packed ${packed[0].filename} (${packed[0].files.length} files, ${(packed[0].size / 1024).toFixed(1)} kB)`,
  );

  const fixture = mkdtempSync(join(tmpdir(), 'ember-remodal-publish-gate-'));

  try {
    if (!relative(root, fixture).startsWith('..')) {
      fail('the fixture project must live outside this repository', [fixture]);
    }

    const dependencies = { 'ember-remodal': `file:${tarball}` };
    for (const name of FIXTURE_DEPENDENCIES) {
      dependencies[name] = await installedVersion(name);
    }

    await writeFile(
      join(fixture, 'package.json'),
      `${JSON.stringify(
        {
          name: 'ember-remodal-publish-gate-fixture',
          private: true,
          version: '0.0.0',
          type: 'module',
          dependencies,
        },
        null,
        2,
      )}\n`,
    );
    for (const file of FIXTURE_FILES) {
      await copyFile(join(gateDir, file), join(fixture, file));
    }

    console.log('publish gate: installing the tarball into a fresh project…');
    // npm, not pnpm: a consumer's flat `node_modules` is where a second copy of
    // a transitively-pinned package shows up, and that is a failure mode this
    // gate exists to see.
    try {
      run('npm', ['install', '--no-audit', '--no-fund', '--loglevel=error'], {
        cwd: fixture,
        stdio: ['ignore', 'inherit', 'inherit'],
      });
    } catch {
      fail('the packed tarball does not install into a fresh project', [
        'see the npm output above',
      ]);
    }

    const installed = join(fixture, 'node_modules', 'ember-remodal');
    const manifest = JSON.parse(
      await readFile(join(installed, 'package.json'), 'utf8'),
    );

    // 1. Coverage.
    const required = await publishedSpecifiers(installed, manifest);
    const { ENTRIES } = await import(join(gateDir, 'consumer-smoke.mjs'));
    const smoked = new Set(ENTRIES.map((entry) => entry.specifier));
    const { bound, sideEffectOnly } = boundImports(
      await readFile(join(gateDir, 'consumer-types.ts'), 'utf8'),
    );

    const gaps = [];
    for (const specifier of required) {
      if (!smoked.has(specifier)) {
        gaps.push(`${specifier} — not imported by consumer-smoke.mjs`);
      }
      if (!bound.has(specifier)) {
        gaps.push(
          sideEffectOnly.has(specifier)
            ? `${specifier} — imported by consumer-types.ts for side effects only, which cannot fail; give it a binding`
            : `${specifier} — not imported by consumer-types.ts`,
        );
      }
    }
    for (const specifier of smoked) {
      if (!required.includes(specifier)) {
        gaps.push(
          `${specifier} — listed in consumer-smoke.mjs but no longer reachable through package.json#exports`,
        );
      }
    }
    if (gaps.length > 0) {
      fail(
        `${gaps.length} published entry point(s) the gate does not cover`,
        gaps,
      );
    }
    console.log(
      `publish gate: ${required.length} published entry points, all covered by both fixture files.`,
    );

    // 2. Types.
    console.log('publish gate: type-checking with skipLibCheck: false…');
    let tscOutput = '';
    try {
      tscOutput = run(
        'npx',
        ['tsc', '--noEmit', '--pretty', 'false', '-p', 'tsconfig.json'],
        { cwd: fixture },
      );
    } catch (error) {
      tscOutput = `${error.stdout ?? ''}${error.stderr ?? ''}`;
    }

    const ours = [];
    let ignored = 0;
    let keeping = false;
    for (const line of tscOutput.split('\n')) {
      const start = line.match(/^(\S[^(]*)\((\d+),(\d+)\): (error|warning) /);
      if (start) {
        const file = start[1].split(sep).join('/');
        // Third-party libraries never opted into `skipLibCheck: false`; today
        // ember-source's own types and `@glimmer/*` report ~200 diagnostics
        // under it. Ours are the fixture's and the package under test's.
        keeping =
          !file.startsWith('node_modules/') ||
          file.startsWith('node_modules/ember-remodal/');
        if (!keeping) ignored += 1;
      } else if (/^error TS/.test(line)) {
        // Config-level errors have no file and are always ours.
        keeping = true;
      }
      if (keeping && line.trim()) ours.push(line);
    }

    if (ours.length > 0) {
      fail('the published types do not check against a consumer', ours);
    }
    console.log(
      `publish gate: types clean (${ignored} third-party lib diagnostics ignored).`,
    );

    // 3. Runtime.
    console.log('publish gate: importing every entry point at runtime…');
    try {
      run('node', ['consumer-smoke.mjs'], {
        cwd: fixture,
        stdio: ['ignore', 'inherit', 'inherit'],
      });
    } catch {
      fail('the published package does not behave when imported', [
        'see the smoke output above',
      ]);
    }

    console.log('\n✓ publish gate: the packed tarball is consumable.\n');
  } catch (error) {
    if (!(error instanceof GateFailure)) throw error;
    console.error(`\n✗ publish gate: ${error.message}\n`);
    for (const detail of error.details) console.error(`  - ${detail}`);
    console.error('');
    process.exitCode = 1;
  } finally {
    if (keep) {
      console.log(`publish gate: fixture kept at ${fixture}`);
      console.log(`publish gate: tarball kept at ${tarball}`);
    } else {
      rmSync(fixture, { recursive: true, force: true });
      rmSync(packDir, { recursive: true, force: true });
    }
  }
}

await main();
