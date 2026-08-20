/**
 * Declares the addon's stylesheet as a module so that the side-effect import in
 * `src/components/ember-remodal.gts` resolves for type-checkers.
 *
 * The import exists purely so that bundlers include the stylesheet, which is
 * why this module intentionally exports nothing.
 *
 * `ember-tsc` can only emit declarations for `.ts`/`.gts` sources, so this file
 * is copied into `declarations/` by the `copy-declaration-assets` plugin in
 * `rollup.config.mjs`. Without it, `declarations/components/ember-remodal.d.ts`
 * contains an import that resolves nowhere.
 */
export {};
