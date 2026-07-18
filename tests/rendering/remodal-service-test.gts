import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, find } from '@ember/test-helpers';
import type { TestContext } from '@ember/test-helpers';
import EmberRemodal from '#src/components/ember-remodal.gts';
import type RemodalService from '#src/services/remodal.ts';

function dialog(): HTMLDialogElement {
  return find('[data-test-id="modalWrapper"]') as HTMLDialogElement;
}

function lookupService(context: TestContext): RemodalService {
  return context.owner.lookup('service:remodal');
}

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
