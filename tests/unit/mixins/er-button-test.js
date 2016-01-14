import Ember from 'ember';
import ErButtonMixin from 'ember-remodal/mixins/er-button';
import { module, test } from 'qunit';

module('Unit | Mixin | er button');

// Replace this with your real tests.
test('it works', function(assert) {
  let ErButtonObject = Ember.Object.extend(ErButtonMixin);
  let subject = ErButtonObject.create();
  assert.ok(subject);
});
