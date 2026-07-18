import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import EmberRemodal from '#src/components/ember-remodal.gts';
import { dialog, lookupService } from '../helpers/remodal-test-helpers.ts';

module('Rendering | remodal service', function (hooks) {
  setupRenderingTest(hooks);

  test('a @forService modal registers under its @name and opens via the service', async function (assert) {
    const service = lookupService(this);

    await render(
      <template>
        <EmberRemodal @forService={{true}} @name="svc-modal" @title="Hi" />
      </template>,
    );

    await service.open('svc-modal');

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');
    assert.true(dialog().open);
  });

  test('a @forService modal without a @name registers under the default name', async function (assert) {
    const service = lookupService(this);

    await render(
      <template>
        <EmberRemodal @forService={{true}} @title="Default" />
      </template>,
    );

    await service.open();

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');
  });

  test('service.open applies option overrides, which persist across opens', async function (assert) {
    const service = lookupService(this);

    await render(
      <template>
        <EmberRemodal @forService={{true}} @name="svc" @title="Original" />
      </template>,
    );

    assert.dom('[data-test-id="title"]').hasText('Original');

    await service.open('svc', { title: 'Overridden' });
    assert.dom('[data-test-id="title"]').hasText('Overridden');

    await service.close('svc');
    await service.open('svc');
    assert
      .dom('[data-test-id="title"]')
      .hasText('Overridden', 'override persists on a subsequent open');
  });

  test('service.open merges option overrides across calls instead of replacing them', async function (assert) {
    // Regression test: the 2.x service used setProperties, which merged each
    // override onto the modal; a prior rewrite replaced the whole overrides
    // object per call, silently dropping earlier keys.
    const service = lookupService(this);

    await render(
      <template><EmberRemodal @forService={{true}} @name="merge" /></template>,
    );

    await service.open('merge', { title: 'A title' });
    assert.dom('[data-test-id="title"]').hasText('A title');

    await service.close('merge');
    await service.open('merge', { text: 'B text' });

    assert
      .dom('[data-test-id="title"]')
      .hasText('A title', 'earlier override survives a later one');
    assert.dom('[data-test-id="text"]').hasText('B text');
  });

  test('service.close closes the modal and resolves', async function (assert) {
    const service = lookupService(this);

    await render(
      <template><EmberRemodal @forService={{true}} @name="svc" /></template>,
    );

    await service.open('svc');
    assert.true(dialog().open);

    const modal = await service.close('svc');

    assert.strictEqual(modal.state, 'closed', 'resolves with the modal');
    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-closed');
    assert.false(dialog().open);
  });

  test('opening an unregistered modal name asserts helpfully', async function (assert) {
    const service = lookupService(this);

    await render(
      <template><EmberRemodal @forService={{true}} @name="svc" /></template>,
    );

    assert.throws(
      () => {
        void service.open('not-registered');
      },
      /not-registered.*can not be opened because it is not rendered/,
      'throws the not-registered assertion',
    );
  });

  test('the registry is keyed by the name a modal registered under, not by @name after a service override changes it', async function (assert) {
    // Regression test: registration used the constructor-time name, but a
    // service override to @name could change what `this.name` returns
    // afterward. unregister() must use the same snapshotted name, or a
    // destroyed instance is stranded in the registry under its original name.
    const service = lookupService(this);

    await render(
      <template>
        <EmberRemodal @forService={{true}} @name="snap" @title="Snap" />
      </template>,
    );

    await service.open('snap', { name: 'renamed-via-override' });
    await service.close('snap');

    await render(<template></template>);

    assert.throws(
      () => {
        void service.open('snap');
      },
      /snap.*can not be opened because it is not rendered/,
      'the registry has no stale entry left under the original name',
    );
  });

  module('promise semantics', function () {
    test('open() followed by an immediate close() both resolve (#44)', async function (assert) {
      const service = lookupService(this);

      await render(
        <template><EmberRemodal @forService={{true}} @name="race" /></template>,
      );

      const openPromise = service.open('race');
      const closePromise = service.close('race');

      const [openedModal, closedModal] = await Promise.all([
        openPromise,
        closePromise,
      ]);

      assert.strictEqual(
        openedModal,
        closedModal,
        'both resolve with the modal',
      );
      assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-closed');
      assert.false(dialog().open, 'the interrupting close wins');
    });

    test('rapid open/close/open settles every promise and ends opened (#16)', async function (assert) {
      const service = lookupService(this);

      await render(
        <template><EmberRemodal @forService={{true}} @name="race" /></template>,
      );

      const first = service.open('race');
      const second = service.close('race');
      const third = service.open('race');

      await Promise.all([first, second, third]);

      assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');
      assert.true(dialog().open, 'the final open wins');
    });

    test('service.open followed by modal.close() in a .then chain works', async function (assert) {
      const service = lookupService(this);

      await render(
        <template>
          <EmberRemodal @forService={{true}} @name="chain" />
        </template>,
      );

      const modal = await service
        .open('chain')
        .then((openedModal) => openedModal.close());

      assert.strictEqual(modal.state, 'closed');
      assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-closed');
      assert.false(dialog().open);
    });

    test('close() on a never-opened modal resolves and warns', async function (assert) {
      const service = lookupService(this);

      await render(
        <template>
          <EmberRemodal @forService={{true}} @name="fresh" />
        </template>,
      );

      const warnings: unknown[] = [];
      const originalWarn = console.warn;
      console.warn = (...args: unknown[]) => {
        warnings.push(args[0]);
      };

      try {
        const modal = await service.close('fresh');
        assert.strictEqual(modal.state, 'closed', 'resolves immediately');
      } finally {
        console.warn = originalWarn;
      }

      assert.strictEqual(warnings.length, 1, 'warned once');
      assert.true(
        String(warnings[0]).includes('has not yet been opened'),
        'warns about closing an unopened modal',
      );
    });
  });
});
