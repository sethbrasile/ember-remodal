import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click } from '@ember/test-helpers';
import PublishedDefault, {
  EmberRemodal as PublishedNamed,
  ErButton as PublishedErButton,
  RemodalService as PublishedService,
} from 'ember-remodal';
import PublishedComponent from 'ember-remodal/components/ember-remodal';
import AppTreeComponent from 'ember-remodal/_app_/components/ember-remodal';
import { setupRemodal as publishedSetupRemodal } from 'ember-remodal/test-support';
import SourceComponent from '#src/components/ember-remodal.gts';
import SourceService from '#src/services/remodal.ts';

// Imported by PACKAGE NAME on purpose. Every other test in this suite reaches
// for `#src/*`, which is why nothing here exercised `package.json#exports`, the
// `dist/_app_/*` classic re-exports, or the `keepAssets` CSS emission — the gap
// that let a published-declarations bug survive a fully green local run.
//
// `node_modules/ember-remodal` is a symlink created by scripts/link-self.mjs,
// and `pnpm test` builds `dist/` before it builds the test app, so these
// specifiers resolve exactly the way a consumer's bundler resolves them:
// through `exports`, into `dist/`.

module('Rendering | the published package surface', function (hooks) {
  setupRenderingTest(hooks);
  // Deliberately the PUBLISHED setupRemodal: the built copy of the addon has its
  // own module-level scroll-lock state, distinct from the `#src` copy every
  // other module uses, and only the built copy's own test-support entry point
  // can reset it.
  publishedSetupRemodal(hooks);

  test('the package specifiers resolve to the built copy, not back to src', function (assert) {
    // The decisive check. An `exports` map that had been short-circuited by a
    // bundler alias back to `src` would make these the same module instance, and
    // the whole point of this file would evaporate silently.
    assert.notStrictEqual(
      PublishedComponent,
      SourceComponent,
      'ember-remodal/components/ember-remodal is a different module instance than #src (i.e. it came from dist/)',
    );
    assert.notStrictEqual(
      PublishedService,
      SourceService,
      'and so is the service',
    );
  });

  test('the root entry point re-exports the same modules as its subpaths', function (assert) {
    assert.strictEqual(
      PublishedDefault,
      PublishedComponent,
      'the default export is the component reached through the "./*" subpath',
    );
    assert.strictEqual(
      PublishedNamed,
      PublishedComponent,
      'and so is the named EmberRemodal export',
    );
    assert.ok(PublishedErButton, 'ErButton is exported');
    assert.ok(PublishedService, 'RemodalService is exported');
  });

  test('the dist/_app_ re-export used by classic resolvers points at the real component', function (assert) {
    // `package.json#ember-addon.app-js` maps the app-tree paths to these files,
    // and each one re-exports by package name — so this resolves through
    // `exports` twice.
    assert.strictEqual(
      AppTreeComponent,
      PublishedComponent,
      'the app-tree re-export is the same module the addon exports',
    );
  });

  test('the built component renders and opens like the source one', async function (assert) {
    // Not a duplicate of the rest of the suite: it proves the BUILT artifact is
    // functional — templates compiled, decorators transformed, the CSS side
    // effect resolvable — rather than merely importable.
    await render(
      <template>
        <PublishedComponent @openButton="Open" @title="From the package" />
      </template>,
    );

    assert.dom('[data-test-id="title"]').hasText('From the package');

    await click('[data-test-id="openButton"]');
    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');

    await click('[data-test-id="nativeClose"]');
    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-closed');
  });
});
