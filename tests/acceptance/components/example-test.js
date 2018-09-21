import { module, test } from 'qunit';
import { setupApplicationTest } from 'ember-qunit';
import { visit, currentURL, click, findAll } from '@ember/test-helpers';

module('Acceptance | components example acceptance test', function(hooks) {
  setupApplicationTest(hooks);

  hooks.beforeEach(async function() {
    await visit('/components/example');
    await click('[data-test-id="modal"] [data-test-id="openButton"]');
  });

  test('visiting /components/example', function(assert) {
    assert.equal(currentURL(), '/components/example');
  });

  test('it opens', async function(assert) {
    assert.expect(1);
    const lengthOpened = findAll('[data-test-id="modalWindow"].remodal-is-opened').length;
    const lengthOpening = findAll('[data-test-id="modalWindow"].remodal-is-opening').length;
    const length = lengthOpened + lengthOpening;
    assert.equal(length, 1);
  });

  test('it has a cancel button', async function(assert) {
    assert.expect(1);
    let { length } = findAll('[data-test-id="modalWindow"] [data-test-id="cancelButton"]');
    assert.equal(length, 1);
  });

  test('it has a confirm button', async function(assert) {
    assert.expect(1);
    let { length } = findAll('[data-test-id="modalWindow"] [data-test-id="confirmButton"]');
    assert.equal(length, 1);
  });

  test('it has a native close button', async function(assert) {
    assert.expect(1);
    let { length } = findAll('[data-test-id="modalWindow"] [data-test-id="nativeClose"]');
    assert.equal(length, 1);
  });
});
