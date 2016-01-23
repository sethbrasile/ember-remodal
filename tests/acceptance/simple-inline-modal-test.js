import Ember from 'ember';
import { test } from 'qunit';
import moduleForAcceptance from '../../tests/helpers/module-for-acceptance';

moduleForAcceptance('Acceptance | simple inline modal', {
  beforeEach() {
    visit('/');

    andThen(function() {
      click(this.$('[data-test-id="simple-inline"] [data-test-id="openButton"]'));
    });
  }
});

test('it opens', function(assert) {
  assert.expect(1);

  andThen(function() {
    assert.ok(this.$('[data-test-id="modalWindow"].remodal-is-opened').length);
  });

  andThen(function() {
    click(this.$('.remodal-wrapper'));
  });
});

test('it has a cancel button', function(assert) {
  assert.expect(1);

  andThen(function() {
    assert.ok(this.$('[data-test-id="modalWindow"].remodal-is-opened [data-test-id="cancelButton"]').length);
  });

  andThen(function() {
    click(this.$('.remodal-wrapper'));
  });
});

test('it has a confirm button', function(assert) {
  assert.expect(1);

  andThen(function() {
    assert.ok(this.$('[data-test-id="modalWindow"].remodal-is-opened [data-test-id="confirmButton"]').length);
  });

  andThen(function() {
    click(this.$('.remodal-wrapper'));
  });
});

test('it has a native close button', function(assert) {
  assert.expect(1);

  andThen(function() {
    assert.ok(this.$('[data-test-id="modalWindow"].remodal-is-opened [data-test-id="nativeClose"]').length);
  });

  andThen(function() {
    click(this.$('.remodal-wrapper'));
  });
});
