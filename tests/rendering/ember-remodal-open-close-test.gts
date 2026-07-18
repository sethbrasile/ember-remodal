import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click, find, settled } from '@ember/test-helpers';
import { on } from '@ember/modifier';
import EmberRemodal from '#src/components/ember-remodal.gts';

function dialog(): HTMLDialogElement {
  return find('[data-test-id="modalWrapper"]') as HTMLDialogElement;
}

function pressEscape(): Promise<void> {
  // The native `cancel` event is what the browser fires on Esc inside an open
  // <dialog>; synthetic keyboard events do not trigger it, so dispatch it
  // directly.
  dialog().dispatchEvent(new Event('cancel', { cancelable: true }));
  return settled();
}

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

    const openButton = find('[data-test-open]');
    assert.ok(openButton, 'the m.open button is rendered');
    assert.notOk(
      dialog().contains(openButton),
      'the m.open button is not inside the <dialog>',
    );
    assert.ok(
      find('.ember-remodal-open-button-target [data-test-open]'),
      'the m.open button is portaled into the target span',
    );

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

    const html = document.documentElement;
    assert.false(html.classList.contains('remodal-is-locked'));

    await click('[data-test-id="openButton"]');
    assert.true(
      html.classList.contains('remodal-is-locked'),
      'html is locked while open',
    );

    await click('[data-test-id="nativeClose"]');
    assert.false(
      html.classList.contains('remodal-is-locked'),
      'lock is released after closing',
    );
  });
});
