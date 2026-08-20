/**
 * Refuses to publish from a dirty working tree.
 *
 * `npm publish` packs whatever is on disk, not whatever is committed. Every
 * check this repo runs — the test suite, `lint:publish`, the publish gate —
 * also reads what is on disk, so an uncommitted edit is green everywhere right
 * up to the moment it ships as a release nobody can reproduce from the tag.
 * (This is not hypothetical: during a review of this branch a stylesheet
 * mutation sat on disk for several minutes; a publish in that window would have
 * shipped it, in both `src/` and `dist/`, with every check passing.)
 *
 * Wired as `prepublishOnly`, which npm runs on `publish` but not on `pack`, so
 * the publish gate can still pack a working tree while it is being iterated on.
 *
 * Untracked files count: `package.json#files` publishes `src/` and `dist/`
 * wholesale, so a file that was never added to git ships just as readily as a
 * modified one. `git status --porcelain` already respects `.gitignore`, so
 * anything genuinely local is invisible here.
 */
import { execFileSync } from 'node:child_process';

const status = execFileSync('git', ['status', '--porcelain'], {
  encoding: 'utf8',
}).trim();

if (status) {
  console.error(
    '\nprepublishOnly: refusing to publish from a dirty working tree.\n\n' +
      'npm packs what is on disk, so everything below would ship in this\n' +
      'release without existing in the repository:\n',
  );
  for (const line of status.split('\n')) console.error(`  ${line}`);
  console.error(
    '\nCommit it, stash it, or add it to .gitignore, then publish again.\n',
  );
  process.exit(1);
}

console.log('prepublishOnly: working tree is clean.');
