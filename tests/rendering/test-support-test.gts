import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click } from '@ember/test-helpers';
import EmberRemodal from '#src/components/ember-remodal.gts';
import {
  remodalDialog,
  remodalDialogs,
  resetRemodalScrollLock,
  setupRemodal,
} from '#src/test-support/index.ts';
import {
  dialog,
  lookupService,
  settlesWithin,
  suspendAnimationFrames,
} from '../helpers/remodal-test-helpers.ts';

/**
 * Covers `ember-remodal/test-support`, the entry point that replaces the
 * (documented, but in a strict-resolver v2 app inert) `config/environment`
 * `disableAnimationWhileTesting` flag.
 *
 * `suspendAnimationFrames()` is what makes "resolves without waiting" a real
 * assertion rather than a timing guess: with requestAnimationFrame stubbed out,
 * a transition that still awaits its frame preamble can never settle at all.
 */
module('Rendering | test-support', function () {
  module('setupRemodal({ disableAnimation: true })', function (hooks) {
    setupRenderingTest(hooks);
    setupRemodal(hooks, { disableAnimation: true });

    test('every modal in the module skips its animations, and open() resolves without waiting for a frame', async function (assert) {
      const service = lookupService(this);

      await render(
        <template>
          <EmberRemodal @forService={{true}} @name="fast" @title="Fast" />
        </template>,
      );

      assert
        .dom('[data-test-id="modalWrapper"]')
        .hasClass('disable-animation', 'the wrapper carries the class');
      assert
        .dom('[data-test-id="modalWindow"]')
        .hasClass('disable-animation', 'and so does the card');

      const restoreFrames = suspendAnimationFrames();
      let opened: 'settled' | 'pending';
      let closed: 'settled' | 'pending';
      try {
        opened = await settlesWithin(service.open('fast'), 1000);
        closed = await settlesWithin(service.close('fast'), 1000);
      } finally {
        restoreFrames();
      }

      assert.strictEqual(opened, 'settled', 'open() never waited for a frame');
      assert.strictEqual(closed, 'settled', 'nor did close()');
      assert.false(dialog().open, 'and the modal really closed');
    });
  });

  module('the animation switch is scoped to its module', function (hooks) {
    setupRenderingTest(hooks);
    setupRemodal(hooks);

    test('a sibling module that did not ask for it still animates', async function (assert) {
      // The flag lives at module scope inside the addon, so `setupRemodal`'s
      // teardown is the only thing between the module above and every test that
      // follows it — including the interrupted-transition tests, which are
      // meaningless without animations to interrupt. `animationState` derives
      // straight from `disableAnimation`, so the class is the flag.
      await render(
        <template><EmberRemodal @openButton="Open" @title="Slow" /></template>,
      );

      assert
        .dom('[data-test-id="modalWrapper"]')
        .doesNotHaveClass(
          'disable-animation',
          'the previous module unwound its own flag',
        );

      await click('[data-test-id="openButton"]');
      assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');

      await click('[data-test-id="nativeClose"]');
      assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-closed');
    });

    test('@disableAnimation on a single modal does not leak to its neighbour', async function (assert) {
      await render(
        <template>
          <EmberRemodal
            data-test-fast
            @title="Fast"
            @disableAnimation={{true}}
          />
          <EmberRemodal data-test-slow @title="Slow" />
        </template>,
      );

      assert.dom(dialog('[data-test-fast]')).hasClass('disable-animation');
      assert
        .dom(dialog('[data-test-slow]'))
        .doesNotHaveClass('disable-animation');
    });
  });

  module('the classic-resolver config/environment fallback', function (hooks) {
    setupRenderingTest(hooks);
    setupRemodal(hooks);

    // `config:environment` only resolves through classic `ember-resolver`, which
    // is why this repo's strict-resolver test app has to register it by hand —
    // and why the flag was documented-but-dead for exactly the v2 apps the
    // README targets. Registering it here keeps the classic path from being an
    // untested branch.
    test('ENV["ember-remodal"].disableAnimationWhileTesting disables animations', async function (assert) {
      this.owner.register(
        'config:environment',
        {
          environment: 'test',
          'ember-remodal': { disableAnimationWhileTesting: true },
        },
        { instantiate: false },
      );
      const service = lookupService(this);

      await render(
        <template>
          <EmberRemodal @forService={{true}} @name="classic" @title="Classic" />
        </template>,
      );

      assert.dom('[data-test-id="modalWrapper"]').hasClass('disable-animation');

      const restoreFrames = suspendAnimationFrames();
      let outcome: 'settled' | 'pending';
      try {
        outcome = await settlesWithin(service.open('classic'), 1000);
      } finally {
        restoreFrames();
      }

      assert.strictEqual(
        outcome,
        'settled',
        'the open resolved without waiting for a frame',
      );
      assert.true(dialog().open);

      await service.close('classic');
    });

    test('the flag is ignored outside the test environment', async function (assert) {
      this.owner.register(
        'config:environment',
        {
          environment: 'development',
          'ember-remodal': { disableAnimationWhileTesting: true },
        },
        { instantiate: false },
      );

      await render(<template><EmberRemodal @title="Dev" /></template>);

      assert
        .dom('[data-test-id="modalWrapper"]')
        .doesNotHaveClass(
          'disable-animation',
          'both halves of the condition are load-bearing',
        );
    });

    test('no config registration at all leaves animations on', async function (assert) {
      // The negative control for the two tests above: without it they would
      // still pass with `disableAnimation` hardcoded to true.
      await render(<template><EmberRemodal @title="Strict" /></template>);

      assert
        .dom('[data-test-id="modalWrapper"]')
        .doesNotHaveClass('disable-animation');
    });
  });

  module('the dialog helpers and the scroll-lock reset', function (hooks) {
    setupRenderingTest(hooks);
    setupRemodal(hooks);

    test('remodalDialog throws helpfully when there is no modal, or more than one', async function (assert) {
      assert.throws(
        () => remodalDialog(),
        /no modal <dialog> is rendered/,
        'nothing rendered yet',
      );

      await render(
        <template>
          <EmberRemodal data-test-a @title="A" />
          <EmberRemodal data-test-b @title="B" />
        </template>,
      );

      assert.strictEqual(remodalDialogs().length, 2, 'both are found');
      assert.throws(
        () => remodalDialog(),
        /Scope the lookup/,
        'the ambiguous case points at the fix instead of guessing',
      );
      assert.throws(
        () => remodalDialog('[data-test-missing]'),
        /no element matched the scope selector/,
        'a scope that matches nothing is an error, not an empty result',
      );

      assert.strictEqual(
        remodalDialogs('[data-test-a]').length,
        1,
        'a scoped lookup narrows to one',
      );
      assert.strictEqual(
        remodalDialog('[data-test-b]'),
        remodalDialogs()[1],
        'and selects the one it named',
      );
    });

    test('resetRemodalScrollLock force-releases a lock that is still held', async function (assert) {
      // The escape hatch for a suite that manages its own hooks, and the half of
      // setupRemodal's teardown that turns a leak into one localized failure.
      await render(
        <template><EmberRemodal @openButton="Open" @title="Held" /></template>,
      );

      await click('[data-test-id="openButton"]');
      assert.dom(document.documentElement).hasClass('remodal-is-locked');

      resetRemodalScrollLock();

      assert
        .dom(document.documentElement)
        .doesNotHaveClass('remodal-is-locked', 'the lock is gone immediately');
      assert.strictEqual(document.body.style.paddingRight, '');

      // The modal is still open and still believes it holds the lock; closing it
      // must neither reintroduce the lock nor throw.
      await click('[data-test-id="nativeClose"]');

      assert
        .dom(document.documentElement)
        .doesNotHaveClass('remodal-is-locked', 'and closing keeps it released');
      assert.strictEqual(document.body.style.paddingRight, '');
    });
  });
});
