import Ember from 'ember';
import { moduleForComponent, test } from 'ember-qunit';

moduleForComponent('er-open-button', 'Unit | Component | er open button', {
  needs: ['component:ember-wormhole'],
  unit: true
});

test('it renders', function(assert) {
  let component = this.subject();
  component.set('_getModal', () => Ember.Object.create());

  this.render();
  assert.equal(this.$().text().trim(), '');
});

test('it properly sets "destination"', function(assert) {
  let component = this.subject();
  component.set('_getModal', () => Ember.Object.create({ elementId: 1 }));

  Ember.run(() => {
    // This will throw a "not in dom" error from ember-wormhole
    assert.throws(() => this.render());
    assert.equal(component.get('destination'), 'open-button-1');
  });
});
