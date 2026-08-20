/**
 * Makes `node_modules/ember-remodal` resolve to this package, so the test suite
 * can import the addon the way a consumer does — by package name, through
 * `package.json#exports`, landing in `dist/`.
 *
 * Why a script instead of a `devDependencies` self-link: this repo is a
 * single-package v2 addon whose test app lives in the same package. Declaring
 * `"ember-remodal": "link:."` would give the app a dependency whose realpath IS
 * the app's own root, and Embroider keys packages by realpath — the app would
 * appear as its own addon. A symlink that is not a declared dependency keeps
 * Node/Vite resolution working (that is all `import 'ember-remodal'` needs)
 * without putting the app into its own addon graph.
 *
 * pnpm prunes anything it does not know about from `node_modules`, so this runs
 * as part of `pnpm test` rather than once at install time.
 */
import { existsSync } from 'node:fs';
import { lstat, mkdir, readlink, rm, symlink } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const nodeModules = join(root, 'node_modules');
const linkPath = join(nodeModules, 'ember-remodal');
// Relative, so the link keeps working if the checkout is moved. Windows
// junctions are the exception: NTFS requires an absolute target, and Node
// resolves a relative one against process.cwd() rather than the link's parent
// — so there the target is `root`, which is also what readlink() hands back.
const isWindows = process.platform === 'win32';
const target = isWindows ? root : '..';

async function currentLinkTarget() {
  try {
    const stats = await lstat(linkPath);
    return stats.isSymbolicLink() ? await readlink(linkPath) : null;
  } catch {
    return undefined;
  }
}

const existing = await currentLinkTarget();

if (existing === target) {
  console.log('link-self: node_modules/ember-remodal is already linked');
} else {
  if (existing !== undefined) {
    await rm(linkPath, { recursive: true, force: true });
  }
  await mkdir(nodeModules, { recursive: true });
  await symlink(target, linkPath, isWindows ? 'junction' : 'dir');
  console.log('link-self: linked node_modules/ember-remodal -> .');
}

// The exports map points at `dist`, so an unbuilt package would fail to resolve
// at bundle time with a much less obvious error than this one.
if (!existsSync(join(root, 'dist', 'index.js'))) {
  console.error(
    'link-self: dist/index.js is missing. Run `pnpm build` before building the test app.',
  );
  process.exit(1);
}
