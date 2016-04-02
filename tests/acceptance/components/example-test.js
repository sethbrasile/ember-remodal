import { test } from 'qunit';
import moduleForAcceptance from '../../../tests/helpers/module-for-acceptance';

moduleForAcceptance('Acceptance | components/example', {
  beforeEach() {
    visit('/components/example');

    andThen(function() {
      click(this.$('[data-test-id="modal"] [data-test-id="openButton"]'));
    });
  }
});

test('visiting /components/example', function(assert) {
  assert.equal(currentURL(), '/components/example');
});

test('it opens', function(assert) {
  assert.expect(1);

  andThen(function() {
    let length = this.$('[data-test-id="modalWindow"].remodal-is-opened').length || this.$('[data-test-id="modalWindow"].remodal-is-opening').length;
    assert.equal(length, 1);
  });
});

test('it has a cancel button', function(assert) {
  assert.expect(1);

  andThen(function() {
    let length = this.$('[data-test-id="modalWindow"].remodal-is-opened [data-test-id="cancelButton"]').length || this.$('[data-test-id="modalWindow"].remodal-is-opening [data-test-id="cancelButton"]').length;
    assert.equal(length, 1);
  });
});

test('it has a confirm button', function(assert) {
  assert.expect(1);

  andThen(function() {
    let length = this.$('[data-test-id="modalWindow"].remodal-is-opened [data-test-id="confirmButton"]').length || this.$('[data-test-id="modalWindow"].remodal-is-opening [data-test-id="confirmButton"]').length;
    assert.equal(length, 1);
  });
});

test('it has a native close button', function(assert) {
  assert.expect(1);

  andThen(function() {
    let length = this.$('[data-test-id="modalWindow"].remodal-is-opened [data-test-id="nativeClose"]').length || this.$('[data-test-id="modalWindow"].remodal-is-opening [data-test-id="nativeClose"]').length;
    assert.equal(length, 1);
  });
});
