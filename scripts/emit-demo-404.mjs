/**
 * GitHub Pages has no server to fall back to a single-page app's router, so a
 * deep link (e.g. /ember-remodal/options/actions) 404s on first load unless
 * something is served for it. GitHub Pages' own convention is to serve
 * `404.html` for any unmatched path — copying the built `index.html` there
 * means the SPA boots normally and its `history`-mode router then renders the
 * right route client-side.
 */
import { copyFileSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const indexPath = join(root, 'dist-demo', 'index.html');
const notFoundPath = join(root, 'dist-demo', '404.html');

if (!existsSync(indexPath)) {
  console.error(
    `emit-demo-404: ${indexPath} does not exist. Run \`pnpm build:demo\` first.`,
  );
  process.exit(1);
}

copyFileSync(indexPath, notFoundPath);
console.log(`emit-demo-404: wrote ${notFoundPath}`);
