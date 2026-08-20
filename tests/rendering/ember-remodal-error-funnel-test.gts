import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click, settled } from '@ember/test-helpers';
import EmberRemodal from '#src/components/ember-remodal.gts';
import { scrollLockStateForTesting } from '#src/components/ember-remodal.gts';
import componentSource from '../../src/components/ember-remodal.gts?raw';
import {
  captureErrors,
  dialog,
  lookupService,
} from '../helpers/remodal-test-helpers.ts';
import { setupRemodal } from '#src/test-support/index.ts';

// The brand `domHandler` attaches. Looked up from the global symbol registry
// rather than imported, so the component does not have to export a testing seam
// for the assertion below (the package's "./*" entry would make one
// semver-visible).
const DOM_HANDLER = Symbol.for('ember-remodal:dom-handler');

/**
 * Every handler the component's template hands to the DOM: the `{{on}}`
 * modifiers, and the `onClick` of each yielded ErButton. Read out of the
 * template source rather than hardcoded, so a binding added later is picked up
 * by the assertion instead of quietly escaping it.
 */
function templateBoundNames(source: string): string[] {
  // The class body precedes the template and is deliberately excluded: it is
  // full of `this.x` references that are not DOM bindings.
  const template = source.slice(source.indexOf('<template>'));
  const names = new Set<string>();
  for (const match of template.matchAll(
    /\{\{on\s+"[a-z]+"\s+this\.(\w+)\s*\}\}/g,
  )) {
    names.add(match[1] as string);
  }
  // `onClick=this.handleOpenClick`, `closeAction=this.closeAction`, … — the
  // hash and component bindings. Non-function values (`isOpen`, `destination`)
  // are filtered out by the caller.
  for (const match of template.matchAll(/\w+=this\.(\w+)\b/g)) {
    names.add(match[1] as string);
  }
  return [...names].sort();
}

function explode(message: string): () => never {
  return () => {
    throw new Error(message);
  };
}

// `async () => { throw }` written as an expression: a callback that hands an
// already-rejected promise back to a call site that does not await it.
function explodeAsync(message: string): () => Promise<never> {
  return () => Promise.reject(new Error(message));
}

module('Rendering | ember-remodal | error funnel', function (hooks) {
  setupRenderingTest(hooks);
  setupRemodal(hooks);

  // --- QC-2-01: confirm/cancel were outside the funnel -----------------------

  test('every handler the template binds to the DOM is produced by the wrapper factory', async function (assert) {
    // The structural assertion behind the whole unit. A public method bound
    // directly — `onClick=this.confirm`, which is what shipped — is a function
    // without the brand, so it fails here rather than at the next unhandled
    // rejection.
    const service = lookupService(this);
    await render(
      <template>
        <EmberRemodal @forService={{true}} @name="funnel" @ariaLabel="Funnel" />
      </template>,
    );
    const modal = await service.open('funnel');
    const instance = modal as unknown as Record<string, unknown>;

    const bound = templateBoundNames(componentSource).filter(
      (name) => typeof instance[name] === 'function',
    );

    for (const expected of [
      'openAction',
      'closeAction',
      'confirmAction',
      'cancelAction',
      'handleOpenClick',
      'handleWrapperMouseDown',
      'handleWrapperClick',
      'handleNativeCancel',
      'handleDialogClose',
    ]) {
      assert.true(
        bound.includes(expected),
        `${expected} was found among the template's DOM bindings`,
      );
    }

    for (const name of bound) {
      assert.true(
        DOM_HANDLER in (instance[name] as object),
        `${name} came from the wrapper factory, so it carries the error funnel`,
      );
    }

    // The counterpart: the raw public methods are NOT branded, which is what
    // makes the loop above able to fail.
    assert.false(
      DOM_HANDLER in modal.confirm,
      'the raw confirm() is unbranded, so binding it in the template would fail this test',
    );
    assert.false(DOM_HANDLER in modal.close, 'and so is the raw close()');

    await modal.close();
  });

  test('a throwing @onConfirm is reported rather than escaping the click handler', async function (assert) {
    // Nothing covered this before: `confirm` was a plain arrow that called
    // @onConfirm synchronously, so the throw escaped past the promise
    // confirmAction was catching on and out of the DOM event handler entirely.
    const handleConfirm = explode('onConfirm exploded');

    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @ariaLabel="Throwing confirm"
          @confirmButton="Yes"
          @onConfirm={{handleConfirm}}
        />
      </template>,
    );
    await click('[data-test-id="openButton"]');

    const errors = await captureErrors(() =>
      click('[data-test-id="confirmButton"]'),
    );

    assert.deepEqual(
      errors,
      ['Error: onConfirm exploded'],
      'the failure was reported through the funnel',
    );
    assert.true(
      dialog().open,
      'and confirm() aborted before closing, as it always has when @onConfirm throws',
    );
  });

  test('a throwing @onCancel is reported rather than escaping the click handler', async function (assert) {
    const handleCancel = explode('onCancel exploded');

    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @ariaLabel="Throwing cancel"
          @cancelButton="No"
          @onCancel={{handleCancel}}
        />
      </template>,
    );
    await click('[data-test-id="openButton"]');

    const errors = await captureErrors(() =>
      click('[data-test-id="cancelButton"]'),
    );

    assert.deepEqual(errors, ['Error: onCancel exploded']);
    assert.true(dialog().open, 'cancel() aborted before closing');
  });

  test('the yielded m.confirm and m.cancel funnel a throwing callback too', async function (assert) {
    // The sharper half of QC-2-01: these bound the RAW confirm/cancel methods,
    // so the throw did not even reach confirmAction's catch — and ErButton
    // discarded the promise they returned.
    const handleConfirm = explode('yielded onConfirm exploded');
    const handleCancel = explode('yielded onCancel exploded');

    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @ariaLabel="Throwing yield"
          @onConfirm={{handleConfirm}}
          @onCancel={{handleCancel}}
          as |m|
        >
          <m.confirm data-test-confirm>
            <button type="button">Yes</button>
          </m.confirm>
          <m.cancel data-test-cancel>
            <button type="button">No</button>
          </m.cancel>
        </EmberRemodal>
      </template>,
    );
    await click('[data-test-id="openButton"]');

    const confirmErrors = await captureErrors(() =>
      click('[data-test-confirm]'),
    );
    assert.deepEqual(confirmErrors, ['Error: yielded onConfirm exploded']);
    assert.true(
      dialog().open,
      'still open: the confirm never got as far as closing',
    );

    const cancelErrors = await captureErrors(() => click('[data-test-cancel]'));
    assert.deepEqual(cancelErrors, ['Error: yielded onCancel exploded']);
    assert.true(dialog().open);
  });

  // --- QC-2-08: the asynchronous half of a throwing callback -----------------

  test('an async @onOpen that rejects is reported, and open() still settles', async function (assert) {
    // The synchronous throw was covered; this one is a different path
    // altogether. `this.opt('onOpen')?.()` never references what it gets back,
    // so an already-rejected promise had nowhere to go but the global
    // unhandledrejection handler.
    const service = lookupService(this);
    const handleOpen = explodeAsync('async onOpen exploded');

    await render(
      <template>
        <EmberRemodal
          @forService={{true}}
          @name="async-open"
          @ariaLabel="Async open"
          @onOpen={{handleOpen}}
        />
      </template>,
    );

    let state = '';
    const errors = await captureErrors(async () => {
      const modal = await service.open('async-open');
      state = modal.state;
      await settled();
    });

    assert.strictEqual(state, 'opened', 'the open still completed');
    assert.deepEqual(errors, ['Error: async onOpen exploded']);
    assert.true(dialog().open);
  });

  test('an async @onClose that rejects is reported, and close() still settles', async function (assert) {
    const service = lookupService(this);
    const handleClose = explodeAsync('async onClose exploded');

    await render(
      <template>
        <EmberRemodal
          @forService={{true}}
          @name="async-close"
          @ariaLabel="Async close"
          @onClose={{handleClose}}
        />
      </template>,
    );
    const modal = await service.open('async-close');

    let state = '';
    const errors = await captureErrors(async () => {
      await modal.close();
      state = modal.state;
      await settled();
    });

    assert.strictEqual(state, 'closed', 'the close still completed');
    assert.deepEqual(errors, ['Error: async onClose exploded']);
    assert.false(dialog().open);
  });

  // --- QC-2-02: the @onClose call site with no promise behind it -------------

  test('a throwing @onClose on the native close path is reported, not thrown at the listener', async function (assert) {
    // finalizeClose's @onClose call is unguarded, and handleDialogClose invokes
    // it straight from the native `close` listener — the path a
    // <form method="dialog"> inside consumer content (or a browser force-close)
    // takes. There is no promise there to turn the throw into a rejection, so
    // the funnel around the handler is what has to catch it.
    const service = lookupService(this);
    const handleClose = explode('native onClose exploded');

    await render(
      <template>
        <EmberRemodal
          @forService={{true}}
          @name="native-close"
          @ariaLabel="Native close"
          @onClose={{handleClose}}
        />
      </template>,
    );
    const modal = await service.open('native-close');
    const element = dialog();

    const errors = await captureErrors(async () => {
      // What a <form method="dialog"> submit does: close the element itself,
      // outside the addon's own close(). The real event is queued; dispatching
      // it makes the test deterministic.
      element.close();
      element.dispatchEvent(new Event('close'));
      await settled();
    });

    assert.deepEqual(errors, ['Error: native onClose exploded']);
    assert.strictEqual(modal.state, 'closed', 'state re-synced anyway');
  });

  // --- QC-2-09: showModal() failing on a disconnected <dialog> ---------------

  test('a failing showModal() rejects open() and leaves the state coherent', async function (assert) {
    // The try/catch + setState('closed') + rethrow around showModal() existed
    // for round 1's QC-1-28 and was covered by nothing. showModal() throws
    // InvalidStateError for a <dialog> that is not connected to a document, and
    // the reopen-during-a-close below is the configuration where all three
    // pieces matter: without the catch or the setState the modal strands at
    // 'closing' holding the scroll lock; without the rethrow the caller is told
    // the modal opened.
    const service = lookupService(this);

    await render(
      <template>
        <EmberRemodal
          @forService={{true}}
          @name="disconnected"
          @ariaLabel="Disconnected"
        />
      </template>,
    );

    const modal = await service.open('disconnected');
    const element = dialog();
    assert.true(
      scrollLockStateForTesting().locked,
      'the scroll lock is held while open',
    );

    // A close is in flight — state 'closing', lock still held — when something
    // outside the addon closes the <dialog> and takes it out of the document,
    // and a reopen lands in that window.
    const closing = modal.close();
    element.close();
    element.remove();

    let error: unknown;
    try {
      await modal.open();
    } catch (caught) {
      error = caught;
    }

    // Asserted HERE, before awaiting anything else, and that is load-bearing:
    // `element.close()` queues a native `close` event, and handleDialogClose
    // re-syncs the state when it arrives. A task boundary later, every
    // assertion below passes with the catch deleted — the window in which the
    // component is the only thing holding the state together is exactly this
    // one, between the rejection (microtasks) and that queued event (a task).
    assert.strictEqual(
      (error as DOMException | undefined)?.name,
      'InvalidStateError',
      'the failure reached the caller instead of resolving as a successful open (the rethrow)',
    );
    assert.strictEqual(
      modal.state,
      'closed',
      'state did not strand at "closing" (the setState)',
    );
    assert.false(
      scrollLockStateForTesting().locked,
      'and the document scroll lock went with it (also the setState)',
    );
    assert.strictEqual(scrollLockStateForTesting().holders, 0);

    await closing;
  });
});
