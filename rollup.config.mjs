import { babel } from '@rollup/plugin-babel';
import { Addon } from '@embroider/addon-dev/rollup';
import {
  copyFile,
  mkdir,
  readdir,
  readFile,
  rm,
  writeFile,
} from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { resolve, dirname, join, basename } from 'node:path';

const srcDir = 'src';
const declarationsDir = 'declarations';

const addon = new Addon({
  srcDir,
  destDir: 'dist',
});

/**
 * `--environment SKIP_DECLARATIONS:true` (what `pnpm test` passes) builds `dist`
 * without running `ember-tsc` for `declarations`.
 *
 * The test suite needs `dist`, because it imports the addon by package name to
 * exercise `package.json#exports` — but it does not need `declarations`: the
 * test app's types for those specifiers resolve to `src` through `tsconfig.json`
 * paths. Skipping the declaration emit keeps a test run fast, and keeps `pnpm
 * test` from failing a type-check against whichever `ember-source` an
 * `@embroider/try` scenario installed. `pnpm build` (and therefore
 * `lint:publish`, `prepack` and CI's packaging checks) still emits them.
 */
const skipDeclarations = Boolean(process.env.SKIP_DECLARATIONS);

const rootDirectory = dirname(fileURLToPath(import.meta.url));
const babelConfig = resolve(rootDirectory, './babel.publish.config.cjs');
const tsConfig = resolve(rootDirectory, './tsconfig.publish.json');

/**
 * Rewrite one relative import specifier from a `.d.ts` file so that it resolves
 * under `moduleResolution: node16`/`nodenext`, which this package needs because
 * it is `"type": "module"`.
 *
 * Two shapes need fixing:
 *
 * - `./foo.ts` — the source files carry explicit extensions (the rollup/babel
 *   build requires them) and TypeScript emits them verbatim.
 * - `./foo` — `@embroider/addon-dev` strips `.gts` from emitted declarations
 *   rather than replacing it, and extensionless specifiers are not resolvable
 *   in an ESM package.
 *
 * Both become `./foo.js`, which TypeScript maps back to `./foo.d.ts` and which
 * matches the real file emitted into `dist`.
 */
function rewriteDeclarationSpecifier(specifier) {
  if (!specifier.startsWith('./') && !specifier.startsWith('../')) {
    return specifier;
  }

  if (specifier.endsWith('.ts') && !specifier.endsWith('.d.ts')) {
    return `${specifier.slice(0, -'.ts'.length)}.js`;
  }

  // Anything with an extension already (`.js`, `.css`) is left alone.
  return basename(specifier).includes('.') ? specifier : `${specifier}.js`;
}

/**
 * Empties `declarations/` before the emit.
 *
 * `addon.clean()` prunes `dist/`, but nothing pruned `declarations/` — and
 * `package.json#files` publishes that directory wholesale. A `.d.ts` left over
 * from a renamed or deleted source therefore survived every rebuild and shipped:
 * `attw`, `publint` and `check-declaration-deps` all pass, because a stale
 * declaration nobody imports is not a resolution failure. Verified before the
 * fix by dropping a file into `declarations/`, rebuilding, and finding it in
 * `npm pack --dry-run`.
 *
 * `buildStart` runs before `addon.declarations()` invokes `ember-tsc` in its
 * `writeBundle` hook, so the emit refills the directory from scratch.
 */
function pruneDeclarations() {
  return {
    name: 'prune-declarations',
    async buildStart() {
      await rm(declarationsDir, { recursive: true, force: true });
    },
  };
}

/**
 * Post-processes the `declarations` directory that `addon.declarations()` emits:
 *
 * 1. Copies hand-written `.d.ts` files across. `ember-tsc` only emits
 *    declarations for the `.ts`/`.gts` sources it compiles, so a hand-written
 *    `.d.ts` under `src` is an input and never reaches `declarations/`, leaving
 *    the emitted declarations importing a file that isn't published.
 * 2. Rewrites relative import specifiers so they resolve. See
 *    `rewriteDeclarationSpecifier`.
 *
 * `closeBundle` runs after every `writeBundle` hook has settled, and
 * `addon.declarations()` waits for `ember-tsc` in its `writeBundle`, so the
 * declarations are complete by the time this runs.
 */
function finalizeDeclarations() {
  const specifierPattern = /(\bfrom\s*|\bimport\s*\(?\s*)(['"])([^'"]+)\2/g;
  // `foo.d.ts`, plus TypeScript's `foo.d.<ext>.ts` form for non-TS assets.
  const declarationFilePattern = /\.d(\.[^.]+)?\.ts$/;

  return {
    name: 'finalize-declarations',
    async closeBundle() {
      const srcEntries = await readdir(srcDir, {
        recursive: true,
        withFileTypes: true,
      });

      for (const entry of srcEntries) {
        if (!entry.isFile() || !declarationFilePattern.test(entry.name))
          continue;

        const from = join(entry.parentPath, entry.name);
        const to = join(
          declarationsDir,
          from.slice(srcDir.length + 1 /* path separator */),
        );

        await mkdir(dirname(to), { recursive: true });
        await copyFile(from, to);
      }

      const declarationEntries = await readdir(declarationsDir, {
        recursive: true,
        withFileTypes: true,
      });

      for (const entry of declarationEntries) {
        if (!entry.isFile() || !declarationFilePattern.test(entry.name))
          continue;

        const file = join(entry.parentPath, entry.name);
        const contents = await readFile(file, 'utf8');
        const rewritten = contents.replace(
          specifierPattern,
          (match, prefix, quote, specifier) =>
            `${prefix}${quote}${rewriteDeclarationSpecifier(specifier)}${quote}`,
        );

        if (rewritten !== contents) await writeFile(file, rewritten);
      }
    },
  };
}

export default {
  // This provides defaults that work well alongside `publicEntrypoints` below.
  // You can augment this if you need to.
  output: addon.output(),

  plugins: [
    // These are the modules that get built as their own entrypoints, so that
    // consumers can import them individually.
    //
    // Note that this plugin cannot *restrict* the public surface: it always
    // appends `**/*.ts`, `**/*.gts`, `**/*.gjs` and `**/*.hbs` to whatever
    // globs are passed here, and `src` contains no `.js` files at all. Only
    // `package.json#exports` decides what consumers can reach; `exclude` below
    // is the one lever that keeps a module out of `dist`.
    // See https://github.com/embroider-build/embroider/blob/main/docs/v2-faq.md#how-can-i-define-the-public-exports-of-my-addon
    addon.publicEntrypoints(['**/*.js'], {
      exclude: [
        // Hand-written declarations (`*.d.ts`, and `*.d.<ext>.ts` for
        // non-TS assets) are declaration-emit inputs, not modules.
        '**/*.d.ts',
        '**/*.d.*.ts',
        // Types-only module: building it produces an empty chunk. Consumers
        // reach it through `package.json#exports`' `types` condition.
        'template-registry.ts',
      ],
    }),

    // These are the modules that should get reexported into the traditional
    // "app" tree. Things in here should also be in publicEntrypoints above, but
    // not everything in publicEntrypoints necessarily needs to go here.
    addon.appReexports([
      'components/**/*.js',
      'helpers/**/*.js',
      'modifiers/**/*.js',
      'services/**/*.js',
    ]),

    // Follow the V2 Addon rules about dependencies. Your code can import from
    // `dependencies` and `peerDependencies` as well as standard Ember-provided
    // package names.
    addon.dependencies(),

    // This babel config should *not* apply presets or compile away ES modules.
    // It exists only to provide development niceties for you, like automatic
    // template colocation.
    //
    // By default, this will load the actual babel config from the file
    // babel.config.json.
    babel({
      extensions: ['.js', '.gjs', '.ts', '.gts'],
      babelHelpers: 'bundled',
      configFile: babelConfig,
    }),

    // Ensure that standalone .hbs files are properly integrated as Javascript.
    addon.hbs(),

    // Ensure that .gjs files are properly integrated as Javascript
    addon.gjs(),

    // Empty `declarations/`, emit .d.ts files, then make them resolvable: copy
    // hand-written .d.ts files across and give relative import specifiers real
    // `.js` extensions.
    ...(skipDeclarations
      ? []
      : [
          pruneDeclarations(),
          addon.declarations(
            declarationsDir,
            `pnpm ember-tsc --declaration --project ${tsConfig}`,
          ),
          finalizeDeclarations(),
        ]),

    // addons are allowed to contain imports of .css files, which we want rollup
    // to leave alone and keep in the published output.
    addon.keepAssets(['**/*.css']),

    // Remove leftover build artifacts when starting a new build.
    addon.clean(),
  ],
};
