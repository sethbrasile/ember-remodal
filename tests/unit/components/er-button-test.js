import { moduleForComponent, test } from 'ember-qunit';
import Ember from 'ember';

const {
  run
} = Ember;

moduleForComponent('er-button', 'Unit | Component | er button', {
  // Specify the other units that are required for this test
  needs: ['component:ember-wormhole'],
  unit: true
});

test('it renders', function(assert) {

  // Creates the component instance
  /*let component =*/ this.subject();
  // Renders the component to the page
  this.render();
  assert.equal(this.$().text().trim(), '');
});

test('"destination" is undefined when modalId is not set', function(assert) {
  let component = this.subject();
  this.render();

  assert.notOk(component.get('destination'));
});

test('"destination" exists when modalId is set', function(assert) {
  let component = this.subject();

  run(() => this.$().append('<div id="open-button-test"></div>'));
  run(() => component.set('modalId', 'test'));

  this.render();

  assert.ok(component.get('destination'));
});

test('"destination" is correct when modalId is set', function(assert) {
  let component = this.subject();

  run(() => this.$().append('<div id="open-button-test"></div>'));
  run(() => component.set('modalId', 'test'));

  this.render();

  assert.equal(component.get('destination'), 'open-button-test');
});
