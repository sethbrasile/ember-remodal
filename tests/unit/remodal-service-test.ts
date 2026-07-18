import { module, test } from 'qunit';
import { setupTest } from 'ember-qunit';
import type { TestContext } from '@ember/test-helpers';
import type RemodalService from '#src/services/remodal.ts';
import type EmberRemodal from '#src/components/ember-remodal.gts';
import type { EmberRemodalOptions } from '#src/components/ember-remodal.gts';

class FakeModal {
  openCalls = 0;
  closeCalls = 0;
  serviceOverrides: EmberRemodalOptions | null = null;

  open(): Promise<this> {
    this.openCalls++;
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

function lookupService(context: TestContext): RemodalService {
  return context.owner.lookup('service:remodal');
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
    assert.throws(
      () => {
        void service.open('a');
      },
      /can not be opened because it is not rendered/,
      'matching unregister removes the modal',
    );
  });

  test('open() and close() assert helpfully for unknown names', function (assert) {
    const service = lookupService(this);

    assert.throws(() => {
      void service.open('missing');
    }, /The requested modal, "missing" can not be opened/);

    assert.throws(() => {
      void service.close('missing');
    }, /The requested modal, "missing" can not be opened/);
  });
});
