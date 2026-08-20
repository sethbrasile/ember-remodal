import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click } from '@ember/test-helpers';
import EmberRemodal from '#src/components/ember-remodal.gts';
import { setupRemodal } from '#src/test-support/index.ts';
import {
  dialog,
  dialogs,
  lookupService,
} from '../helpers/remodal-test-helpers.ts';

/**
 * Stacked modals are a 3.0 feature (the top layer makes them work naturally),
 * and the shared scroll lock is the one piece of state that spans them: it is
 * reference-counted across every open modal, so the document must stay locked
 * until the LAST one closes. Nothing could test this before, because the old
 * `dialog()` helper was a single `find()` that silently returned the first of
 * two matches.
 */
module('Rendering | ember-remodal | stacked modals', function (hooks) {
  setupRenderingTest(hooks);
  setupRemodal(hooks);

  test('two open modals share one lock, released only by the last close', async function (assert) {
    const service = lookupService(this);

    await render(
      <template>
        <EmberRemodal
          data-test-outer
          @forService={{true}}
          @name="outer"
          @title="Outer"
        />
        <EmberRemodal
          data-test-inner
          @forService={{true}}
          @name="inner"
          @title="Inner"
        />
      </template>,
    );

    assert.strictEqual(dialogs().length, 2, 'both modals are rendered');
    assert.throws(
      () => dialog(),
      /2 modal <dialog> elements are rendered/,
      'an unscoped lookup refuses to guess which modal a test meant',
    );

    const outer = dialog('[data-test-outer]');
    const inner = dialog('[data-test-inner]');
    assert.notStrictEqual(outer, inner, 'the scopes select different dialogs');

    await service.open('outer');
    assert
      .dom(document.documentElement)
      .hasClass('remodal-is-locked', 'locked by the first open');

    await service.open('inner');
    assert.true(outer.open, 'the outer modal stays open underneath');
    assert.true(inner.open, 'and the inner one opened on top of it');
    assert
      .dom(document.documentElement)
      .hasClass('remodal-is-locked', 'still locked with two modals open');

    await service.close('inner');
    assert.false(inner.open, 'the inner modal closed');
    assert.true(outer.open, 'the outer modal is untouched');
    assert
      .dom(document.documentElement)
      .hasClass(
        'remodal-is-locked',
        'the lock survives closing the inner modal — the outer one still holds it',
      );

    await service.close('outer');
    assert
      .dom(document.documentElement)
      .doesNotHaveClass(
        'remodal-is-locked',
        'the last close releases the lock',
      );
    assert.strictEqual(
      document.body.style.paddingRight,
      '',
      'and restores the body padding exactly once',
    );
  });

  test('a modal opened from inside another modal stacks on top of it', async function (assert) {
    // The inner modal's trigger lives in the outer modal's yielded content, so
    // it is a DOM descendant of the outer <dialog>; the inner modal is only
    // reachable and interactive because it renders into the top layer above it.
    const service = lookupService(this);

    await render(
      <template>
        <EmberRemodal
          data-test-outer
          @forService={{true}}
          @name="host"
          @title="Outer"
        >
          <EmberRemodal
            data-test-inner
            @openButton="Open inner"
            @title="Inner"
          />
        </EmberRemodal>
      </template>,
    );

    await service.open('host');
    const outer = dialog('[data-test-outer] > [data-test-id="modalWrapper"]');
    const inner = dialog('[data-test-inner]');
    assert.true(
      outer.contains(inner),
      'the inner modal is nested in the outer',
    );

    await click('[data-test-inner] [data-test-id="openButton"]');

    assert.true(outer.open, 'the outer modal is still open');
    assert.true(inner.open, 'and the inner one opened on top of it');
    assert
      .dom(document.documentElement)
      .hasClass('remodal-is-locked', 'locked once for the pair');

    await click('[data-test-inner] [data-test-id="nativeClose"]');
    assert.false(inner.open, 'the inner modal closed');
    assert
      .dom(document.documentElement)
      .hasClass('remodal-is-locked', 'the outer modal still holds the lock');

    await service.close('host');
    assert
      .dom(document.documentElement)
      .doesNotHaveClass('remodal-is-locked', 'released by the last close');
  });
});
