import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click, settled } from '@ember/test-helpers';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { tracked } from '@glimmer/tracking';
import EmberRemodal from '#src/components/ember-remodal.gts';
import type { CloseReason } from '#src/components/ember-remodal.gts';
import { setupRemodal } from '#src/test-support/index.ts';
import { dialog } from '../helpers/remodal-test-helpers.ts';

class Label {
  @tracked value = 'before';
}

module('Rendering | ember-remodal', function (hooks) {
  setupRenderingTest(hooks);
  setupRemodal(hooks);

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
      .hasClass('ember-remodal-window')
      .hasClass('extra-class')
      .hasClass('remodal-is-closed');
    assert
      .dom('[data-test-id="modalWrapper"]')
      .hasClass('remodal-wrapper')
      .hasClass('with-red-theme');
  });

  /**
   * Pattern-3 regression guard. 1.x/2.x emitted a bare single-word class token
   * beside every namespaced one, and every addon rule backing them sits at
   * specificity (0,1,0) — so Bootstrap's `.close`/`.invisible` and
   * Bulma/Foundation's `.button` tie or beat them, with bundle order (which the
   * addon cannot control) deciding the winner. Round 1 namespaced exactly the
   * one token that had been reported (`invisible`); this asserts the whole
   * population is gone rather than one member of it.
   */
  const RETIRED_BARE_CLASSES = [
    'window',
    'close',
    'button',
    'title',
    'text',
    'content',
    'invisible',
    'open',
    'link',
    'native',
    'inner',
    'outer',
    'confirm',
    'cancel',
    'paragraph',
    'yielded',
  ];

  /** Every class token on every element the rendered components emit. */
  function emittedClasses(): string[] {
    const roots = [...document.querySelectorAll('.remodal-component')];
    if (roots.length === 0) {
      throw new Error('the component did not render');
    }
    const tokens = new Set<string>();
    for (const root of roots) {
      for (const element of [root, ...root.querySelectorAll('*')]) {
        for (const token of element.classList) {
          tokens.add(token);
        }
      }
    }
    return [...tokens];
  }

  test('no rendered element carries a bare single-word class token', async function (assert) {
    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @title="Titled"
          @text="Texted"
          @confirmButton="Yes"
          @cancelButton="No"
          @disableAnimation={{true}}
          as |m|
        >
          <m.open><button type="button">Trigger</button></m.open>
          <p>Block content</p>
        </EmberRemodal>
        {{! the two link trigger variants, which render different markup }}
        <EmberRemodal @openLink="Open link" />
        <EmberRemodal @linkButton="Legacy link" />
      </template>,
    );
    await click('[data-test-id="openButton"]');

    const emitted = emittedClasses();
    assert.true(emitted.length > 10, `collected classes: ${emitted.join(' ')}`);

    for (const bare of RETIRED_BARE_CLASSES) {
      assert.false(
        emitted.includes(bare),
        `the bare \`${bare}\` token is not emitted`,
      );
    }

    // And the positive form of the same rule, so a NEW bare token cannot be
    // added without failing here: every token is namespaced. `er-button` is the
    // yielded trigger's own hook and `disable-animation` the animation
    // kill-switch; both are hyphenated compounds, not framework-owned nouns.
    for (const token of emitted) {
      assert.true(
        /^(remodal-|remodal$|ember-remodal|er-button$|disable-animation$)/.test(
          token,
        ),
        `\`${token}\` is namespaced`,
      );
    }
  });

  test('@legacyClassNames brings the 2.x bare tokens back', async function (assert) {
    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @title="Titled"
          @text="Texted"
          @confirmButton="Yes"
          @cancelButton="No"
          @disableForeground={{true}}
          @disableNativeClose={{false}}
          @legacyClassNames={{true}}
          @disableAnimation={{true}}
          as |m|
        >
          <m.open><button type="button">Trigger</button></m.open>
          <p>Block content</p>
        </EmberRemodal>
        <EmberRemodal @openLink="Open link" @legacyClassNames={{true}} />
      </template>,
    );
    await click('[data-test-id="openButton"]');

    const emitted = emittedClasses();
    for (const bare of RETIRED_BARE_CLASSES) {
      assert.true(
        emitted.includes(bare),
        `the opt-in restores \`${bare}\` (${emitted.join(' ')})`,
      );
    }
    // The namespaced hooks stay put alongside them.
    assert.dom('[data-test-id="modalWindow"]').hasClass('ember-remodal-window');
  });

  test('every styling hook documented in the README resolves against the rendered DOM', async function (assert) {
    // One row per line of README's "Styling hooks" table (plus the two
    // footnoted forms). Renaming a hook without updating the table — or the
    // table without the markup — fails here.
    await render(
      <template>
        <EmberRemodal
          @name="my-name"
          @openButton="Open"
          @title="Titled"
          @text="Texted"
          @confirmButton="Yes"
          @cancelButton="No"
          @disableAnimation={{true}}
        >
          <p>Block content</p>
        </EmberRemodal>
        <EmberRemodal @openLink="Open link" />
        <EmberRemodal @linkButton="Legacy link" />
        <EmberRemodal @ariaLabel="Ghost" @disableForeground={{true}} />
      </template>,
    );
    await click('[data-test-id="openButton"]');

    const hooks = [
      '.ember-remodal.ember-remodal-window',
      '.ember-remodal.my-name.ember-remodal-window',
      '.ember-remodal.ember-remodal-open.ember-remodal-button',
      '.ember-remodal.ember-remodal-link.ember-remodal-text',
      '.ember-remodal.ember-remodal-confirm.ember-remodal-button',
      '.ember-remodal.ember-remodal-cancel.ember-remodal-button',
      '.ember-remodal.ember-remodal-native.ember-remodal-close',
      '.ember-remodal.ember-remodal-title.ember-remodal-text',
      '.ember-remodal.ember-remodal-paragraph.ember-remodal-text',
      '.ember-remodal.ember-remodal-yielded.ember-remodal-content',
      '.ember-remodal.ember-remodal-button',
      '.ember-remodal.ember-remodal-inner.ember-remodal-button',
      '.ember-remodal.ember-remodal-outer.ember-remodal-button',
      '.ember-remodal.ember-remodal-outer.ember-remodal-link.ember-remodal-text',
      '.ember-remodal-invisible.remodal',
      // The overlay row: a ::backdrop cannot be selected, so assert its
      // originating element instead.
      'dialog.remodal-wrapper',
    ];

    for (const hook of hooks) {
      assert.dom(hook).exists(`${hook} matches`);
    }
    // The table's note that the outer-button hook does NOT match the link
    // forms, which render as `.ember-remodal-outer.ember-remodal-link`.
    assert
      .dom('[data-test-id="openLink"]')
      .doesNotHaveClass('ember-remodal-button');
    assert
      .dom('[data-test-id="linkButton"]')
      .doesNotHaveClass('ember-remodal-button');
  });

  test('the link trigger variants carry the namespaced hooks', async function (assert) {
    await render(
      <template>
        <EmberRemodal @openLink="Open link" />
        <EmberRemodal @linkButton="Legacy link" />
      </template>,
    );

    for (const id of ['openLink', 'linkButton']) {
      assert
        .dom(`[data-test-id="${id}"]`)
        .hasClass('ember-remodal')
        .hasClass('ember-remodal-outer')
        .hasClass('ember-remodal-link')
        .hasClass('ember-remodal-text');
    }
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
    assert
      .dom('[data-test-id="modalWindow"]')
      .hasClass('ember-remodal-invisible')
      .doesNotHaveClass(
        'invisible',
        'the bare Bootstrap-colliding token is retired',
      );
  });

  test('@disableForeground with @disableNativeClose={{false}} keeps the close button', async function (assert) {
    // @disableNativeClose defaults to @disableForeground rather than to false,
    // so an explicit `false` is the only way to get the frameless card AND the
    // built-in close button — and `?? this.disableForeground` makes that a real
    // branch rather than a formality.
    await render(
      <template>
        <EmberRemodal
          @title="Ghost with an exit"
          @disableForeground={{true}}
          @disableNativeClose={{false}}
        />
      </template>,
    );

    assert.dom('[data-test-id="nativeClose"]').exists();
    assert
      .dom('[data-test-id="modalWindow"]')
      .hasClass('ember-remodal-invisible');
  });

  test('the outer trigger classes land on the button and the link variants', async function (assert) {
    // @outerButtonClasses applies to whichever outer trigger renders;
    // @openButtonClasses and @openLinkClasses are per-variant.
    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @buttonClasses="every-button"
          @outerButtonClasses="outer-only"
          @openButtonClasses="open-button-only"
          @openLinkClasses="open-link-only"
        />
        <EmberRemodal
          @openLink="Open link"
          @outerButtonClasses="outer-only"
          @openLinkClasses="open-link-only"
        />
        <EmberRemodal @linkButton="Legacy" @outerButtonClasses="outer-only" />
      </template>,
    );

    assert
      .dom('[data-test-id="openButton"]')
      .hasClass('every-button')
      .hasClass('outer-only')
      .hasClass('open-button-only')
      .doesNotHaveClass(
        'open-link-only',
        'the link-only class stays off the button',
      );
    assert
      .dom('[data-test-id="openLink"]')
      .hasClass('outer-only')
      .hasClass('open-link-only');
    assert
      .dom('[data-test-id="linkButton"]')
      .hasClass('outer-only')
      .doesNotHaveClass(
        'open-link-only',
        '@linkButton is the legacy trigger and takes no openLink classes',
      );
  });

  test('the yielded confirmAction and cancelAction work as plain event handlers', async function (assert) {
    const events: string[] = [];
    const handleConfirm = () => events.push('confirm');
    const handleCancel = () => events.push('cancel');

    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @title="Actions"
          @onConfirm={{handleConfirm}}
          @onCancel={{handleCancel}}
          @closeOnConfirm={{false}}
          @closeOnCancel={{false}}
          as |m|
        >
          <button
            type="button"
            data-test-action-confirm
            {{on "click" m.confirmAction}}
          >Yes</button>
          <button
            type="button"
            data-test-action-cancel
            {{on "click" m.cancelAction}}
          >No</button>
        </EmberRemodal>
      </template>,
    );

    await click('[data-test-id="openButton"]');
    await click('[data-test-action-confirm]');
    await click('[data-test-action-cancel]');

    assert.deepEqual(events, ['confirm', 'cancel']);
    assert
      .dom('[data-test-id="modalWindow"]')
      .hasClass('remodal-is-opened', 'neither action closed the modal');

    await click('[data-test-id="nativeClose"]');
  });

  test('content inside an open modal tracks a mutated @tracked value', async function (assert) {
    // The most common real usage there was no coverage for at all: the modal
    // stays open while the app it is showing changes underneath it.
    const label = new Label();

    await render(
      <template>
        <EmberRemodal @openButton="Open" @title={{label.value}}>
          <p data-test-live>{{label.value}}</p>
        </EmberRemodal>
      </template>,
    );

    await click('[data-test-id="openButton"]');
    assert.dom('[data-test-live]').hasText('before');
    assert.dom('[data-test-id="title"]').hasText('before');

    label.value = 'after';
    await settled();

    assert.dom('[data-test-live]').hasText('after', 'block content updated');
    assert
      .dom('[data-test-id="title"]')
      .hasText('after', 'and so did an inline option read through opt()');
    assert.true(dialog().open, 'the modal stayed open across the update');

    await click('[data-test-id="nativeClose"]');
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
