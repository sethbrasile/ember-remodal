import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click, find, settled, waitUntil } from '@ember/test-helpers';
import { on } from '@ember/modifier';
import { tracked } from '@glimmer/tracking';
import Component from '@glimmer/component';
import type Owner from '@ember/owner';
import EmberRemodal from '#src/components/ember-remodal.gts';
import type { CloseReason } from '#src/components/ember-remodal.gts';
import {
  captureWarnings,
  dialog,
  hideDocument,
  lookupService,
  pressEscape,
  settlesWithin,
  suspendAnimationFrames,
} from '../helpers/remodal-test-helpers.ts';
import { setupRemodal } from '#src/test-support/index.ts';

/** A tracked flag a test can flip to tear a modal out of the DOM mid-flight. */
class Visibility {
  @tracked value = true;
}

module('Rendering | ember-remodal | open and close', function (hooks) {
  setupRenderingTest(hooks);
  setupRemodal(hooks);

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

    const prevented = await pressEscape();

    // The addon owns the closing animation, so it must always cancel the
    // browser's instant close. A synthetic `cancel` event has no default action
    // of its own, so without this assertion the test passes with
    // `handleNativeCancel`'s preventDefault() deleted.
    assert.true(prevented, 'the native cancel default was prevented');
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

    const prevented = await pressEscape();

    assert.true(
      prevented,
      'the cancel default is prevented whether or not we go on to close',
    );
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

    // Spy on the real event rather than sleeping for it: a fixed `setTimeout`
    // makes the test pass vacuously the day the event stops firing at all,
    // which is exactly the regression it is supposed to detect.
    const closeEvents: Event[] = [];
    dialog().addEventListener('close', (event) => closeEvents.push(event));

    const modal = await service.open('reopen');
    await modal.close().then((m) => m.open());

    await waitUntil(() => closeEvents.length > 0, { timeout: 2000 });
    assert.strictEqual(
      closeEvents.length,
      1,
      'the queued native close event really did arrive (late, after the reopen)',
    );

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

  test('close() cancels an open() that is still waiting for the <dialog> element', async function (assert) {
    // Regression test: open() used to leave `state === 'closed'` (and claim no
    // transition id) for the whole time it awaited waitForDialogElement, so
    // nothing recorded that an open was pending. A close() landing in that
    // window warned about closing an unopened modal, no-opped, and the modal
    // went on to open anyway. The same pair after render already ends closed,
    // so the outcome depended purely on render timing.
    class EarlyOpenCloser extends Component {
      constructor(owner: Owner, args: object) {
        super(owner, args);
        const remodal = owner.lookup('service:remodal');
        void remodal.open('early-pair');
        void remodal.close('early-pair');
      }

      <template></template>
    }

    const warnings: unknown[] = [];
    const originalWarn = console.warn;
    console.warn = (...args: unknown[]) => {
      warnings.push(args[0]);
    };

    try {
      await render(
        <template>
          <EmberRemodal @forService={{true}} @name="early-pair" @title="Pair" />
          <EarlyOpenCloser />
        </template>,
      );
    } finally {
      console.warn = originalWarn;
    }

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-closed');
    assert.false(dialog().open, 'the close won over the pending open');
    assert.false(
      warnings.some((warning) =>
        String(warning).includes('has not yet been opened'),
      ),
      'no spurious "close before open" warning',
    );
  });

  test('a throwing @onOpen still settles an open() that joined the same transition', async function (assert) {
    // Regression test: `deferred.resolve(this)` sat AFTER the @onOpen call with
    // no try/finally, and openDeferred had already been nulled — so when a
    // consumer's @onOpen threw, a second open() that had been handed the first
    // call's deferred was never settled and settlePendingTransitions() could
    // not rescue it.
    const service = lookupService(this);
    const explode = () => {
      throw new Error('onOpen exploded');
    };

    await render(
      <template>
        <EmberRemodal @forService={{true}} @name="boom" @onOpen={{explode}} />
      </template>,
    );

    const first = service.open('boom');
    const second = service.open('boom');

    // The exception belongs to the caller whose transition ran the callback.
    await assert.rejects(first, /onOpen exploded/);

    assert.strictEqual(
      await settlesWithin(second, 1000),
      'settled',
      'the joined open() settled instead of dangling forever',
    );
  });

  test('a throwing @onClose still settles a close() that joined the same transition', async function (assert) {
    // Same shape as the @onOpen case above, on the close path.
    const service = lookupService(this);
    const explode = () => {
      throw new Error('onClose exploded');
    };

    await render(
      <template>
        <EmberRemodal
          @forService={{true}}
          @name="boom-close"
          @onClose={{explode}}
        />
      </template>,
    );

    const modal = await service.open('boom-close');
    const first = modal.close();
    const second = modal.close();

    await assert.rejects(first, /onClose exploded/);

    assert.strictEqual(
      await settlesWithin(second, 1000),
      'settled',
      'the joined close() settled instead of dangling forever',
    );
  });

  test('close() settles in a hidden tab, where requestAnimationFrame is suspended', async function (assert) {
    // Regression test: animationsSettled unconditionally awaited two
    // requestAnimationFrames, which never fire while the tab is backgrounded,
    // so a session-timeout timer or websocket message calling close() left the
    // dialog visibly open forever and never fired @onClose.
    const service = lookupService(this);
    const reasons: (CloseReason | undefined)[] = [];
    const handleClose = (reason?: CloseReason) => reasons.push(reason);

    await render(
      <template>
        <EmberRemodal
          @forService={{true}}
          @name="hidden-tab"
          @onClose={{handleClose}}
        />
      </template>,
    );
    const modal = await service.open('hidden-tab');

    const restoreFrames = suspendAnimationFrames();
    const restoreHidden = hideDocument();
    let outcome: 'settled' | 'pending';
    try {
      outcome = await settlesWithin(modal.close(), 1000);
    } finally {
      restoreHidden();
      restoreFrames();
    }

    assert.strictEqual(outcome, 'settled', 'close() did not hang');
    assert.strictEqual(modal.state, 'closed');
    assert.false(dialog().open, 'the dialog really closed');
    assert.deepEqual(reasons, [undefined], '@onClose still fired');
  });

  test('an open() still waiting for its <dialog> element settles in a hidden tab (NB-17)', async function (assert) {
    // The other frame-waiting loop. animationsSettled got the hidden-tab guard
    // in round 1; waitForDialogElement kept its bare rAF loop, which does not
    // advance in a backgrounded tab — so an open() that landed before the
    // <dialog> rendered (a session-timeout modal opened from a route hook, say)
    // never settled, and the waitForPromise waiter wrapping it leaked for the
    // rest of the session, hanging every later settled().
    const reasons: (CloseReason | undefined)[] = [];
    const handleClose = (reason?: CloseReason) => reasons.push(reason);
    const started: { promise?: Promise<EmberRemodal> } = {};

    class EarlyOpener extends Component {
      constructor(owner: Owner, args: object) {
        super(owner, args);
        const remodal = owner.lookup('service:remodal');
        started.promise = remodal.open('hidden-early');
      }

      <template></template>
    }

    const restoreFrames = suspendAnimationFrames();
    const restoreHidden = hideDocument();
    let rendering: Promise<void> | null = null;
    let openOutcome: 'settled' | 'pending' = 'pending';
    let closeOutcome: 'settled' | 'pending' = 'pending';
    try {
      // Deliberately not awaited: render() awaits settled(), which waits on the
      // very waiter this test is about, so awaiting it here would hang the test
      // rather than fail it.
      rendering = render(
        <template>
          <EmberRemodal
            @forService={{true}}
            @name="hidden-early"
            @ariaLabel="Hidden early"
            @onClose={{handleClose}}
          />
          <EarlyOpener />
        </template>,
      );
      await waitUntil(() => started.promise !== undefined, { timeout: 2000 });
      const opening = started.promise as Promise<EmberRemodal>;
      openOutcome = await settlesWithin(opening, 2000);
      if (openOutcome === 'settled') {
        const modal = await opening;
        closeOutcome = await settlesWithin(modal.close(), 2000);
      }
    } finally {
      restoreHidden();
      restoreFrames();
    }

    assert.strictEqual(
      openOutcome,
      'settled',
      'the open settled instead of waiting on frames that never arrive',
    );
    assert.strictEqual(closeOutcome, 'settled', 'and so did the close');
    assert.false(dialog().open, 'the dialog really closed');
    assert.deepEqual(reasons, [undefined], '@onClose fired');
    // The waiter is clear, so this resolves; before the fix it was the leak.
    await rendering;
  });

  test('a transition already in flight when the tab is backgrounded still settles', async function (assert) {
    const service = lookupService(this);

    await render(
      <template>
        <EmberRemodal @forService={{true}} @name="backgrounded" />
      </template>,
    );
    const modal = await service.open('backgrounded');

    const restoreFrames = suspendAnimationFrames();
    let restoreHidden = () => {};
    let outcome: 'settled' | 'pending';
    try {
      const closing = modal.close();
      // The tab is backgrounded after close() has already started waiting on
      // frames that will now never arrive.
      restoreHidden = hideDocument();
      document.dispatchEvent(new Event('visibilitychange'));
      outcome = await settlesWithin(closing, 1000);
    } finally {
      restoreHidden();
      restoreFrames();
    }

    assert.strictEqual(outcome, 'settled', 'close() did not hang');
    assert.strictEqual(modal.state, 'closed');
  });

  test('destroying a modal while it is open closes the dialog and fires @onClose', async function (assert) {
    // The registerDialog modifier's destructor runs one `actions`-queue hop
    // before willDestroy, which nulls dialogElement — so willDestroy's
    // `if (this.dialogElement?.open)` branch was dead code and a modal
    // destroyed while open left an open <dialog> behind and never fired
    // @onClose (2.x's destroy path did fire `closed`).
    const service = lookupService(this);
    const reasons: (CloseReason | undefined)[] = [];
    const handleClose = (reason?: CloseReason) => reasons.push(reason);

    await render(
      <template>
        <EmberRemodal
          @forService={{true}}
          @name="doomed"
          @onClose={{handleClose}}
        />
      </template>,
    );

    await service.open('doomed');
    const element = dialog();
    assert.true(element.open, 'open before teardown');

    await render(<template></template>);

    assert.false(element.open, 'the <dialog> element was closed on teardown');
    assert.deepEqual(reasons, [undefined], '@onClose fired on destroy');
    assert
      .dom(document.documentElement)
      .doesNotHaveClass('remodal-is-locked', 'scroll lock released');
  });

  test('destroying a modal mid-transition settles the pending promise, releases the lock and fires @onClose', async function (assert) {
    // The sibling test above tears the modal down between transitions. This one
    // pulls it out of the DOM while an open() is still awaiting its animations:
    // the caller is holding a promise that only willDestroy can settle, and
    // both the scroll lock and the @onClose callback hang off the same path.
    const service = lookupService(this);
    const reasons: (CloseReason | undefined)[] = [];
    const handleClose = (reason?: CloseReason) => reasons.push(reason);
    const rendered = new Visibility();

    await render(
      <template>
        {{#if rendered.value}}
          <EmberRemodal
            @forService={{true}}
            @name="doomed-in-flight"
            @title="Doomed"
            @onClose={{handleClose}}
          />
        {{/if}}
      </template>,
    );

    // Deliberately not awaited: the open is mid-animation, so its promise is
    // unsettled and the scroll lock is held at the moment of teardown.
    const opening = service.open('doomed-in-flight');
    rendered.value = false;

    assert.strictEqual(
      await settlesWithin(opening, 2000),
      'settled',
      'the pending open() settled instead of dangling forever',
    );
    await settled();

    assert.dom('[data-test-id="modalWrapper"]').doesNotExist('torn down');
    assert.deepEqual(reasons, [undefined], '@onClose fired on destroy');
    assert
      .dom(document.documentElement)
      .doesNotHaveClass('remodal-is-locked', 'the scroll lock was released');
    assert.strictEqual(
      document.body.style.paddingRight,
      '',
      'and the body padding was restored',
    );
  });

  test('a <form method="dialog"> submit inside the block re-syncs state and fires @onClose exactly once', async function (assert) {
    // The browser closes the <dialog> itself here — close() is never called, so
    // handleDialogClose is the only thing that can put the state machine (and
    // the scroll lock) back in sync. Firing @onClose twice, or not at all, are
    // both live failure modes on this path.
    const reasons: (CloseReason | undefined)[] = [];
    const handleClose = (reason?: CloseReason) => reasons.push(reason);

    await render(
      <template>
        <EmberRemodal @openButton="Open" @title="Form" @onClose={{handleClose}}>
          <form method="dialog">
            <button type="submit" data-test-submit>Done</button>
          </form>
        </EmberRemodal>
      </template>,
    );

    await click('[data-test-id="openButton"]');
    assert.true(dialog().open, 'open before the submit');

    await click('[data-test-submit]');
    await waitUntil(() => reasons.length > 0, { timeout: 2000 });
    await settled();

    assert.false(dialog().open, 'the browser closed the dialog');
    assert
      .dom('[data-test-id="modalWindow"]')
      .hasClass('remodal-is-closed', 'the component state re-synced');
    assert.deepEqual(
      reasons,
      [undefined],
      '@onClose fired exactly once, with no reason',
    );
    assert
      .dom(document.documentElement)
      .doesNotHaveClass('remodal-is-locked', 'the scroll lock was released');
  });

  test('closing an already-closed modal a second time does not warn', async function (assert) {
    // The "close before open" warning is scoped by `hasOpened`, so a modal that
    // has been through one open/close cycle must stay quiet on a redundant
    // close — a route teardown or a debounced handler closing twice is normal.
    const service = lookupService(this);

    await render(
      <template>
        <EmberRemodal @forService={{true}} @name="twice" @title="Twice" />
      </template>,
    );

    await service.open('twice');
    await service.close('twice');

    const warnings = await captureWarnings(() => service.close('twice'));

    assert.deepEqual(warnings, [], 'the second close is silent');
    assert.false(dialog().open);
  });

  test('a press that starts inside the card and is released over the backdrop does not close', async function (assert) {
    // The click of a drag out of the card dispatches on the common ancestor of
    // press and release — the <dialog> — which looked exactly like a backdrop
    // click and discarded the user's content.
    await render(
      <template><EmberRemodal @openButton="Open" @title="Hi" /></template>,
    );
    await click('[data-test-id="openButton"]');

    const card = find('[data-test-id="modalWindow"]');
    assert.ok(card, 'the card is rendered');
    card?.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));
    dialog().dispatchEvent(new MouseEvent('click', { bubbles: true }));
    await settled();

    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');
    assert.true(dialog().open, 'the modal survived the drag-release');
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
