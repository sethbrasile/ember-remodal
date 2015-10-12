import { moduleForComponent, test } from 'ember-qunit';
import hbs from 'htmlbars-inline-precompile';
import Ember from 'ember';

moduleForComponent('ember-remodal', 'Integration | Component | ember remodal', {
  integration: true
});

test('it works by clicking the provided button', function(assert) {
  assert.expect(2);

  this.render(hbs`{{ember-remodal openLabel='open' onOpen='open'}}`);

  this.on('open', () => {
    Ember.run.later('render', () => $('.remodal-wrapper').click(), 1000);
  });

  const modal = this.$('[data-test-id="modal"]');
  const open = this.$('[data-test-id="openLabel"]');

  assert.equal(modal.attr('data-is-open'), 'false');

  Ember.run(() => open.click());

  assert.equal(modal.attr('data-is-open'), 'true');
});

test('it works by setting showModal to true', function(assert) {
  assert.expect(2);

  this.set('showModal', false);

  this.render(hbs`{{ember-remodal showModal=showModal onOpen='open'}}`);

  this.on('open', () => {
    Ember.run.later('render', () => $('.remodal-wrapper').click(), 1000);
  });

  const modal = this.$('[data-test-id="modal"]');

  assert.equal(modal.attr('data-is-open'), 'false');

  this.set('showModal', true);

  assert.equal(modal.attr('data-is-open'), 'true');
});

test('the cancel button closes the modal', function(assert) {
  assert.expect(3);

  this.render(hbs`{{ember-remodal openLabel='open' cancelLabel='cancel' onOpen='open'}}`);

  const cancel = this.$('[data-test-id="cancelLabel"]');
  const modal = this.$('[data-test-id="modal"]');
  const open = this.$('[data-test-id="openLabel"]');

  assert.equal(modal.attr('data-is-open'), 'false');

  this.on('open', () => {
    Ember.run.later('render', () => cancel.click(), 1000);
    assert.equal(modal.attr('data-is-open'), 'false');
  });

  Ember.run(() => open.click());

  assert.equal(modal.attr('data-is-open'), 'true');
});
