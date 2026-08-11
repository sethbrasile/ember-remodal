import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click, find } from '@ember/test-helpers';
import { hash } from '@ember/helper';
import EmberRemodal from '#src/components/ember-remodal.gts';
import cssSource from '../../src/styles/ember-remodal.css?raw';
import {
  authoredAccessibleName,
  captureWarnings,
  dialog,
  lookupService,
  pressEscape,
} from '../helpers/remodal-test-helpers.ts';

function closeButton(): HTMLButtonElement {
  return find('[data-test-id="nativeClose"]') as HTMLButtonElement;
}

module('Rendering | ember-remodal | accessibility', function (hooks) {
  setupRenderingTest(hooks);

  // --- QC-1-03: the <dialog> must have an accessible name ---------------------

  test('the dialog is named by its @title through aria-labelledby', async function (assert) {
    await render(
      <template>
        <EmberRemodal @openButton="Open" @title="Delete this record?" />
      </template>,
    );

    const titleId = dialog().getAttribute('aria-labelledby');
    assert.ok(titleId, 'the dialog carries aria-labelledby');
    assert
      .dom('[data-test-id="title"]')
      .hasAttribute('id', titleId!, 'it points at the rendered <h2>');
    assert.strictEqual(
      authoredAccessibleName(dialog()),
      'Delete this record?',
      'the reference resolves to the title text, so the dialog has a name',
    );
  });

  test('two modals on the page get distinct title ids', async function (assert) {
    await render(
      <template>
        <EmberRemodal @title="First" />
        <EmberRemodal @title="Second" />
      </template>,
    );

    const dialogs = Array.from(
      document.querySelectorAll('[data-test-id="modalWrapper"]'),
    );
    const names = dialogs.map((element) => authoredAccessibleName(element));

    assert.deepEqual(
      names,
      ['First', 'Second'],
      'each dialog resolves to its own title rather than the first one',
    );
  });

  test('@ariaLabel names a modal that has no visible title', async function (assert) {
    await render(
      <template>
        <EmberRemodal @openButton="Open" @ariaLabel="Session expiry notice" />
      </template>,
    );

    assert.dom('[data-test-id="title"]').doesNotExist('no visible title');
    assert
      .dom('[data-test-id="modalWrapper"]')
      .doesNotHaveAttribute(
        'aria-labelledby',
        'no dangling idref (which would name nothing)',
      );
    assert.strictEqual(
      authoredAccessibleName(dialog()),
      'Session expiry notice',
      'the dialog is named by aria-label',
    );
  });

  test('@ariaLabel wins over @title, and only one naming attribute is emitted', async function (assert) {
    await render(
      <template>
        <EmberRemodal @title="Short title" @ariaLabel="A longer spoken name" />
      </template>,
    );

    assert
      .dom('[data-test-id="modalWrapper"]')
      .hasAttribute('aria-label', 'A longer spoken name')
      .doesNotHaveAttribute('aria-labelledby');
    assert.strictEqual(
      authoredAccessibleName(dialog()),
      'A longer spoken name',
      'the explicit author name is what gets announced',
    );
  });

  test('@ariaLabel flows through @options and service.open()', async function (assert) {
    const service = lookupService(this);

    await render(
      <template>
        <EmberRemodal
          @forService={{true}}
          @name="named"
          @options={{hash ariaLabel="From options"}}
        />
      </template>,
    );

    assert.strictEqual(authoredAccessibleName(dialog()), 'From options');

    await service.open('named', { ariaLabel: 'From the service' });

    assert.strictEqual(
      authoredAccessibleName(dialog()),
      'From the service',
      'service overrides win, like every other option',
    );
  });

  test('opening a modal with neither @title nor @ariaLabel warns', async function (assert) {
    await render(<template><EmberRemodal @openButton="Open" /></template>);

    assert.strictEqual(
      authoredAccessibleName(dialog()),
      '',
      'reproduces the audited failure: the dialog has no accessible name',
    );

    const warnings = await captureWarnings(() =>
      click('[data-test-id="openButton"]'),
    );

    assert.true(
      warnings.some((warning) => warning.includes('no accessible name')),
      `warned about the unnamed dialog (got: ${JSON.stringify(warnings)})`,
    );
  });

  test('a named modal opens without an accessible-name warning', async function (assert) {
    await render(
      <template><EmberRemodal @openButton="Open" @title="Named" /></template>,
    );

    const warnings = await captureWarnings(() =>
      click('[data-test-id="openButton"]'),
    );

    assert.deepEqual(warnings, [], 'no warnings at all');
  });

  // --- QC-1-04: the close button must be named "Close Modal", not "×" --------

  test('the close button is named by aria-label, which outranks the ::before glyph', async function (assert) {
    await render(<template><EmberRemodal @title="Closable" /></template>);

    assert
      .dom('[data-test-id="nativeClose"]')
      .hasAttribute('aria-label', 'Close Modal')
      .hasAttribute('title', 'Close Modal')
      .hasText('', 'the glyph is a pseudo-element, not real text content');

    assert.strictEqual(
      authoredAccessibleName(closeButton()),
      'Close Modal',
      'the authored name is "Close Modal"',
    );

    // The bug this replaces: `title` alone was superseded by name-from-contents
    // (the ::before glyph). aria-label outranks contents unconditionally, so
    // assert the precedence itself rather than trusting the attribute.
    const button = closeButton();
    button.setAttribute('title', 'A different title');
    assert.strictEqual(
      authoredAccessibleName(button),
      'Close Modal',
      'aria-label wins over title',
    );
    button.removeAttribute('aria-label');
    assert.strictEqual(
      authoredAccessibleName(button),
      'A different title',
      'and title is only ever the fallback',
    );
  });

  test('the close-button glyph is excluded from the accessible name by the CSS alt-text form', async function (assert) {
    // `content: "…" / ""` is what keeps the ::before glyph out of
    // name-from-contents. Asserted against the shipped stylesheet source, and
    // against what the browser actually computed for the pseudo-element.
    assert.ok(
      /\.remodal-close::before\s*\{[^}]*content:\s*"\\00d7"\s*\/\s*""\s*;/.test(
        cssSource,
      ),
      'the stylesheet declares the alt-text form of `content`',
    );

    await render(<template><EmberRemodal @title="Closable" /></template>);

    const computed = window.getComputedStyle(closeButton(), '::before').content;
    assert.ok(
      computed.includes('\u00d7'),
      `the glyph still renders (computed content: ${computed})`,
    );
    assert.ok(
      computed.includes('/'),
      `the computed content carries alt text (computed content: ${computed})`,
    );
  });

  test('@closeButtonLabel is translatable and drives both aria-label and title', async function (assert) {
    await render(
      <template>
        <EmberRemodal
          @title="Fermer"
          @options={{hash closeButtonLabel="Fermer la fenêtre"}}
        />
      </template>,
    );

    assert
      .dom('[data-test-id="nativeClose"]')
      .hasAttribute('aria-label', 'Fermer la fenêtre')
      .hasAttribute('title', 'Fermer la fenêtre');
    assert.strictEqual(
      authoredAccessibleName(closeButton()),
      'Fermer la fenêtre',
    );
  });

  // --- QC-1-18: @closeOnEscape={{false}} must not become a keyboard trap -----

  test('@closeOnEscape={{false}} with no focusable control warns and lets Escape out anyway', async function (assert) {
    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @ariaLabel="Trap"
          @closeOnEscape={{false}}
          @disableNativeClose={{true}}
        />
      </template>,
    );

    const warnings = await captureWarnings(() =>
      click('[data-test-id="openButton"]'),
    );

    assert.true(dialog().open, 'the modal opened');
    assert.true(
      warnings.some((warning) => warning.includes('no way out')),
      `warned about the keyboard trap (got: ${JSON.stringify(warnings)})`,
    );

    await pressEscape();

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-closed');
    assert.false(
      dialog().open,
      'Escape closes it: refusing to would be an inescapable keyboard trap',
    );
  });

  test('@closeOnEscape={{false}} is still honored when the modal has a focusable control', async function (assert) {
    // The escape hatch above must be narrow: it only fires when there is
    // genuinely no other way out, so this configuration keeps working.
    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @ariaLabel="Not a trap"
          @closeOnEscape={{false}}
          @disableNativeClose={{true}}
        >
          <button type="button" data-test-own-close>Done</button>
        </EmberRemodal>
      </template>,
    );

    const warnings = await captureWarnings(() =>
      click('[data-test-id="openButton"]'),
    );

    assert.deepEqual(warnings, [], 'no keyboard-trap warning');

    await pressEscape();

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');
    assert.true(dialog().open, 'Escape is suppressed, as configured');
  });

  test('@closeOnEscape={{false}} with the built-in close button neither warns nor closes', async function (assert) {
    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @ariaLabel="Has a close button"
          @closeOnEscape={{false}}
        />
      </template>,
    );

    const warnings = await captureWarnings(() =>
      click('[data-test-id="openButton"]'),
    );

    assert.deepEqual(warnings, []);

    await pressEscape();

    assert.true(dialog().open, 'the close button is the keyboard exit');
  });

  // --- QC-1-35: yielded triggers need a focusable control in the block -------

  test('a yielded trigger whose block has no focusable control warns', async function (assert) {
    const warnings = await captureWarnings(() =>
      render(
        <template>
          <EmberRemodal @title="Naked trigger" as |m|>
            <m.open>Open modal</m.open>
          </EmberRemodal>
        </template>,
      ),
    );

    assert.true(
      warnings.some((warning) =>
        warning.includes('keyboard users can never reach'),
      ),
      `warned about the unreachable trigger (got: ${JSON.stringify(warnings)})`,
    );
  });

  test('legitimate block content does not warn', async function (assert) {
    // Every one of these is a real focusable control, and a false positive here
    // would shout at a working application — hence `warn`, not `assert`.
    const warnings = await captureWarnings(() =>
      render(
        <template>
          <EmberRemodal @title="Reachable" as |m|>
            <m.open><button type="button">Button</button></m.open>
            <m.confirm><a href="/somewhere">Link</a></m.confirm>
            <m.cancel><input type="checkbox" aria-label="Checkbox" /></m.cancel>
          </EmberRemodal>
          <EmberRemodal @title="Also reachable" as |m|>
            <m.open><span tabindex="0">Custom widget</span></m.open>
            <m.confirm>
              <span><span><button type="button">Nested</button></span></span>
            </m.confirm>
          </EmberRemodal>
        </template>,
      ),
    );

    assert.deepEqual(warnings, [], 'no warnings for any of these');
  });
});
