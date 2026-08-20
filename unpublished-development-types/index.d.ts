// Side-effect CSS imports (e.g. `import '../styles/ember-remodal.css'`).
// The dev tsconfig gets this from vite/client, but the publish tsconfig
// (used for declaration emit) does not include vite's types.
declare module '*.css';

// Injected by vite.config.mjs's `define`, from package.json's version — read
// by the demo's DocsShell to show the version in the top bar. Vite's own
// ImportMetaEnv is an open interface, so this augments rather than replaces it.
interface ImportMetaEnv {
  readonly DEMO_VERSION: string;
}

// `import source from './example.gts?highlight'` — see demo-app/vite/highlight.mjs.
// A wildcard module cannot be imported from by name, so this type is declared
// at top level (global scope) rather than exported from the module below.
interface HighlightedSource {
  html: string;
  text: string;
  lang: string;
}

declare module '*?highlight' {
  const source: HighlightedSource;
  export default source;
}
