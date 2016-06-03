import { test } from 'qunit';
import moduleForAcceptance from '../../tests/helpers/module-for-acceptance';

moduleForAcceptance('Acceptance | state');

test('user van visit /state', function(assert) {
  visit('/state');

  andThen(function() {
    assert.equal(currentURL(), '/state');
  });
});

test('state1 works', function(assert) {
  visit('/state');

  click('[data-test-id="state-1"]');

  andThen(function() {
    let state = $('[data-test-id="modalWindow"] [data-test-id="state-text"]');
    assert.equal(state.text(), 'state 1');
  });
});

test('state2 works', function(assert) {
  visit('/state');

  click('[data-test-id="state-2"]');

  andThen(function() {
    let state = $('[data-test-id="modalWindow"] [data-test-id="state-text"]');
    assert.equal(state.text(), 'state 2');
  });
});
