// Side-effect CSS imports (e.g. `import '../styles/ember-remodal.css'`).
// The dev tsconfig gets this from vite/client, but the publish tsconfig
// (used for declaration emit) does not include vite's types.
declare module '*.css';
