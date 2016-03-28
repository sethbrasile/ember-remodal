import { test } from 'qunit';
import moduleForAcceptance from '../../tests/helpers/module-for-acceptance';

moduleForAcceptance('Acceptance | simple inline modal', {
  beforeEach() {
    visit('/inline');

    andThen(function() {
      click(this.$('[data-test-id="simple-inline"] [data-test-id="openButton"]'));
    });
  }
});

test('visiting /inline', function(assert) {
  assert.equal(currentURL(), '/inline');
});

test('it opens', function(assert) {
  assert.expect(1);

  andThen(function() {
    let length = this.$('[data-test-id="modalWindow"].remodal-is-opened').length || this.$('[data-test-id="modalWindow"].remodal-is-opening').length;
    assert.equal(length, 1);
  });

  andThen(function() {
    click(this.$('.remodal-wrapper'));
  });
});

test('it has a cancel button', function(assert) {
  assert.expect(1);

  andThen(function() {
    let length = this.$('[data-test-id="modalWindow"].remodal-is-opened [data-test-id="cancelButton"]').length || this.$('[data-test-id="modalWindow"].remodal-is-opening [data-test-id="cancelButton"]').length;
    assert.equal(length, 1);
  });

  andThen(function() {
    click(this.$('.remodal-wrapper'));
  });
});

test('it has a confirm button', function(assert) {
  assert.expect(1);

  andThen(function() {
    let length = this.$('[data-test-id="modalWindow"].remodal-is-opened [data-test-id="confirmButton"]').length || this.$('[data-test-id="modalWindow"].remodal-is-opening [data-test-id="confirmButton"]').length;
    assert.equal(length, 1);
  });

  andThen(function() {
    click(this.$('.remodal-wrapper'));
  });
});

test('it has a native close button', function(assert) {
  assert.expect(1);

  andThen(function() {
    let length = this.$('[data-test-id="modalWindow"].remodal-is-opened [data-test-id="nativeClose"]').length || this.$('[data-test-id="modalWindow"].remodal-is-opening [data-test-id="nativeClose"]').length;
    assert.equal(length, 1);
  });

  andThen(function() {
    click(this.$('.remodal-wrapper'));
  });
});
