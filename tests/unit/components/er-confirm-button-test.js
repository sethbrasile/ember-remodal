import { moduleForComponent, test } from 'ember-qunit';

moduleForComponent('er-confirm-button', 'Unit | Component | er confirm button', {
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
      confirmCalled: false,
      actions: {
        confirm() {
          this.set('confirmCalled', true);
        }
      }
    }).create();
  });

  Ember.run(() => this.render());
  assert.notOk(component.get('modal.confirmCalled'));

  Ember.run(() => component.click());
  assert.ok(component.get('modal.confirmCalled'));
});
