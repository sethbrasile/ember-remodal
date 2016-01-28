import Ember from 'ember';
import ErButtonMixin from 'ember-remodal/mixins/er-button';
import { module, test } from 'qunit';

module('Unit | Mixin | er button');

const ErButtonObject = Ember.Object.extend(ErButtonMixin, {
  name: 'test-name',
  _assertModalIsNested() {}
});

test('it works', function(assert) {
  let ErButtonObject = Ember.Object.extend(ErButtonMixin);
  let subject = ErButtonObject.create();
  assert.ok(subject);
});

test('it calls "_registerWithModal" on didRender', function(assert) {
  const thing = ErButtonObject.create();
  thing.set('registerCalled', false);
  thing.set('_registerWithModal', () => thing.set('registerCalled', true));

  Ember.run(() => thing.didRender());
  assert.ok(thing.get('registerCalled'));
});

test('"_registerWithModal" calls "_getModal"', function(assert) {
  const mixin = ErButtonObject.create();
  mixin.set('getModalCalled', false);
  mixin.set('_getModal', () => {
    mixin.set('getModalCalled', true);
    return Ember.Object.create();
  });

  Ember.run(() => {
    assert.notOk(mixin.get('getModalCalled'));
    mixin._registerWithModal();
    assert.ok(mixin.get('getModalCalled'));
  });
});

test('"_registerWithModal" properly sets the button\'s name on the modal', function(assert) {
  const mixin = ErButtonObject.create();

  mixin.set('_getModal', () => Ember.Object.create());

  Ember.run(() => {
    assert.notOk(mixin.get('modal.testName'));
    mixin._registerWithModal();
    assert.ok(mixin.get('modal.testName'));
  });
});

test('"_registerWithModal" throws an error when modal is not set', function(assert) {
  const mixin = ErButtonObject.create();
  mixin.set('getModalCalled', false);
  mixin.set('_getModal', () => {
    mixin.set('getModalCalled', true);
    return null;
  });

  Ember.run(() => {
    assert.throws(mixin._registerWithModal);
  });
});
