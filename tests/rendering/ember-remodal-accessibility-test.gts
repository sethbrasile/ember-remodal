import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click, find } from '@ember/test-helpers';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import EmberRemodal from '#src/components/ember-remodal.gts';
import cssSource from '../../src/styles/ember-remodal.css?raw';
import {
  authoredAccessibleName,
  captureWarnings,
  dialog,
  lookupService,
  pressEscape,
} from '../helpers/remodal-test-helpers.ts';
import { setupRemodal } from '#src/test-support/index.ts';

function closeButton(): HTMLButtonElement {
  return find('[data-test-id="nativeClose"]') as HTMLButtonElement;
}

module('Rendering | ember-remodal | accessibility', function (hooks) {
  setupRenderingTest(hooks);
  setupRemodal(hooks);

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

  // --- NB-30: a later service.open() must not leave a stale name behind ------

  test('a second service.open() with a different naming key does not leak the first name', async function (assert) {
    const service = lookupService(this);

    await render(
      <template><EmberRemodal @forService={{true}} @name="leak" /></template>,
    );

    await service.open('leak', { ariaLabel: 'Session expired' });
    assert.strictEqual(authoredAccessibleName(dialog()), 'Session expired');

    await service.close('leak');
    await service.open('leak', { title: 'Delete record?' });

    assert.dom('[data-test-id="title"]').hasText('Delete record?');
    assert.strictEqual(
      authoredAccessibleName(dialog()),
      'Delete record?',
      'the dialog announces what it displays; the stale @ariaLabel is gone',
    );
    assert
      .dom('[data-test-id="modalWrapper"]')
      .doesNotHaveAttribute('aria-label');
  });

  test('a stale @title does not survive a later service.open() that names by @ariaLabel', async function (assert) {
    const service = lookupService(this);

    await render(
      <template><EmberRemodal @forService={{true}} @name="leak2" /></template>,
    );

    await service.open('leak2', { title: 'Delete record?' });
    assert.dom('[data-test-id="title"]').hasText('Delete record?');

    await service.close('leak2');
    await service.open('leak2', { ariaLabel: 'Session expired' });

    assert
      .dom('[data-test-id="title"]')
      .doesNotExist('the stale visible title is gone too');
    assert.strictEqual(
      authoredAccessibleName(dialog()),
      'Session expired',
      'nothing displayed contradicts what is announced',
    );
  });

  test('non-naming overrides still merge across service.open() calls', async function (assert) {
    // The narrow scope of the reset: only the mutually-exclusive naming keys
    // clear each other. 2.x setProperties parity for everything else is a
    // round-1 regression test and must keep passing.
    const service = lookupService(this);

    await render(
      <template><EmberRemodal @forService={{true}} @name="keep" /></template>,
    );

    await service.open('keep', { title: 'A title' });
    await service.close('keep');
    await service.open('keep', { text: 'B text' });

    assert
      .dom('[data-test-id="title"]')
      .hasText('A title', 'title survives a later override that does not name');
    assert.dom('[data-test-id="text"]').hasText('B text');
  });

  // --- NB-29: @ariaLabelledBy names a modal from consumer-authored markup ----

  test('@ariaLabelledBy points the dialog at a consumer-authored heading', async function (assert) {
    await render(
      <template>
        <EmberRemodal @openButton="Open" @ariaLabelledBy="consumer-heading">
          <h2 id="consumer-heading">Consumer-authored heading</h2>
        </EmberRemodal>
      </template>,
    );

    assert
      .dom('[data-test-id="modalWrapper"]')
      .hasAttribute('aria-labelledby', 'consumer-heading')
      .doesNotHaveAttribute(
        'aria-label',
        'only one naming attribute is emitted',
      );
    assert.strictEqual(
      authoredAccessibleName(dialog()),
      'Consumer-authored heading',
      'the name comes from the block content, not a duplicated @ariaLabel',
    );

    const warnings = await captureWarnings(() =>
      click('[data-test-id="openButton"]'),
    );
    assert.deepEqual(warnings, [], 'no accessible-name warning');
  });

  test('@ariaLabelledBy outranks @ariaLabel and @title, matching accname', async function (assert) {
    await render(
      <template>
        <EmberRemodal
          @title="A visible title"
          @ariaLabel="An aria-label"
          @ariaLabelledBy="preferred-heading"
        >
          <h2 id="preferred-heading">The referenced heading</h2>
        </EmberRemodal>
      </template>,
    );

    assert.strictEqual(
      authoredAccessibleName(dialog()),
      'The referenced heading',
      'aria-labelledby wins, as it does in the accname algorithm',
    );
    assert
      .dom('[data-test-id="modalWrapper"]')
      .doesNotHaveAttribute('aria-label');
    assert
      .dom('[data-test-id="title"]')
      .hasText('A visible title', 'the visible title still renders');
  });

  test('a dangling @ariaLabelledBy idref names nothing, and warns', async function (assert) {
    // The whole point of modelling this explicitly: an attribute that is
    // PRESENT but resolves to no element names nothing at all. Trusting the
    // attribute would be the same "assumed complete" mistake as the old exit
    // gate.
    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @ariaLabelledBy="nothing-with-this-id"
        />
      </template>,
    );

    assert.strictEqual(
      authoredAccessibleName(dialog()),
      '',
      'the dialog has no accessible name',
    );

    const warnings = await captureWarnings(() =>
      click('[data-test-id="openButton"]'),
    );

    assert.true(
      warnings.some((warning) =>
        warning.includes('resolvable accessible name'),
      ),
      `warned about the unnamed dialog (got: ${JSON.stringify(warnings)})`,
    );
  });

  // --- NB-31: whitespace-only names are absent names -------------------------

  test('@title=" " renders no <h2> and leaves the dialog unnamed (NB-31)', async function (assert) {
    await render(
      <template><EmberRemodal @openButton="Open" @title=" " /></template>,
    );

    assert
      .dom('[data-test-id="title"]')
      .doesNotExist('a whitespace-only title renders no heading');
    assert
      .dom('[data-test-id="modalWrapper"]')
      .doesNotHaveAttribute(
        'aria-labelledby',
        'and no idref pointing at a heading that is not there',
      );
    assert.strictEqual(
      authoredAccessibleName(dialog()),
      '',
      'accname trims it to the empty string, so the dialog is unnamed',
    );

    const warnings = await captureWarnings(() =>
      click('[data-test-id="openButton"]'),
    );

    assert.true(
      warnings.some((warning) =>
        warning.includes('resolvable accessible name'),
      ),
      `the guard reports it as unnamed rather than named (got: ${JSON.stringify(warnings)})`,
    );
  });

  test('@ariaLabel=" " is treated as absent too', async function (assert) {
    await render(
      <template>
        <EmberRemodal @openButton="Open" @title="Real title" @ariaLabel="   " />
      </template>,
    );

    assert
      .dom('[data-test-id="modalWrapper"]')
      .doesNotHaveAttribute(
        'aria-label',
        'a whitespace-only aria-label is not emitted',
      );
    assert.strictEqual(
      authoredAccessibleName(dialog()),
      'Real title',
      'so the @title still names the dialog instead of being suppressed by it',
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
      warnings.some((warning) =>
        warning.includes('resolvable accessible name'),
      ),
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

  test('@closeOnEscape={{false}} is honored when the consumer declares their own exit', async function (assert) {
    // The escape hatch above must be narrow: it only fires when there is
    // genuinely no other way out, so this configuration keeps working — but the
    // block content has to SAY so. The addon cannot tell a real exit from an
    // <input type="hidden"> by looking at the DOM.
    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @ariaLabel="Not a trap"
          @closeOnEscape={{false}}
          @disableNativeClose={{true}}
          @hasCustomKeyboardExit={{true}}
          as |m|
        >
          <button
            type="button"
            data-test-own-close
            {{on "click" m.closeAction}}
          >
            Done
          </button>
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

  // --- QC-2-03: the exit gate is an enumeration, not a DOM guess -------------

  test('a focusable descendant that is not an exit does not suppress Escape (QC-2-03a)', async function (assert) {
    // Mode (a) of QC-2-03. `hasFocusableDescendant` — the lenient predicate the
    // ErButton reachability warning uses — matches input[type=hidden]. Reusing
    // it as the trap gate meant a hidden CSRF field counted as "a way out".
    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @ariaLabel="Hidden-input trap"
          @closeOnEscape={{false}}
          @disableNativeClose={{true}}
        >
          <input type="hidden" name="csrf" value="a-token" />
          <button type="button" disabled>Submit</button>
          <span tabindex="-1">Programmatic focus target</span>
        </EmberRemodal>
      </template>,
    );

    const warnings = await captureWarnings(() =>
      click('[data-test-id="openButton"]'),
    );

    assert.true(
      warnings.some((warning) => warning.includes('no way out')),
      `warned about the keyboard trap (got: ${JSON.stringify(warnings)})`,
    );

    await pressEscape();

    assert.false(
      dialog().open,
      'Escape closes it: none of a hidden input, a disabled button or tabindex="-1" is an exit',
    );
  });

  test('cancel and confirm buttons that never close are not a way out (QC-2-03b)', async function (assert) {
    // Mode (b) of QC-2-03: every argument here is documented, there is no
    // consumer markup at all, and the result is two tabbable buttons that can
    // never dismiss the modal.
    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @ariaLabel="All-documented-options trap"
          @closeOnEscape={{false}}
          @disableNativeClose={{true}}
          @cancelButton="No"
          @closeOnCancel={{false}}
          @confirmButton="Yes"
          @closeOnConfirm={{false}}
        />
      </template>,
    );

    const warnings = await captureWarnings(() =>
      click('[data-test-id="openButton"]'),
    );

    assert.true(
      warnings.some((warning) => warning.includes('no way out')),
      `warned about the keyboard trap (got: ${JSON.stringify(warnings)})`,
    );

    await pressEscape();

    assert.false(
      dialog().open,
      'Escape closes it: neither button closes the modal, so neither is an exit',
    );
  });

  test('a blank @cancelButton is neither rendered nor counted as an exit', async function (assert) {
    // NB-31's defect on the opposite element, and it re-opens the trap the
    // exit enumeration exists to close: " " is truthy, so the button rendered
    // with no perceivable label and no accessible name, and the enumeration
    // counted it as the keyboard way out. One getter feeds both the
    // enumeration and the render condition, so they cannot disagree.
    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @ariaLabel="Blank-label trap"
          @closeOnEscape={{false}}
          @disableNativeClose={{true}}
          @cancelButton=" "
        />
      </template>,
    );

    const warnings = await captureWarnings(() =>
      click('[data-test-id="openButton"]'),
    );

    assert.dom('[data-test-id="cancelButton"]').doesNotExist('no empty button');
    assert.true(
      warnings.some((warning) => warning.includes('no way out')),
      `warned about the keyboard trap (got: ${JSON.stringify(warnings)})`,
    );

    await pressEscape();

    assert.false(
      dialog().open,
      'Escape closes it: a button with no label is not a way out',
    );
  });

  test('a blank @confirmButton is not rendered either', async function (assert) {
    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @ariaLabel="Blank confirm"
          @confirmButton=" "
        />
      </template>,
    );
    await click('[data-test-id="openButton"]');

    assert.dom('[data-test-id="confirmButton"]').doesNotExist();
  });

  test('a cancel button that does close IS an exit, so Escape stays suppressed', async function (assert) {
    // The other side of QC-2-03b: same shape, but @closeOnCancel left at its
    // default, so the enumeration finds a real exit.
    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @ariaLabel="Cancellable"
          @closeOnEscape={{false}}
          @disableNativeClose={{true}}
          @cancelButton="No"
        />
      </template>,
    );

    const warnings = await captureWarnings(() =>
      click('[data-test-id="openButton"]'),
    );

    assert.deepEqual(warnings, [], 'no keyboard-trap warning');

    await pressEscape();

    assert.true(dialog().open, 'the cancel button is the keyboard exit');

    await click('[data-test-id="cancelButton"]');
    assert.false(dialog().open, 'and it really does close the modal');
  });

  test('a consumer who does not declare an exit is never trapped, even with a real button', async function (assert) {
    // The opt-in is fail-safe: undeclared means Escape is NOT suppressed. A
    // consumer who forgets the argument gets a dev warning and a working
    // Escape key, not a trap.
    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @ariaLabel="Undeclared"
          @closeOnEscape={{false}}
          @disableNativeClose={{true}}
          as |m|
        >
          <button type="button" {{on "click" m.closeAction}}>Done</button>
        </EmberRemodal>
      </template>,
    );

    const warnings = await captureWarnings(() =>
      click('[data-test-id="openButton"]'),
    );

    assert.true(
      warnings.some((warning) => warning.includes('no way out')),
      `warned, naming the opt-in (got: ${JSON.stringify(warnings)})`,
    );
    assert.true(
      warnings.some((warning) => warning.includes('@hasCustomKeyboardExit')),
      'the warning names the argument that declares a block-provided exit',
    );

    await pressEscape();

    assert.false(dialog().open, 'Escape closes it rather than trapping');
  });

  test('backdrop click is not a keyboard exit', async function (assert) {
    // @closeOnOutsideClick defaults to true, so counting it as an exit would
    // suppress Escape on almost every modal while leaving keyboard-only users
    // with nothing (WCAG 2.1.2 is about the keyboard interface).
    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @ariaLabel="Pointer-only exit"
          @closeOnEscape={{false}}
          @disableNativeClose={{true}}
          @closeOnOutsideClick={{true}}
        />
      </template>,
    );

    const warnings = await captureWarnings(() =>
      click('[data-test-id="openButton"]'),
    );

    assert.true(
      warnings.some((warning) => warning.includes('no way out')),
      `warned about the keyboard trap (got: ${JSON.stringify(warnings)})`,
    );

    await pressEscape();

    assert.false(dialog().open, 'Escape closes it');
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
