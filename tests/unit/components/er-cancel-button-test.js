import Ember from 'ember';
import { moduleForComponent, test } from 'ember-qunit';

moduleForComponent('er-cancel-button', 'Unit | Component | er cancel button', {
  unit: true
});

test('it renders', function(assert) {
  let component = this.subject();
  component.set('_getModal', () => Ember.Object.create());

  this.render();
  assert.equal(this.$().text().trim(), '');
});

test('it calls "cancel" on "modal" from "click()"', function(assert) {
  let component = this.subject();
  component.set('_getModal', () => {
    return Ember.Component.extend({
      cancelCalled: false,
      actions: {
        cancel() {
          this.set('cancelCalled', true);
        }
      }
    }).create();
  });

  Ember.run(() => this.render());
  assert.notOk(component.get('modal.cancelCalled'));

  Ember.run(() => component.click());
  assert.ok(component.get('modal.cancelCalled'));
});
