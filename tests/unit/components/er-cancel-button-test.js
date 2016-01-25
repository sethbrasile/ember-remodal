import Ember from 'ember';
import { moduleForComponent, test } from 'ember-qunit';

const {
  run,
  Component
} = Ember;

moduleForComponent('er-cancel-button', 'Unit | Component | er cancel button', {
  unit: true
});

test('it renders', function(assert) {
  let component = this.subject();
  component.set('_getModal', () => Component.create());

  this.render();
  assert.equal(this.$().text().trim(), '');
});

test('it calls "cancel" on "modal" from "click()"', function(assert) {
  let component = this.subject();
  component.set('_getModal', () => {
    return Component.extend({
      cancelCalled: false,
      actions: {
        cancel() {
          this.set('cancelCalled', true);
        }
      }
    }).create();
  });

  run(() => this.render());
  assert.notOk(component.get('modal.cancelCalled'));

  run(() => component.click());
  assert.ok(component.get('modal.cancelCalled'));
});
