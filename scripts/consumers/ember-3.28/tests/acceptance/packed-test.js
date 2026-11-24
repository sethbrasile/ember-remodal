import Ember from 'ember';
import { VERSION } from '@ember/version';
import $ from 'jquery';
import { module, test } from 'qunit';
import { setupApplicationTest } from 'ember-qunit';
import { visit, click, find, waitFor, waitUntil } from '@ember/test-helpers';
// Written by scripts/test-consumer.sh for the consumer being run.
import expected from '../helpers/expected';

const TRIGGER = '[id^=open-button-]';
const TITLE = '.remodal-is-opened [data-test-id=title]';
const NATIVE_CLOSE = '[data-test-id=nativeClose]';

function registeredVersion() {
  let library = Ember.libraries._registry.find((entry) => entry.name === 'Ember Remodal');
  return library && library.version;
}

module('Acceptance | packed ember-remodal', function (hooks) {
  setupApplicationTest(hooks);

  test('the browser runs the versions this consumer names', function (assert) {
    assert.expect(3);
    assert.strictEqual(VERSION, expected.ember, 'Ember');
    assert.strictEqual($.fn.jquery, expected.jquery, 'jQuery');
    assert.strictEqual(registeredVersion(), expected.remodal, 'ember-remodal');
  });

  test('the yielded trigger opens the modal and the native close button closes it', async function (assert) {
    assert.expect(5);
    await visit('/');
    assert.strictEqual(find(TRIGGER).textContent.trim(), 'Show packed modal', 'the yielded trigger rendered its block');
    assert.strictEqual(find(TITLE), null, 'the modal starts closed');

    // remodal reaches its opened and closed states when its CSS animations
    // end, which click() does not wait for.
    await click(TRIGGER);
    await waitFor(TITLE, { timeout: 5000 });
    assert.strictEqual(find(TITLE).textContent.trim(), 'Packed modal', 'the trigger opened the modal');
    assert.strictEqual(find(NATIVE_CLOSE).getAttribute('title'), 'Close Modal', 'the native close button is named');

    await click(NATIVE_CLOSE);
    await waitUntil(() => find(TITLE) === null, { timeout: 5000 });
    assert.strictEqual(find(TITLE), null, 'the native close button closed the modal');
  });

  test('the service opens and closes the modal', async function (assert) {
    assert.expect(5);
    await visit('/');
    let service = this.owner.lookup('service:remodal');
    let component = service.get('ember-remodal');
    assert.ok(component, 'the rendered modal registered itself on the service');

    let opened = await service.open();
    assert.strictEqual(opened, component, 'open() resolves to the component');
    assert.strictEqual(find(TITLE).textContent.trim(), 'Packed modal', 'open() opened the modal');

    let closed = await service.close();
    assert.strictEqual(closed, component, 'close() resolves to the component');
    assert.strictEqual(find(TITLE), null, 'close() closed the modal');
  });

  test('closing through the service before opening resolves to the component', async function (assert) {
    assert.expect(3);
    await visit('/');
    let service = this.owner.lookup('service:remodal');
    let component = service.get('ember-remodal');
    assert.ok(component, 'the rendered modal registered itself on the service');
    assert.notOk(component.get('modal'), 'the modal has never been opened');

    let result = await service.close();
    assert.strictEqual(result, component, 'close() resolves to the component');
  });
});
