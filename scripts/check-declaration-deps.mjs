/**
 * Every package the PUBLISHED declarations import must be something the
 * consumer necessarily has — i.e. one of our `dependencies` or
 * `peerDependencies`. A devDependency that leaks into `declarations/` resolves
 * fine here (it is right there in our own `node_modules`) and fails only in the
 * consumer's install, where `skipLibCheck: true` then downgrades it from an
 * error to silently degraded types.
 *
 * `attw` does not catch this: it validates that each entry point resolves, not
 * that the specifiers inside the emitted `.d.ts` files do.
 *
 * Runs as part of `lint:publish`, after the build that produces `declarations/`.
 */
import { readdir, readFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const declarationsDir = join(root, 'declarations');

const manifest = JSON.parse(await readFile(join(root, 'package.json'), 'utf8'));
const declared = new Set([
  ...Object.keys(manifest.dependencies ?? {}),
  ...Object.keys(manifest.peerDependencies ?? {}),
]);

/** `from '…'` / `import('…')` / `import type … from '…'`. */
const specifierPattern = /(?:\bfrom\s*|\bimport\s*\(?\s*)(['"])([^'"]+)\1/g;

function packageName(specifier) {
  const parts = specifier.split('/');
  return specifier.startsWith('@') ? parts.slice(0, 2).join('/') : parts[0];
}

const problems = [];

async function* declarationFiles(dir) {
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const path = join(entry.parentPath, entry.name);
    if (entry.isDirectory()) {
      yield* declarationFiles(path);
    } else if (/\.d(\.[^.]+)?\.ts$/.test(entry.name)) {
      yield path;
    }
  }
}

for await (const file of declarationFiles(declarationsDir)) {
  const contents = await readFile(file, 'utf8');
  for (const [, , specifier] of contents.matchAll(specifierPattern)) {
    if (specifier.startsWith('.') || specifier.startsWith('#')) continue;

    // `@ember/*` (and `ember` itself) are provided by ember-source, which has to
    // be a declared peer for any of them to resolve.
    const required = /^(@ember\/|ember$)/.test(specifier)
      ? 'ember-source'
      : packageName(specifier);

    if (!declared.has(required)) {
      problems.push(
        `${file.slice(root.length + 1)}: imports "${specifier}", but "${required}" is neither a dependency nor a peerDependency.`,
      );
    }
  }
}

if (problems.length > 0) {
  console.error(
    'check-declaration-deps: the published types import packages a consumer is not guaranteed to have:\n',
  );
  for (const problem of [...new Set(problems)]) console.error(`  - ${problem}`);
  console.error(
    '\nMove each one into "dependencies" or "peerDependencies" (peer, when the app must own the single copy).',
  );
  process.exit(1);
}

console.log(
  'check-declaration-deps: every specifier in declarations/ resolves from a declared dependency.',
);
