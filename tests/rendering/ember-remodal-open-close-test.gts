import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click, find } from '@ember/test-helpers';
import { on } from '@ember/modifier';
import Component from '@glimmer/component';
import type Owner from '@ember/owner';
import EmberRemodal from '#src/components/ember-remodal.gts';
import {
  dialog,
  lookupService,
  pressEscape,
} from '../helpers/remodal-test-helpers.ts';

module('Rendering | ember-remodal | open and close', function (hooks) {
  setupRenderingTest(hooks);

  test('clicking @openButton opens the modal', async function (assert) {
    await render(
      <template><EmberRemodal @openButton="Open" @title="Hi" /></template>,
    );

    assert.dom('[data-test-id="openButton"]').hasTagName('button');
    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-closed');
    assert.false(dialog().open, 'dialog starts closed');

    await click('[data-test-id="openButton"]');

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');
    assert.true(dialog().open, 'dialog is open');
  });

  test('clicking @openLink opens the modal', async function (assert) {
    await render(
      <template><EmberRemodal @openLink="Open link" @title="Hi" /></template>,
    );

    assert.dom('[data-test-id="openLink"]').hasTagName('a');

    await click('[data-test-id="openLink"]');

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');
    assert.true(dialog().open);
  });

  test('clicking @linkButton opens the modal', async function (assert) {
    await render(
      <template>
        <EmberRemodal @linkButton="Legacy link" @title="Hi" />
      </template>,
    );

    assert.dom('[data-test-id="linkButton"]').hasTagName('a');

    await click('[data-test-id="linkButton"]');

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');
    assert.true(dialog().open);
  });

  test('the yielded m.open button is portaled outside the dialog and opens the modal', async function (assert) {
    await render(
      <template>
        <EmberRemodal @title="Hi" as |m|>
          <m.open data-test-open>
            <button type="button">Open me</button>
          </m.open>
        </EmberRemodal>
      </template>,
    );

    assert.dom('[data-test-open]').exists('the m.open button is rendered');
    assert.notOk(
      dialog().contains(find('[data-test-open]')),
      'the m.open button is not inside the <dialog>',
    );
    assert
      .dom('.ember-remodal-open-button-target [data-test-open]')
      .exists('the m.open button is portaled into the target span');

    await click('[data-test-open]');

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');
    assert.true(dialog().open);
  });

  test('the native close button closes the modal', async function (assert) {
    await render(
      <template><EmberRemodal @openButton="Open" @title="Hi" /></template>,
    );
    await click('[data-test-id="openButton"]');
    assert.true(dialog().open);

    await click('[data-test-id="nativeClose"]');

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-closed');
    assert.false(dialog().open, 'dialog is closed');
  });

  test('pressing Escape closes the modal', async function (assert) {
    await render(
      <template><EmberRemodal @openButton="Open" @title="Hi" /></template>,
    );
    await click('[data-test-id="openButton"]');

    await pressEscape();

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-closed');
    assert.false(dialog().open);
  });

  test('@closeOnEscape={{false}} keeps the modal open on Escape', async function (assert) {
    await render(
      <template>
        <EmberRemodal @openButton="Open" @closeOnEscape={{false}} />
      </template>,
    );
    await click('[data-test-id="openButton"]');

    await pressEscape();

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');
    assert.true(dialog().open);
  });

  test('clicking outside the modal card closes the modal', async function (assert) {
    await render(
      <template><EmberRemodal @openButton="Open" @title="Hi" /></template>,
    );
    await click('[data-test-id="openButton"]');

    // Clicks on the <dialog> element itself land on the backdrop padding,
    // outside the .remodal card.
    await click('[data-test-id="modalWrapper"]');

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-closed');
    assert.false(dialog().open);
  });

  test('@closeOnOutsideClick={{false}} keeps the modal open', async function (assert) {
    await render(
      <template>
        <EmberRemodal @openButton="Open" @closeOnOutsideClick={{false}} />
      </template>,
    );
    await click('[data-test-id="openButton"]');

    await click('[data-test-id="modalWrapper"]');

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');
    assert.true(dialog().open);
  });

  test('clicking inside the modal card does not close the modal', async function (assert) {
    await render(
      <template><EmberRemodal @openButton="Open" @title="Hi" /></template>,
    );
    await click('[data-test-id="openButton"]');

    await click('[data-test-id="modalWindow"]');

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');
    assert.true(dialog().open);
  });

  test('@onOpen and @onClose fire; a plain close passes no reason', async function (assert) {
    const events: unknown[] = [];
    const handleOpen = () => events.push('open');
    const handleClose = (reason?: string) => events.push(['close', reason]);

    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @onOpen={{handleOpen}}
          @onClose={{handleClose}}
        />
      </template>,
    );

    await click('[data-test-id="openButton"]');
    await click('[data-test-id="nativeClose"]');

    assert.deepEqual(events, ['open', ['close', undefined]]);
  });

  test('@onBeforeOpen returning false prevents opening', async function (assert) {
    let opened = false;
    const veto = () => false;
    const handleOpen = () => (opened = true);

    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @onBeforeOpen={{veto}}
          @onOpen={{handleOpen}}
        />
      </template>,
    );

    await click('[data-test-id="openButton"]');

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-closed');
    assert.false(dialog().open, 'dialog never opened');
    assert.false(opened, '@onOpen never fired');
  });

  test('@onBeforeOpen returning anything else allows opening', async function (assert) {
    const beforeOpen = () => undefined;

    await render(
      <template>
        <EmberRemodal @openButton="Open" @onBeforeOpen={{beforeOpen}} />
      </template>,
    );

    await click('[data-test-id="openButton"]');

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');
  });

  test('m.isOpen only renders lazy content while the modal is open', async function (assert) {
    await render(
      <template>
        <EmberRemodal @openButton="Open" as |m|>
          {{#if m.isOpen}}
            <div data-test-lazy>Expensive content</div>
          {{/if}}
        </EmberRemodal>
      </template>,
    );

    assert.dom('[data-test-lazy]').doesNotExist('absent while closed');

    await click('[data-test-id="openButton"]');
    assert.dom('[data-test-lazy]').exists('present while open');

    await click('[data-test-id="nativeClose"]');
    assert.dom('[data-test-lazy]').doesNotExist('absent again after closing');
  });

  test('the yielded openAction and closeAction work as plain event handlers', async function (assert) {
    await render(
      <template>
        <EmberRemodal @title="Hi" as |m|>
          <m.open>
            <button
              type="button"
              data-test-action-open
              {{on "click" m.openAction}}
            >
              Open
            </button>
          </m.open>
          <button
            type="button"
            data-test-action-close
            {{on "click" m.closeAction}}
          >
            Close
          </button>
        </EmberRemodal>
      </template>,
    );

    await click('[data-test-action-open]');
    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');

    await click('[data-test-action-close]');
    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-closed');
    assert.false(dialog().open);
  });

  test('the document scroll is locked while the modal is open', async function (assert) {
    await render(<template><EmberRemodal @openButton="Open" /></template>);

    assert.dom(document.documentElement).doesNotHaveClass('remodal-is-locked');

    await click('[data-test-id="openButton"]');
    assert
      .dom(document.documentElement)
      .hasClass('remodal-is-locked', 'html is locked while open');

    await click('[data-test-id="nativeClose"]');
    assert
      .dom(document.documentElement)
      .doesNotHaveClass('remodal-is-locked', 'lock is released after closing');
  });

  test('a chained reopen (close().then(open())) survives the queued native close event', async function (assert) {
    // Regression test: `dialog.close()` dispatches its native `close` event
    // from a QUEUED task, not synchronously. A naive close-then-reopen could
    // let that stale event arrive after the reopen had already started,
    // clobbering it (dialog left visibly open, but state forced to 'closed'
    // and the scroll lock released). handleDialogClose must recognize a
    // stale event by checking `dialog.open` rather than trusting timing.
    const service = lookupService(this);

    await render(
      <template>
        <EmberRemodal @forService={{true}} @name="reopen" @title="Reopen" />
      </template>,
    );

    const modal = await service.open('reopen');
    await modal.close().then((m) => m.open());

    // Give the queued native `close` event a chance to land before asserting.
    await new Promise((resolve) => setTimeout(resolve, 50));

    assert.true(dialog().open, 'dialog element is still natively open');
    assert.strictEqual(modal.state, 'opened');
    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');
    assert
      .dom(document.documentElement)
      .hasClass('remodal-is-locked', 'scroll lock still held');
  });

  test('service.open() called during the initial render pass still opens the modal', async function (assert) {
    // Regression test: registering with the service happens in the
    // component's constructor, before its <dialog> element has been
    // captured by the registerDialog modifier. A service.open() call that
    // lands in that window must wait for the element instead of silently
    // no-opping.
    class EarlyOpener extends Component {
      constructor(owner: Owner, args: object) {
        super(owner, args);
        const remodal = owner.lookup('service:remodal');
        void remodal.open('early-modal');
      }

      <template></template>
    }

    await render(
      <template>
        <EmberRemodal @forService={{true}} @name="early-modal" @title="Early" />
        <EarlyOpener />
      </template>,
    );

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');
    assert.true(dialog().open);
  });

  test('isOpen (and thus yielded m.isOpen) stays true through the closing animation', async function (assert) {
    // Regression test: isOpen previously excluded 'closing', so lazily
    // rendered content driven by `{{#if m.isOpen}}` was torn out the instant
    // close() was called, before the closing animation had a chance to play.
    // close() sets state synchronously before its first internal await, so
    // this is observable without racing the render/animation timing.
    const service = lookupService(this);

    await render(
      <template>
        <EmberRemodal @forService={{true}} @name="lazy" @title="Lazy" />
      </template>,
    );

    const modal = await service.open('lazy');
    assert.true(modal.isOpen, 'open while opened');

    const closePromise = modal.close();
    assert.true(
      modal.isOpen,
      'still true synchronously after close() starts (state is "closing")',
    );

    await closePromise;
    assert.false(modal.isOpen, 'false once fully closed');
  });
});
