import { module, test } from 'qunit';
import { setupTest } from 'ember-qunit';
import type EmberRemodal from '#src/components/ember-remodal.gts';
import type { EmberRemodalOptions } from '#src/components/ember-remodal.gts';
import { lookupService } from '../helpers/remodal-test-helpers.ts';

class FakeModal {
  openCalls = 0;
  closeCalls = 0;
  serviceOverrides: EmberRemodalOptions | null = null;
  // Snapshot of the overrides as they stood when open() was called, so tests
  // can assert the service applies them BEFORE starting the transition.
  overridesAtOpen: EmberRemodalOptions | null = null;

  open(): Promise<this> {
    this.openCalls++;
    this.overridesAtOpen = this.serviceOverrides;
    return Promise.resolve(this);
  }

  close(): Promise<this> {
    this.closeCalls++;
    return Promise.resolve(this);
  }
}

function asModal(fake: FakeModal): EmberRemodal {
  return fake as unknown as EmberRemodal;
}

module('Unit | Service | remodal', function (hooks) {
  setupTest(hooks);

  test('open() dispatches to the registered modal and resolves with it', async function (assert) {
    const service = lookupService(this);
    const fake = new FakeModal();

    service.register('a', asModal(fake));

    const result = await service.open('a');

    assert.strictEqual(fake.openCalls, 1, 'open() called on the modal');
    assert.strictEqual(result, asModal(fake), 'resolves with the modal');
  });

  test('open() stores option overrides on the modal; omitting them leaves overrides alone', async function (assert) {
    const service = lookupService(this);
    const fake = new FakeModal();

    service.register('a', asModal(fake));

    await service.open('a', { title: 'Hello' });
    assert.deepEqual(fake.serviceOverrides, { title: 'Hello' });

    await service.open('a');
    assert.deepEqual(
      fake.serviceOverrides,
      { title: 'Hello' },
      'previous overrides persist when open() is called without options',
    );
  });

  test('open() merges option overrides across calls instead of replacing them', async function (assert) {
    const service = lookupService(this);
    const fake = new FakeModal();

    service.register('a', asModal(fake));

    await service.open('a', { title: 'Hello' });
    await service.open('a', { text: 'World' });

    assert.deepEqual(
      fake.serviceOverrides,
      { title: 'Hello', text: 'World' },
      'a later call merges onto, rather than replacing, earlier overrides',
    );
  });

  test('open() applies option overrides before starting the open transition', async function (assert) {
    // The overrides write is deferred out of any active render transaction
    // (see the backtracking-rerender regression test), but it must still land
    // before open() runs or the modal animates open showing stale content.
    const service = lookupService(this);
    const fake = new FakeModal();

    service.register('a', asModal(fake));

    await service.open('a', { title: 'Hello' });

    assert.deepEqual(
      fake.overridesAtOpen,
      { title: 'Hello' },
      'the overrides were already applied when open() ran',
    );
  });

  test('close() dispatches to the registered modal', async function (assert) {
    const service = lookupService(this);
    const fake = new FakeModal();

    service.register('a', asModal(fake));

    const result = await service.close('a');

    assert.strictEqual(fake.closeCalls, 1);
    assert.strictEqual(result, asModal(fake));
  });

  test('registering the same name again replaces the previous modal', async function (assert) {
    const service = lookupService(this);
    const first = new FakeModal();
    const second = new FakeModal();

    service.register('a', asModal(first));
    service.register('a', asModal(second));

    await service.open('a');

    assert.strictEqual(first.openCalls, 0);
    assert.strictEqual(second.openCalls, 1);
  });

  test('unregister() only removes the entry when the instance matches', async function (assert) {
    const service = lookupService(this);
    const registered = new FakeModal();
    const impostor = new FakeModal();

    service.register('a', asModal(registered));

    // A stale instance (e.g. a torn-down duplicate) must not evict the
    // currently registered one.
    service.unregister('a', asModal(impostor));
    await service.open('a');
    assert.strictEqual(
      registered.openCalls,
      1,
      'still registered after mismatched unregister',
    );

    service.unregister('a', asModal(registered));
    await assert.rejects(
      service.open('a'),
      /can not be opened because it is not rendered/,
      'matching unregister removes the modal',
    );
  });

  test('open() and close() reject helpfully for unknown names', async function (assert) {
    // They must REJECT, not throw synchronously: an assert() in the lookup
    // fired before open() could return, so `service.open('typo').catch(…)`
    // never caught in dev while it did in production.
    const service = lookupService(this);

    await assert.rejects(
      service.open('missing'),
      /The requested modal, "missing" can not be opened/,
    );

    await assert.rejects(
      service.close('missing'),
      /The requested modal, "missing" can not be opened/,
    );
  });
});
