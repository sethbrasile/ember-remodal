import { module, test } from 'qunit';
import { setupApplicationTest } from 'ember-qunit';
import { visit, currentURL, click } from '@ember/test-helpers';
import $ from 'jquery';

module('Acceptance | state', function(hooks) {
  setupApplicationTest(hooks);

  test('user can visit /state', async function(assert) {
    assert.expect(1);
    await visit('/state');
    assert.equal(currentURL(), '/state');
  });

  test('"simple" state1 works', async function(assert) {
    assert.expect(1);
    await visit('/state');
    await click('[data-test-id="state-1"]');
    let state = $('[data-test-id="modalWindow"] [data-test-id="state-text"]');
    assert.equal(state.text(), 'state 1');
  });

  test('"simple" state2 works', async function(assert) {
    assert.expect(1);
    await visit('/state');
    await click('[data-test-id="state-2"]');
    let state = $('[data-test-id="modalWindow"] [data-test-id="state-text"]');
    assert.equal(state.text(), 'state 2');
  });

  test('"complex" setting initial state works', async function(assert) {
    assert.expect(1);
    await visit('/state/complex');
    await click('[data-test-id="Moose"]');
    let state = $('[data-test-id="modalWindow"] [data-test-id="dog-name"]');
    assert.equal(state.text(), 'Moose');
  });

  test('"complex" setting initial state then selecting another works', async function(assert) {
    await assert.expect(2);
    await visit('/state/complex');
    await click('[data-test-id="Moose"]');
    let state = $('[data-test-id="modalWindow"] [data-test-id="dog-name"]');
    assert.equal(state.text(), 'Moose');
    await click('[data-test-id="Buttons"]');
    state = $('[data-test-id="modalWindow"] [data-test-id="dog-name"]');
    assert.equal(state.text(), 'Buttons');
  });
});
