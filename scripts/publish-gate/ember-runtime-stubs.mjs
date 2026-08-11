/**
 * A Node module-customization hook that makes the PUBLISHED addon importable in
 * plain Node, so `consumer-smoke.mjs` can execute the real `dist/` modules.
 *
 * The addon's runtime imports fall into three groups:
 *
 * 1. Real npm packages it declares (`ember-modifier`, `@ember/test-waiters`,
 *    `decorator-transforms`). These are NEVER stubbed — resolving and
 *    evaluating them for real is half the point of the smoke: it proves the
 *    published dependency closure is complete and installable.
 * 2. Modules an Ember BUILD provides rather than npm (`@ember/service`,
 *    `@glimmer/tracking`, `@embroider/macros`, …). There is no such thing as
 *    resolving these in Node, so they are stubbed — but only from the allowlist
 *    below, and only after a real resolution has been attempted and failed. A
 *    specifier outside the allowlist that fails to resolve is a gate failure,
 *    which is what keeps this from quietly papering over a missing dependency.
 * 3. `.css` assets, which Node cannot load. Stubbed to an empty module; the
 *    stylesheet itself is asserted directly from disk by the smoke.
 *
 * The stub for a given specifier exports exactly the names its importer asks
 * for, read out of the importer's own source. That keeps the stub honest in the
 * one direction that matters: it can only satisfy an import that the published
 * code actually writes, and it can never invent an export of `ember-remodal`
 * itself (that package is not on the allowlist, so it always resolves for real).
 */
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

/** Specifier prefixes an Ember app's build supplies. Nothing else is stubbed. */
const STUB_PREFIXES = ['@ember/', '@glimmer/', '@embroider/macros'];
const STUB_EXACT = new Set(['ember']);

const STUB_SCHEME = 'ember-build-stub:';

function isStubbable(specifier) {
  return (
    STUB_EXACT.has(specifier) ||
    STUB_PREFIXES.some((prefix) => specifier.startsWith(prefix))
  );
}

/**
 * The export names `source` imports from `specifier`.
 *
 * The clause pattern deliberately excludes quotes and semicolons so it cannot
 * span from one statement's `import` to a later statement's `from '…'`.
 */
function importedNames(source, specifier) {
  const names = new Set();
  const escaped = specifier.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const pattern = new RegExp(
    String.raw`\b(?:import|export)\s+([^'";]*?)\s*from\s*['"]${escaped}['"]`,
    'g',
  );

  for (const [, clause] of source.matchAll(pattern)) {
    const trimmed = clause.trim();
    // `import * as ns from …` / `export * from …` need no named exports.
    if (trimmed.startsWith('*')) continue;

    const braced = trimmed.match(/\{([^}]*)\}/);
    if (braced) {
      for (const part of braced[1].split(',')) {
        const name = part
          .trim()
          .split(/\s+as\s+/)[0]
          ?.trim();
        if (name) names.add(name);
      }
    }

    // Anything left outside the braces is a default import binding.
    const head = trimmed
      .replace(/\{[^}]*\}/, '')
      .replace(/,/g, ' ')
      .trim();
    if (head) names.add('default');
  }

  return names;
}

export async function resolve(specifier, context, nextResolve) {
  if (!isStubbable(specifier)) return nextResolve(specifier, context);

  try {
    return await nextResolve(specifier, context);
  } catch (error) {
    if (
      error.code !== 'ERR_MODULE_NOT_FOUND' &&
      error.code !== 'ERR_PACKAGE_PATH_NOT_EXPORTED'
    ) {
      throw error;
    }

    let names = new Set();
    if (context.parentURL?.startsWith('file:')) {
      const source = await readFile(fileURLToPath(context.parentURL), 'utf8');
      names = importedNames(source, specifier);
    }

    return {
      // The names ride along in the URL so that two importers asking for
      // different names from the same module get their own stub instances.
      url: `${STUB_SCHEME}${specifier}?names=${[...names].join(',')}`,
      format: 'module',
      shortCircuit: true,
    };
  }
}

export async function load(url, context, nextLoad) {
  if (url.startsWith(STUB_SCHEME)) {
    const names = (new URL(url).searchParams.get('names') ?? '')
      .split(',')
      .filter(Boolean);

    const lines = [
      // Callable, constructible, and permissive under property access, so that
      // `class X extends Service`, `@tracked`-style decorator application and
      // `setComponentTemplate(...)` at module scope all survive evaluation.
      'const stub = (name) => {',
      '  const value = function (...args) { return args[0]; };',
      '  Object.defineProperty(value, "name", { value: name });',
      '  return new Proxy(value, { get: (target, key) => (key in target ? target[key] : stub(String(key))) });',
      '};',
    ];

    for (const name of names) {
      lines.push(
        name === 'default'
          ? 'export default stub("default");'
          : `export const ${name} = stub(${JSON.stringify(name)});`,
      );
    }

    return { format: 'module', shortCircuit: true, source: lines.join('\n') };
  }

  if (url.endsWith('.css')) {
    return { format: 'module', shortCircuit: true, source: 'export {};' };
  }

  return nextLoad(url, context);
}
