import { test } from 'qunit';
import moduleForAcceptance from '../../tests/helpers/module-for-acceptance';

moduleForAcceptance('Acceptance | simple inline modal', {
  beforeEach() {
    visit('/inline');

    andThen(function() {
      click('[data-test-id="simple-inline"] [data-test-id="openButton"]');
    });
  }
});

test('visiting /inline', function(assert) {
  assert.equal(currentURL(), '/inline');
});

test('it opens', function(assert) {
  assert.expect(1);
  let length = find('[data-test-id="modalWindow"].remodal-is-opened').length || find('[data-test-id="modalWindow"].remodal-is-opening').length;

  andThen(function() {
    assert.equal(length, 1);
  });
});

test('it has a cancel button', function(assert) {
  assert.expect(1);
  let { length } = find('[data-test-id="modalWindow"] [data-test-id="cancelButton"]');

  andThen(function() {
    assert.equal(length, 1);
  });
});

test('it has a confirm button', function(assert) {
  assert.expect(1);
  let { length } = find('[data-test-id="modalWindow"] [data-test-id="confirmButton"]');

  andThen(function() {
    assert.equal(length, 1);
  });
});

test('it has a native close button', function(assert) {
  assert.expect(1);
  let { length } = find('[data-test-id="modalWindow"] [data-test-id="nativeClose"]');

  andThen(function() {
    assert.equal(length, 1);
  });
});
