/**
 * Mutation selftest for the deviation-pinning theme suite.
 *
 * The theme suite claims to pin every deliberate deviation from upstream
 * Remodal and every WCAG figure the docs publish. A test that claims that and
 * cannot fail is worse than no test: it is a gate that reports green while the
 * thing it guards is gone. Two of them were exactly that before this script
 * existed — one read `getComputedStyle(card).outlineStyle`, which Chrome's UA
 * `:focus-visible` rule satisfies with zero author CSS, and one measured a
 * detached <div> fed by an injected stylesheet instead of the real selectors.
 *
 * So: for every entry in the deviation registry in CHANGELOG.md, and for every
 * published contrast figure, delete or neutralise the CSS that backs it,
 * rebuild both copies of the stylesheet, re-run the pinning tests, and require
 * them to go RED. A pinning test that stays green under its own mutation is a
 * failure of this script.
 *
 * Three meta-checks run before any mutation, so the corpus cannot rot silently:
 *   1. every registry id in CHANGELOG.md is claimed by at least one case
 *      (deviation twelve cannot be added without a killing mutation);
 *   2. every case names a registry id that exists;
 *   3. every test in the theme module is killed by at least one case, unless it
 *      is listed in UNPINNED_BY_DESIGN with a reason.
 *
 * Each mutation rebuilds, so the whole run is minutes rather than seconds —
 * it is a release-time gate, not a per-commit one. Run it with
 * `pnpm verify:css-deviations`.
 *
 * Usage:
 *   node ./scripts/css-mutation-selftest.mjs            # whole corpus
 *   node ./scripts/css-mutation-selftest.mjs --list     # corpus table only
 *   node ./scripts/css-mutation-selftest.mjs --only <id-substring>
 */

import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const cssPath = join(root, 'src', 'styles', 'ember-remodal.css');
const changelogPath = join(root, 'CHANGELOG.md');

/** The QUnit module whose tests do the pinning. */
const MODULE = 'Rendering | ember-remodal theme';

/**
 * Theme-module tests that pin no CSS and therefore need no killing mutation.
 * Anything added here needs a reason: an empty list is the healthy state.
 */
const UNPINNED_BY_DESIGN = new Map([]);

/**
 * The corpus. Each case neutralises the CSS behind one claim and names the
 * tests that must go red as a result.
 *
 * `edits` are literal find/replace pairs, not regexes, and every one must match
 * exactly `count` times (default 1). A mutation that no longer matches is a
 * hard error rather than a silent no-op — that is what stops the corpus from
 * quietly detaching from the stylesheet.
 *
 * `deviations` are ids from the registry in CHANGELOG.md. A case may back more
 * than one, and a case with an empty list pins a published contract or figure
 * that is not itself a deviation.
 */
const CORPUS = [
  {
    id: 'confirm-cancel/upstream-colours',
    deviations: ['confirm-cancel-contrast'],
    claim:
      'confirm #2e7d32 (5.13:1) and cancel #c62828 (5.62:1) under white labels — WCAG 1.4.3 AA',
    mutation: "restore upstream's #81c784 / #e57373 (2.01:1 / 2.99:1)",
    edits: [
      [
        '--ember-remodal-confirm-background: #2e7d32;',
        '--ember-remodal-confirm-background: #81c784;',
      ],
      [
        '--ember-remodal-cancel-background: #c62828;',
        '--ember-remodal-cancel-background: #e57373;',
      ],
    ],
    kills: [
      'contrast and focus: confirm and cancel labels clear WCAG 1.4.3 AA against their backgrounds',
      'contrast and focus: the contrast figures quoted in the docs are the ones the theme produces',
      'theming hooks: the default colours still apply when the consumer does nothing',
    ],
  },
  {
    id: 'confirm-cancel/upstream-hover-colours',
    deviations: ['confirm-cancel-contrast'],
    claim: 'the hover colours a pointer user reads text against also clear AA',
    mutation: "restore upstream's #66bb6a / #ef5350 hovers (2.37:1 / 3.49:1)",
    edits: [
      [
        '--ember-remodal-confirm-background-hover: #1b5e20;',
        '--ember-remodal-confirm-background-hover: #66bb6a;',
      ],
      [
        '--ember-remodal-cancel-background-hover: #b71c1c;',
        '--ember-remodal-cancel-background-hover: #ef5350;',
      ],
    ],
    kills: ['contrast and focus: hover/focus backgrounds also clear AA'],
  },
  {
    id: 'confirm-cancel/hover-rules-deleted',
    deviations: ['confirm-cancel-contrast'],
    claim: 'the hover colours are actually wired to :hover / :focus',
    mutation:
      'delete the .remodal-confirm:hover and .remodal-cancel:hover rules (the QC-2-07 mutation)',
    edits: [
      [
        '  .remodal-confirm:hover,\n  .remodal-confirm:focus {\n    background: var(--ember-remodal-confirm-background-hover, #1b5e20);\n  }\n\n',
        '',
      ],
      [
        '  .remodal-cancel:hover,\n  .remodal-cancel:focus {\n    background: var(--ember-remodal-cancel-background-hover, #b71c1c);\n  }\n\n',
        '',
      ],
    ],
    kills: ['contrast and focus: hover/focus backgrounds also clear AA'],
  },
  {
    id: 'close-glyph/upstream-colour',
    deviations: ['close-glyph-contrast'],
    claim:
      'the × glyph at #767981 measures 4.35:1 against the card — WCAG 1.4.11',
    mutation: "restore upstream's #95979c (2.92:1)",
    edits: [
      [
        '--ember-remodal-close-color: #767981;',
        '--ember-remodal-close-color: #95979c;',
      ],
    ],
    kills: [
      'contrast and focus: the close glyph clears WCAG 1.4.11 against the card',
      'contrast and focus: the contrast figures quoted in the docs are the ones the theme produces',
    ],
  },
  {
    id: 'focus-rings/outline-none',
    deviations: ['focus-visible-rings'],
    claim:
      'the card and the three buttons draw a :focus-visible ring — WCAG 2.4.7',
    mutation: "restore upstream's `outline: none` on all four",
    edits: [
      [
        '    outline: 2px solid var(--ember-remodal-focus-ring, #2b2e38);\n    outline-offset: 2px;\n    box-shadow: 0 0 0 2px var(--ember-remodal-focus-ring-inverse, #fff);',
        '    outline: none;',
      ],
    ],
    kills: [
      'contrast and focus: every focusable part of the modal gets a visible focus ring',
      'contrast and focus: the card can take a focus ring too',
    ],
  },
  {
    id: 'focus-rings/card-selector-removed',
    deviations: ['focus-visible-rings'],
    claim: 'the CARD specifically draws a ring, not just the buttons',
    mutation:
      'drop `.remodal:focus-visible` from the ring selector list (the QC-2-06 mutation)',
    edits: [
      [
        '  .remodal:focus-visible,\n  .remodal-close:focus-visible,',
        '  .remodal-close:focus-visible,',
      ],
    ],
    kills: [
      'contrast and focus: the card can take a focus ring too',
      'contrast and focus: the contrast figures quoted in the docs are the ones the theme produces',
    ],
  },
  {
    id: 'focus-rings/dialog-ring-removed',
    deviations: ['focus-visible-rings'],
    claim:
      'the <dialog> itself draws an inset ring — the @disableForeground path, where showModal() focuses the dialog',
    mutation: 'replace the dialog ring with `outline: none`',
    edits: [
      [
        '  dialog.remodal-wrapper:focus-visible {\n    outline: 3px solid var(--ember-remodal-focus-ring-inverse, #fff);\n    outline-offset: -3px;\n  }',
        '  dialog.remodal-wrapper:focus-visible {\n    outline: none;\n  }',
      ],
    ],
    kills: [
      'contrast and focus: every focusable part of the modal gets a visible focus ring',
    ],
  },
  {
    id: 'focus-rings/low-contrast-tokens',
    deviations: ['focus-visible-rings'],
    claim:
      'the ring pair clears 3:1 against whatever is behind it (ink 13.5:1 on the light card)',
    mutation: 'set both ring tokens to near-white, so neither half is visible',
    edits: [
      [
        '--ember-remodal-focus-ring: #2b2e38;',
        '--ember-remodal-focus-ring: #f6f6f6;',
      ],
      [
        '--ember-remodal-focus-ring-inverse: #fff;',
        '--ember-remodal-focus-ring-inverse: #fafafa;',
      ],
    ],
    kills: [
      'contrast and focus: every focusable part of the modal gets a visible focus ring',
      'contrast and focus: the card can take a focus ring too',
      'contrast and focus: the contrast figures quoted in the docs are the ones the theme produces',
    ],
  },
  {
    id: 'touch-action/reintroduced',
    deviations: ['no-touch-action-lock'],
    claim:
      'the scroll lock leaves touch panning alive inside the modal — WCAG 2.1.1, 1.4.10',
    mutation: "put upstream's `touch-action: none` back on the locked <html>",
    edits: [
      [
        '  html.remodal-is-locked {\n    overflow: hidden;\n  }',
        '  html.remodal-is-locked {\n    overflow: hidden;\n    touch-action: none;\n  }',
      ],
    ],
    kills: [
      'layout: the scroll lock does not disable touch panning inside the modal',
    ],
  },
  {
    id: 'touch-action/overscroll-dropped',
    deviations: ['no-touch-action-lock'],
    claim:
      'scroll chaining out of the dialog is contained rather than disabled',
    mutation: 'delete `overscroll-behavior: contain` from the dialog',
    edits: [['    overscroll-behavior: contain;\n', '']],
    kills: [
      'layout: the scroll lock does not disable touch panning inside the modal',
    ],
  },
  {
    id: 'translate3d/reintroduced',
    deviations: ['no-translate3d'],
    claim:
      'the card is not a containing block for consumer `position: fixed` content',
    mutation:
      "put upstream's `transform: translate3d(0, 0, 0)` back on .remodal",
    edits: [
      [
        '  .remodal {\n    position: relative;\n',
        '  .remodal {\n    position: relative;\n    transform: translate3d(0, 0, 0);\n',
      ],
    ],
    kills: [
      'layout: the card is not a containing block for fixed-position content',
    ],
  },
  {
    id: 'namespaced-invisible/bare-class',
    deviations: ['namespaced-invisible'],
    claim:
      'the frameless card is styled through `ember-remodal-invisible`, not through the bare `invisible` class Bootstrap owns',
    mutation: 'hang the frameless rules off `.invisible` again',
    edits: [
      { find: '.ember-remodal-invisible', replace: '.invisible', count: 5 },
    ],
    kills: [
      '@disableForeground: the frameless card is styled through a namespaced class',
      '@disableForeground: a backdrop click still closes a frameless modal',
    ],
  },
  {
    id: 'dialog-box/content-box',
    deviations: ['dialog-border-box'],
    claim:
      'the <dialog> is border-box, so its 10px padding stays inside the viewport',
    mutation: 'delete `box-sizing: border-box` from the dialog',
    edits: [
      [
        '    box-sizing: border-box;\n    width: 100%;\n    height: 100%;',
        '    width: 100%;\n    height: 100%;',
      ],
    ],
    kills: [
      'layout: the open dialog fits the viewport exactly and centers the card',
      'layout: a card as wide as the viewport is not clipped off-screen',
    ],
  },
  {
    id: 'dialog-box/ua-fit-content',
    deviations: ['dialog-border-box'],
    claim:
      'the explicit width/height override the UA <dialog> `fit-content` sizing',
    mutation: 'delete `width: 100%` / `height: 100%` from the dialog',
    edits: [
      [
        '    width: 100%;\n    height: 100%;\n    max-width: none;\n    max-height: none;\n',
        '    max-width: none;\n    max-height: none;\n',
      ],
    ],
    kills: [
      'layout: the open dialog fits the viewport exactly and centers the card',
    ],
  },
  {
    id: 'bg-blur/deleted',
    deviations: ['bg-blur-hook'],
    claim:
      "upstream's `.remodal-bg` blur, re-expressed as `html.remodal-is-locked .remodal-bg`",
    mutation: 'delete the blur rule',
    edits: [
      [
        '  html.remodal-is-locked .remodal-bg {\n    filter: blur(3px);\n  }\n\n',
        '',
      ],
    ],
    kills: [
      'theming hooks: remodal-bg content is blurred only while a modal is open',
    ],
  },
  {
    id: 'text-size-adjust/deleted',
    deviations: ['webkit-text-size-adjust'],
    claim:
      'the prefixed property is declared, so text inflation is suppressed on the one platform that implements only the prefix',
    mutation: 'delete `-webkit-text-size-adjust`',
    edits: [['    -webkit-text-size-adjust: 100%;\n', '']],
    kills: ['layout: text inflation is suppressed on WebKit as well'],
  },
  {
    id: 'css-layer/unwrapped',
    deviations: ['css-layer'],
    claim:
      'the whole sheet sits in `@layer ember-remodal`, so unlayered consumer CSS beats it regardless of specificity or order',
    mutation:
      'unwrap the layer block — delete the `@layer ember-remodal {` opener and its closing brace, leaving the same rules unlayered',
    edits: [
      ['@layer ember-remodal {\n', ''],
      ['}\n\n/* No rule for', '\n/* No rule for'],
    ],
    kills: [
      'theming hooks: the stylesheet ships inside @layer ember-remodal',
      'theming hooks: an unlayered consumer rule beats the addon at equal specificity, layer-first or not',
      'theming hooks: the same rule inside the addon layer loses, a later layer wins',
      'theming hooks: a layered !important outranks an unlayered one',
      '@disableForeground: a Bootstrap-style .invisible cannot hide the modal',
    ],
  },
  {
    id: 'css-layer/font-family-important',
    deviations: ['css-layer'],
    claim:
      "the close glyph's font-family survives a consumer `!important` at the same specificity, because a layered important outranks an unlayered one",
    mutation: 'drop the `!important` from the close glyph font-family',
    edits: [
      [
        'font-family: Arial, "Helvetica CY", "Nimbus Sans L", sans-serif !important;',
        'font-family: Arial, "Helvetica CY", "Nimbus Sans L", sans-serif;',
      ],
    ],
    kills: ['theming hooks: a layered !important outranks an unlayered one'],
  },
  {
    id: 'css-layer/important-inversion',
    deviations: ['css-layer', 'namespaced-invisible'],
    claim:
      "the accepted cost of the layer is its benefit here: a layered `!important` outranks Bootstrap's unlayered `.invisible { visibility: hidden !important }`",
    mutation: 'drop the `!important` from the frameless `visibility: visible`',
    edits: [['visibility: visible !important;', 'visibility: visible;']],
    kills: [
      '@disableForeground: a Bootstrap-style .invisible cannot hide the modal',
    ],
  },
  {
    id: 'no-layer-fallback/unlayered-escape',
    deviations: ['no-layer-fallback'],
    claim:
      'the cost is accepted wholesale — no rule escapes the layer as a fallback for engines that do not support it, because an escaped rule would silently reinstate the collisions the layer exists to remove',
    mutation: 'add one unlayered addon rule outside the layer block',
    edits: [
      [
        '/* No rule for',
        'dialog.remodal-wrapper {\n  color: inherit;\n}\n\n/* No rule for',
      ],
    ],
    kills: ['theming hooks: the stylesheet ships inside @layer ember-remodal'],
  },
  {
    id: 'no-layer-fallback/zero-specificity-tokens',
    deviations: ['no-layer-fallback'],
    claim:
      'on an engine with no `@layer` support the tokens still lose to a consumer, because they are declared on `:where(html)` — zero specificity — rather than on `html` or `:root`',
    mutation:
      'move the token block to `html:root` (0,1,1), which outweighs a consumer `:root` (0,1,0) once the layer is not doing the work',
    edits: [[':where(html) {', 'html:root {']],
    kills: [
      'theming hooks: a consumer stylesheet overrides the card colours without a specificity fight',
    ],
  },
  {
    id: 'contract/themable-card-colours',
    deviations: [],
    claim:
      'every colour is a custom property, so `@modalClasses` and a consumer stylesheet can retheme the card without a specificity fight',
    mutation: 'hardcode the card background instead of reading the token',
    edits: [
      [
        '    background: var(--ember-remodal-background, #fff);',
        '    background: #fff;',
      ],
    ],
    kills: [
      'theming hooks: a consumer stylesheet overrides the card colours without a specificity fight',
      'theming hooks: @modalClasses can retheme the card even though it ties on specificity',
    ],
  },
  {
    id: 'contract/forced-colors-distinction',
    deviations: [],
    claim:
      'confirm and cancel differ by something other than colour under forced-colors — WCAG 1.4.1',
    mutation: "make cancel's border style match confirm's",
    edits: [
      [
        '    .remodal-cancel {\n      border-style: dashed;\n    }',
        '    .remodal-cancel {\n      border-style: solid;\n    }',
      ],
    ],
    kills: [
      'theming hooks: confirm and cancel stay distinguishable under forced-colors',
    ],
  },
  {
    id: 'contract/reduced-motion-transitions',
    deviations: [],
    claim:
      'prefers-reduced-motion suppresses the colour transitions as well as the animations',
    mutation: 'delete the transition suppression from the reduced-motion block',
    edits: [
      [
        '\n    .remodal-close,\n    .remodal-confirm,\n    .remodal-cancel {\n      transition: none;\n    }\n',
        '',
      ],
    ],
    kills: [
      'theming hooks: reduced motion suppresses the transitions as well as the animations',
    ],
  },
  {
    id: 'contract/animation-namespacing',
    deviations: [],
    claim:
      'every keyframe name starts with `remodal-`, which is half of how the component recognises its own animations — one it cannot recognise is one open()/close() never awaits',
    mutation: 'drop the prefix from the opening keyframes',
    edits: [
      {
        find: 'remodal-opening-keyframes',
        replace: 'opening-keyframes',
        count: 2,
      },
    ],
    kills: [
      'animation contract: every keyframe animation is namespaced and targets only the dialog or the card',
    ],
  },
  {
    id: 'contract/frameless-pointer-events',
    deviations: [],
    claim:
      'clicks over the empty frameless card fall through to the dialog, so closeOnOutsideClick still works',
    mutation: 'delete `pointer-events: none` from the frameless card',
    edits: [['    pointer-events: none;\n', '']],
    kills: [
      '@disableForeground: a backdrop click still closes a frameless modal',
      '@disableForeground: the frameless card is styled through a namespaced class',
    ],
  },
];

// ---------------------------------------------------------------------------

function fail(message) {
  console.error(`\n✗ ${message}\n`);
  process.exitCode = 1;
}

/**
 * The deviation registry in CHANGELOG.md, between its two HTML markers. The
 * registry is the contract this script enforces: every id in it must be backed
 * by a mutation that kills a test.
 */
function readRegistry() {
  const changelog = readFileSync(changelogPath, 'utf8');
  const block = changelog.match(
    /<!-- deviation-registry:start -->([\s\S]*?)<!-- deviation-registry:end -->/,
  );
  if (!block) {
    throw new Error(
      'CHANGELOG.md has no <!-- deviation-registry:start --> block',
    );
  }
  const ids = [...block[1].matchAll(/^\d+\.\s+`([a-z0-9-]+)`/gm)].map(
    (match) => match[1],
  );
  if (ids.length === 0) {
    throw new Error('the deviation registry in CHANGELOG.md parsed as empty');
  }
  return ids;
}

function applyEdits(css, edits) {
  let mutated = css;
  for (const edit of edits) {
    const { find, replace, count } = Array.isArray(edit)
      ? { find: edit[0], replace: edit[1], count: 1 }
      : edit;
    const found = mutated.split(find).length - 1;
    if (found !== count) {
      throw new Error(
        `mutation is stale: expected ${count} occurrence(s) of ${JSON.stringify(
          find.length > 70 ? `${find.slice(0, 70)}…` : find,
        )}, found ${found}`,
      );
    }
    mutated = mutated.split(find).join(replace);
  }
  if (mutated === css) {
    throw new Error('mutation changed nothing');
  }
  return mutated;
}

function run(command, args, label) {
  const result = spawnSync(command, args, { cwd: root, encoding: 'utf8' });
  if (result.error) {
    throw result.error;
  }
  if (label && result.status !== 0) {
    throw new Error(
      `${label} failed (exit ${result.status})\n${result.stdout}\n${result.stderr}`,
    );
  }
  return result;
}

function build() {
  run(
    'pnpm',
    ['exec', 'rollup', '--config', '--environment', 'SKIP_DECLARATIONS:true'],
    'rollup build',
  );
  run('node', ['./scripts/link-self.mjs'], 'link-self');
  run(
    'pnpm',
    ['exec', 'vite', 'build', '--mode=development', '--out-dir', 'dist-tests'],
    'vite build',
  );
}

/**
 * Runs the theme module and returns { passed, failed } keyed by the test name
 * with the module prefix stripped; failed values carry the first assertion
 * message, which is the evidence the corpus table reports.
 */
function runThemeModule() {
  const testPage = `tests/index.html?hidepassed&filter=${encodeURIComponent(MODULE)}`;
  const result = run('pnpm', [
    'exec',
    'testem',
    '--file',
    'testem.cjs',
    'ci',
    '--port',
    '0',
    '--test_page',
    testPage,
  ]);
  const lines = `${result.stdout}\n${result.stderr}`.split('\n');
  // A failing run has `not ok` lines; a broken run (testem or the browser
  // never started) has no TAP at all. Without this, the latter reads as
  // "every test killed" inside the mutation loop.
  if (!lines.some((line) => /^(not )?ok \d+ /.test(line))) {
    throw new Error(
      `testem produced no TAP output (exit ${result.status})\n${result.stdout}\n${result.stderr}`,
    );
  }
  const passed = new Set();
  const failed = new Map();
  const prefix = `${MODULE} > `;

  const nameOf = (rest) => {
    const name = rest.replace(/^\S+\s+\S+\s+-\s+(\[\d+ ms\]\s+-\s+)?/, '');
    return name.startsWith(prefix) ? name.slice(prefix.length) : name;
  };

  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    const ok = line.match(/^ok \d+ (.*)$/);
    if (ok) {
      passed.add(nameOf(ok[1]));
      continue;
    }
    const notOk = line.match(/^not ok \d+ (.*)$/);
    if (!notOk) {
      continue;
    }
    let message = '';
    for (let cursor = index + 1; cursor < lines.length; cursor += 1) {
      if (/^\s{0,4}\.\.\.\s*$/.test(lines[cursor])) {
        break;
      }
      if (/^\s+message: >/.test(lines[cursor])) {
        const collected = [];
        for (
          let inner = cursor + 1;
          inner < lines.length && /^\s{12}\S/.test(lines[inner]);
          inner += 1
        ) {
          collected.push(lines[inner].trim());
        }
        message = collected.join(' ');
        break;
      }
    }
    failed.set(nameOf(notOk[1]), message || '(no assertion message)');
  }
  return { passed, failed, tap: result.stdout };
}

// ---------------------------------------------------------------------------

const args = process.argv.slice(2);
const only = args.includes('--only') ? args[args.indexOf('--only') + 1] : null;
const listOnly = args.includes('--list');

const registry = readRegistry();
const claimed = new Set(CORPUS.flatMap((entry) => entry.deviations));

let metaFailed = false;
for (const id of registry) {
  if (!claimed.has(id)) {
    fail(
      `deviation \`${id}\` is in the CHANGELOG registry but no corpus entry mutates it. ` +
        'Every deviation needs a mutation that kills its pinning test.',
    );
    metaFailed = true;
  }
}
for (const id of claimed) {
  if (!registry.includes(id)) {
    fail(`corpus references \`${id}\`, which is not in the CHANGELOG registry`);
    metaFailed = true;
  }
}
if (metaFailed) {
  process.exit(1);
}
console.log(
  `meta: ${registry.length} registered deviations, all claimed by ${CORPUS.length} corpus entries`,
);

if (listOnly) {
  for (const entry of CORPUS) {
    console.log(
      `\n${entry.id}\n  deviations: ${entry.deviations.join(', ') || '(published contract)'}\n  claim: ${entry.claim}\n  mutation: ${entry.mutation}\n  kills: ${entry.kills.join('; ')}`,
    );
  }
  process.exit(0);
}

const original = readFileSync(cssPath, 'utf8');

// Every edit is checked against the current stylesheet before anything is
// built, so a mutation that has drifted away from the CSS reports as corpus rot
// in a second rather than after ten minutes of rebuilds.
for (const entry of CORPUS) {
  try {
    applyEdits(original, entry.edits);
  } catch (error) {
    fail(`${entry.id}: ${error.message}`);
    metaFailed = true;
  }
}
if (metaFailed) {
  process.exit(1);
}
console.log(`meta: all ${CORPUS.length} mutations still match the stylesheet`);

// dist/ and dist-tests/ are gitignored, so assert-clean-tree cannot see a
// build left over from a mutated stylesheet. The single cleanup path restores
// the source AND rebuilds whenever a mutated build has happened — on success,
// on a thrown build()/runThemeModule(), and on SIGINT/SIGTERM.
let distMutated = false;
const restore = () => writeFileSync(cssPath, original);
function cleanup() {
  restore();
  if (!distMutated) {
    return;
  }
  console.log('\nrestoring the stylesheet and rebuilding…');
  build();
  distMutated = false;
}
process.on('exit', restore);
for (const signal of ['SIGINT', 'SIGTERM']) {
  process.on(signal, () => {
    try {
      cleanup();
    } catch (error) {
      console.error(
        `css-mutation-selftest: ${error.message}\ndist/ may still hold a build of the mutated stylesheet — run \`pnpm build:dist\`.`,
      );
    }
    process.exit(130);
  });
}

console.log('baseline: building and running the theme module unmutated…');
build();
const baseline = runThemeModule();
if (baseline.failed.size > 0) {
  console.error(baseline.tap);
  fail(
    `the theme module is not green before any mutation: ${[...baseline.failed.keys()].join(', ')}`,
  );
  process.exit(1);
}
console.log(`baseline: ${baseline.passed.size} tests green`);

// Meta-check 3: no theme test may be un-killable.
const killed = new Set(CORPUS.flatMap((entry) => entry.kills));
for (const name of baseline.passed) {
  if (!killed.has(name) && !UNPINNED_BY_DESIGN.has(name)) {
    fail(
      `no corpus entry claims to kill "${name}". Add a mutation for it, or list it in ` +
        'UNPINNED_BY_DESIGN with a reason for why it pins no CSS.',
    );
    metaFailed = true;
  }
}
for (const name of killed) {
  if (!baseline.passed.has(name)) {
    fail(`corpus expects to kill "${name}", which is not in the theme module`);
    metaFailed = true;
  }
}
if (metaFailed) {
  process.exit(1);
}
console.log(
  `meta: every one of the ${baseline.passed.size} theme tests is claimed by a mutation`,
);

const cases = only ? CORPUS.filter((entry) => entry.id.includes(only)) : CORPUS;
if (cases.length === 0) {
  fail(`--only ${only} matched no corpus entry`);
  process.exit(1);
}

const rows = [];
let broken = 0;

try {
  for (const [index, entry] of cases.entries()) {
    console.log(`\n[${index + 1}/${cases.length}] ${entry.id}`);
    console.log(`  mutation: ${entry.mutation}`);
    writeFileSync(cssPath, applyEdits(original, entry.edits));
    distMutated = true;
    build();
    const { failed } = runThemeModule();
    const survivors = entry.kills.filter((name) => !failed.has(name));
    const collateral = [...failed.keys()].filter(
      (name) => !entry.kills.includes(name),
    );
    for (const name of entry.kills) {
      rows.push({
        entry,
        test: name,
        killed: failed.has(name),
        message: failed.get(name) ?? '(SURVIVED — the test stayed green)',
      });
    }
    if (survivors.length > 0) {
      broken += 1;
      fail(
        `vacuous gate: ${survivors.map((name) => `"${name}"`).join(', ')} stayed green under ${entry.id}`,
      );
    } else {
      console.log(`  killed ${entry.kills.length} test(s) ✓`);
    }
    for (const name of collateral) {
      console.log(`  also failed (not claimed): ${name} — ${failed.get(name)}`);
    }
    restore();
  }
} finally {
  cleanup();
}

console.log('\n## Mutation corpus\n');
console.log('| deviation | pinning test | mutation | observed failure |');
console.log('| --- | --- | --- | --- |');
for (const row of rows) {
  const cell = (value) => String(value).replace(/\|/g, '\\|');
  console.log(
    `| ${cell(row.entry.deviations.join(', ') || '(contract)')} — ${cell(row.entry.id)} | ${cell(row.test)} | ${cell(row.entry.mutation)} | ${row.killed ? cell(row.message) : '**SURVIVED**'} |`,
  );
}

if (broken > 0) {
  fail(`${broken} of ${cases.length} mutations failed to kill their gate`);
  process.exit(1);
}
console.log(
  `\n✓ ${cases.length} mutations, ${rows.length} pinning assertions, every one red under its mutation`,
);
