import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click } from '@ember/test-helpers';
import EmberRemodal from '#src/components/ember-remodal.gts';
import type { CloseReason } from '#src/components/ember-remodal.gts';
import { dialog, lookupService } from '../helpers/remodal-test-helpers.ts';
import { setupRemodal } from '#src/test-support/index.ts';

module('Rendering | ember-remodal | confirm and cancel', function (hooks) {
  setupRenderingTest(hooks);
  setupRemodal(hooks);

  test('@confirmButton fires @onConfirm, closes, and reports the reason to @onClose', async function (assert) {
    let confirmed = 0;
    const reasons: (CloseReason | undefined)[] = [];
    const handleConfirm = () => confirmed++;
    const handleClose = (reason?: CloseReason) => reasons.push(reason);

    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @confirmButton="Confirm"
          @onConfirm={{handleConfirm}}
          @onClose={{handleClose}}
        />
      </template>,
    );
    await click('[data-test-id="openButton"]');

    await click('[data-test-id="confirmButton"]');

    assert.strictEqual(confirmed, 1, '@onConfirm fired once');
    assert.deepEqual(reasons, ['confirmation'], 'reason passed to @onClose');
    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-closed');
    assert.false(dialog().open);
  });

  test('@cancelButton fires @onCancel, closes, and reports the reason to @onClose', async function (assert) {
    let cancelled = 0;
    const reasons: (CloseReason | undefined)[] = [];
    const handleCancel = () => cancelled++;
    const handleClose = (reason?: CloseReason) => reasons.push(reason);

    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @cancelButton="Cancel"
          @onCancel={{handleCancel}}
          @onClose={{handleClose}}
        />
      </template>,
    );
    await click('[data-test-id="openButton"]');

    await click('[data-test-id="cancelButton"]');

    assert.strictEqual(cancelled, 1, '@onCancel fired once');
    assert.deepEqual(reasons, ['cancellation'], 'reason passed to @onClose');
    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-closed');
    assert.false(dialog().open);
  });

  test('a stale native close racing an in-flight confirm still reports the confirmation reason', async function (assert) {
    // Regression test: a native `close` event arriving mid-animation bumps the
    // transitionId and finalizes with no reason of its own, which made the
    // in-flight close('confirmation') skip its own finalizeClose — so @onClose
    // received undefined instead of 'confirmation'.
    const service = lookupService(this);
    const reasons: (CloseReason | undefined)[] = [];
    const handleClose = (reason?: CloseReason) => reasons.push(reason);

    await render(
      <template>
        <EmberRemodal
          @forService={{true}}
          @name="reason-race"
          @onClose={{handleClose}}
        />
      </template>,
    );

    const modal = await service.open('reason-race');
    const closing = modal.confirm();
    // Something outside the addon closes the dialog natively while our closing
    // animation is still running (a `<form method="dialog">` submit inside user
    // content, say). The real event is queued; dispatching it synchronously
    // makes the race deterministic.
    dialog().close();
    dialog().dispatchEvent(new Event('close'));

    await closing;

    assert.deepEqual(reasons, ['confirmation'], 'the reason survived the race');
  });

  test('the yielded m.confirm and m.cancel buttons work', async function (assert) {
    const events: string[] = [];
    const handleConfirm = () => events.push('confirm');
    const handleCancel = () => events.push('cancel');

    await render(
      <template>
        <EmberRemodal
          @onConfirm={{handleConfirm}}
          @onCancel={{handleCancel}}
          as |m|
        >
          <m.open data-test-open>
            <button type="button">Open</button>
          </m.open>
          <m.confirm data-test-confirm>
            <button type="button">Yes</button>
          </m.confirm>
          <m.cancel data-test-cancel>
            <button type="button">No</button>
          </m.cancel>
        </EmberRemodal>
      </template>,
    );

    await click('[data-test-open]');
    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');

    await click('[data-test-confirm]');
    assert.deepEqual(events, ['confirm'], '@onConfirm fired');
    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-closed');

    await click('[data-test-open]');
    await click('[data-test-cancel]');
    assert.deepEqual(events, ['confirm', 'cancel'], '@onCancel fired');
    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-closed');
    assert.false(dialog().open);
  });

  test('@closeOnConfirm={{false}} fires @onConfirm but keeps the modal open', async function (assert) {
    let confirmed = 0;
    const handleConfirm = () => confirmed++;

    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @confirmButton="Confirm"
          @closeOnConfirm={{false}}
          @onConfirm={{handleConfirm}}
        />
      </template>,
    );
    await click('[data-test-id="openButton"]');

    await click('[data-test-id="confirmButton"]');

    assert.strictEqual(confirmed, 1, '@onConfirm fired');
    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');
    assert.true(dialog().open, 'modal stayed open');
  });

  test("m.confirm does not swallow a checkbox's default toggle behavior", async function (assert) {
    // Regression test: the yielded confirm/cancel buttons previously called
    // preventDefault() unconditionally, which suppressed a wrapped
    // checkbox's native toggle. The old addon's confirm/cancel buttons never
    // did this (only the open-trigger path preventDefaults, to stop
    // `<a href="#">` from navigating).
    let confirmed = 0;
    const handleConfirm = () => confirmed++;

    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @closeOnConfirm={{false}}
          @onConfirm={{handleConfirm}}
          as |m|
        >
          <m.confirm>
            <label>
              <input type="checkbox" data-test-agree />
              I agree
            </label>
          </m.confirm>
        </EmberRemodal>
      </template>,
    );
    await click('[data-test-id="openButton"]');

    await click('[data-test-agree]');

    assert.dom('[data-test-agree]').isChecked('checkbox still toggles');
    assert.strictEqual(confirmed, 1, '@onConfirm still fired');
  });

  test('@closeOnCancel={{false}} fires @onCancel but keeps the modal open', async function (assert) {
    let cancelled = 0;
    const handleCancel = () => cancelled++;

    await render(
      <template>
        <EmberRemodal
          @openButton="Open"
          @cancelButton="Cancel"
          @closeOnCancel={{false}}
          @onCancel={{handleCancel}}
        />
      </template>,
    );
    await click('[data-test-id="openButton"]');

    await click('[data-test-id="cancelButton"]');

    assert.strictEqual(cancelled, 1, '@onCancel fired');
    assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');
    assert.true(dialog().open, 'modal stayed open');
  });
});
