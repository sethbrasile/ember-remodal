import Ember from 'ember';
import { moduleForComponent, test } from 'ember-qunit';

const {
  run,
  Component
} = Ember;

moduleForComponent('er-confirm-button', 'Unit | Component | er confirm button', {
  unit: true
});

test('it renders', function(assert) {
  let component = this.subject();
  component.set('_getModal', () => Component.create());

  this.render();
  assert.equal(this.$().text().trim(), '');
});

test('it calls "confirm" on "modal" from "click()"', function(assert) {
  let component = this.subject();
  component.set('_getModal', () => {
    return Component.extend({
      confirmCalled: false,
      actions: {
        confirm() {
          this.set('confirmCalled', true);
        }
      }
    }).create();
  });

  run(() => this.render());
  assert.notOk(component.get('modal.confirmCalled'));

  run(() => component.click());
  assert.ok(component.get('modal.confirmCalled'));
});
