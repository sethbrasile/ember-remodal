import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click } from '@ember/test-helpers';
import { hash } from '@ember/helper';
import EmberRemodal from '#src/components/ember-remodal.gts';
import type { CloseReason } from '#src/components/ember-remodal.gts';

module('Rendering | ember-remodal', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders inline content from @title and @text', async function (assert) {
    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @title="Hello Title"
          @text="Hello Text"
        />
      </template>,
    );

    assert.dom('[data-test-id="title"]').hasText('Hello Title');
    assert.dom('[data-test-id="title"]').hasTagName('h2');
    assert.dom('[data-test-id="text"]').hasText('Hello Text');
    assert.dom('[data-test-id="text"]').hasTagName('p');
  });

  test('it omits title and text elements when not provided', async function (assert) {
    await render(<template><EmberRemodal @openButton="Open" /></template>);

    assert.dom('[data-test-id="title"]').doesNotExist();
    assert.dom('[data-test-id="text"]').doesNotExist();
  });

  test('block content is rendered inside the yielded content wrapper', async function (assert) {
    await render(
      <template>
        <EmberRemodal>
          <p data-test-block-content>Custom block content</p>
        </EmberRemodal>
      </template>,
    );

    assert
      .dom('[data-test-id="yielded"] [data-test-block-content]')
      .hasText('Custom block content');
  });

  test('no yielded content wrapper is rendered without a block', async function (assert) {
    await render(<template><EmberRemodal @title="Inline only" /></template>);

    assert.dom('[data-test-id="yielded"]').doesNotExist();
  });

  test('@dataTestId lands on the outer span', async function (assert) {
    await render(<template><EmberRemodal @dataTestId="my-modal" /></template>);

    assert.dom('span.remodal-component[data-test-id="my-modal"]').exists();
  });

  test('the modal card carries the remodal-compatible classes', async function (assert) {
    await render(
      <template>
        <EmberRemodal
          @name="my-name"
          @modifier="with-red-theme"
          @modalClasses="extra-class"
        />
      </template>,
    );

    assert
      .dom('[data-test-id="modalWindow"]')
      .hasClass('remodal')
      .hasClass('remodal-is-initialized')
      .hasClass('ember-remodal')
      .hasClass('my-name')
      .hasClass('with-red-theme')
      .hasClass('window')
      .hasClass('extra-class')
      .hasClass('remodal-is-closed');
    assert
      .dom('[data-test-id="modalWrapper"]')
      .hasClass('remodal-wrapper')
      .hasClass('with-red-theme');
  });

  test('options can be provided via the @options object', async function (assert) {
    await render(
      <template>
        <EmberRemodal
          @options={{hash title="From options" openButton="Open me"}}
        />
      </template>,
    );

    assert.dom('[data-test-id="title"]').hasText('From options');
    assert.dom('[data-test-id="openButton"]').hasText('Open me');
  });

  test('@options takes precedence over direct args (matches 2.x setProperties behavior)', async function (assert) {
    await render(
      <template>
        <EmberRemodal @title="Direct" @options={{hash title="From options"}} />
      </template>,
    );

    assert.dom('[data-test-id="title"]').hasText('From options');
  });

  test('callbacks can be provided via the @options object', async function (assert) {
    // 2.x applied `setProperties(options)`, so every key handed to @options
    // landed on the component — callbacks included. Reading the callbacks only
    // from `this.args` made `@options={{hash onConfirm=…}}` silent dead code.
    const events: string[] = [];
    const handleOpen = () => events.push('open');
    const handleConfirm = () => events.push('confirm');
    const handleClose = (reason?: CloseReason) =>
      events.push(`close:${String(reason)}`);

    await render(
      <template>
        <EmberRemodal
          @options={{hash
            openButton="Open"
            confirmButton="Yes"
            onOpen=handleOpen
            onConfirm=handleConfirm
            onClose=handleClose
          }}
        />
      </template>,
    );

    await click('[data-test-id="openButton"]');
    await click('[data-test-id="confirmButton"]');

    assert.deepEqual(events, ['open', 'confirm', 'close:confirmation']);
  });

  test('a callback in @options takes precedence over the direct argument', async function (assert) {
    const events: string[] = [];
    const direct = () => events.push('direct');
    const fromOptions = () => events.push('from-options');

    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @onOpen={{direct}}
          @options={{hash onOpen=fromOptions}}
        />
      </template>,
    );

    await click('[data-test-id="openButton"]');

    assert.deepEqual(events, ['from-options']);
  });

  test('@onBeforeOpen can veto from the @options object', async function (assert) {
    const veto = () => false;

    await render(
      <template>
        <EmberRemodal @openButton="Open" @options={{hash onBeforeOpen=veto}} />
      </template>,
    );

    await click('[data-test-id="openButton"]');

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-closed');
  });

  test('the native close button renders by default', async function (assert) {
    await render(<template><EmberRemodal @title="Closable" /></template>);

    assert
      .dom('[data-test-id="nativeClose"]')
      .exists()
      .hasClass('remodal-close')
      .hasAttribute('title', 'Close Modal');
  });

  test('@disableNativeClose hides the native close button', async function (assert) {
    await render(
      <template>
        <EmberRemodal @title="No close" @disableNativeClose={{true}} />
      </template>,
    );

    assert.dom('[data-test-id="nativeClose"]').doesNotExist();
  });

  test('@disableForeground hides the native close button by default and adds the invisible class', async function (assert) {
    await render(
      <template>
        <EmberRemodal @title="Ghost" @disableForeground={{true}} />
      </template>,
    );

    assert.dom('[data-test-id="nativeClose"]').doesNotExist();
    assert.dom('[data-test-id="modalWindow"]').hasClass('invisible');
  });

  test('confirm and cancel buttons carry theme and custom classes', async function (assert) {
    await render(
      <template>
        <EmberRemodal
          @confirmButton="Yes"
          @cancelButton="No"
          @buttonClasses="both-buttons"
          @innerButtonClasses="inner-buttons"
          @confirmButtonClasses="confirm-only"
          @cancelButtonClasses="cancel-only"
        />
      </template>,
    );

    assert
      .dom('[data-test-id="confirmButton"]')
      .hasText('Yes')
      .hasClass('remodal-confirm')
      .hasClass('both-buttons')
      .hasClass('inner-buttons')
      .hasClass('confirm-only');
    assert
      .dom('[data-test-id="cancelButton"]')
      .hasText('No')
      .hasClass('remodal-cancel')
      .hasClass('both-buttons')
      .hasClass('inner-buttons')
      .hasClass('cancel-only');
  });
});
