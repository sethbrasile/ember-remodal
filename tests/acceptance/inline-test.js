import { module, test } from 'qunit';
import { setupApplicationTest } from 'ember-qunit';
import { visit, currentURL, click, findAll } from '@ember/test-helpers';

module('Acceptance | simple inline modal', function(hooks) {
  setupApplicationTest(hooks);

  hooks.beforeEach(async function() {
    await visit('/inline');
    click('[data-test-id="simple-inline"] [data-test-id="openButton"]');
  });

  test("visiting '/inline'", function(assert) {
    assert.equal(currentURL(), '/inline');
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
