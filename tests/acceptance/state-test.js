import { test } from 'qunit';
import moduleForAcceptance from '../../tests/helpers/module-for-acceptance';

moduleForAcceptance('Acceptance | state');

test('user can visit /state', function(assert) {
  assert.expect(1);

  visit('/state');

  andThen(function() {
    assert.equal(currentURL(), '/state');
  });
});

test('"simple" state1 works', function(assert) {
  assert.expect(1);

  visit('/state');

  click('[data-test-id="state-1"]');

  andThen(function() {
    let state = find('[data-test-id="modalWindow"] [data-test-id="state-text"]');
    assert.equal(state.text(), 'state 1');
  });
});

test('"simple" state2 works', function(assert) {
  assert.expect(1);

  visit('/state');

  click('[data-test-id="state-2"]');

  andThen(function() {
    let state = find('[data-test-id="modalWindow"] [data-test-id="state-text"]');
    assert.equal(state.text(), 'state 2');
  });
});

test('"complex" setting initial state works', function(assert) {
  assert.expect(1);

  visit('/state/complex');

  click('[data-test-id="Moose"]');

  andThen(function() {
    let state = find('[data-test-id="modalWindow"] [data-test-id="dog-name"]');
    assert.equal(state.text(), 'Moose');
  });
});

test('"complex" setting initial state then selecting another works', function(assert) {
  assert.expect(2);

  visit('/state/complex');

  click('[data-test-id="Moose"]');

  andThen(function() {
    let state = find('[data-test-id="modalWindow"] [data-test-id="dog-name"]');
    assert.equal(state.text(), 'Moose');
  });

  click('[data-test-id="Buttons"]');

  andThen(function() {
    let state = find('[data-test-id="modalWindow"] [data-test-id="dog-name"]');
    assert.equal(state.text(), 'Buttons');
  });
});
