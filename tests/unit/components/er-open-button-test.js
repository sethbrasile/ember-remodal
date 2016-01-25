import Ember from 'ember';
import { moduleForComponent, test } from 'ember-qunit';

const {
  run,
  Component
} = Ember;

moduleForComponent('er-open-button', 'Unit | Component | er open button', {
  unit: true,

  beforeEach() {
    this.register('component:ember-wormhole', Component.extend());
  }
});

test('it renders', function(assert) {
  let component = this.subject();
  component.set('_getModal', () => Component.create());

  this.render();
  assert.equal(this.$().text().trim(), '');
});

test('it properly sets "destination"', function(assert) {
  let component = this.subject();
  component.set('_getModal', () => Component.create({ elementId: 1 }));

  run(() => {
    this.render();
    assert.equal(component.get('destination'), 'open-button-1');
  });
});
