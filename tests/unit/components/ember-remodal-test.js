import Ember from 'ember';
import { moduleForComponent, test } from 'ember-qunit';

moduleForComponent('ember-remodal', 'Unit | Component | ember remodal', {
  // Specify the other units that are required for this test
  // needs: ['component:foo', 'helper:bar'],
  unit: true
});

const ModalMock = Ember.Object.extend({
  closeCalled: false,
  openCalled: false,

  close() {
    this.set('closeCalled', true);
  },

  open() {
    this.set('openCalled', true);
  }
});

test('it renders', function(assert) {
  this.subject();
  this.render();
  assert.equal(this.$().text().trim(), '');
});

test('"open()" returns a promise', function(assert) {
  const component = this.subject({ disableAnimation: true });
  this.render();
  const modal = component.open();
  assert.ok(modal instanceof Ember.RSVP.Promise);
  modal.then(() => component.close());
});

test('"close()" returns a promise', function(assert) {
  const component = this.subject({ disableAnimation: true });
  this.render();
  component.open().then((modal) => {
    modal.close();
  });
  assert.ok(component.close() instanceof Ember.RSVP.Promise);
});

test('"confirm" action sends "onConfirm" action', function(assert) {
  const component = this.subject();
  component.set('onConfirmCalled', false);

  component.set('onConfirm', () => {
    component.set('onConfirmCalled', true);
  });

  component.set('actions.close', () => { /* no-op */ });

  this.render();

  assert.notOk(component.get('onConfirmCalled'));
  component.send('confirm');
  assert.ok(component.get('onConfirmCalled'));
});

test('"confirm" action sends "close" action', function(assert) {
  const component = this.subject();
  component.set('closeCalled', false);

  component.set('actions.close', () => {
    component.set('closeCalled', true);
  });

  this.render();

  assert.notOk(component.get('closeCalled'));
  component.send('confirm');
  assert.ok(component.get('closeCalled'));
});

test('"confirm" action does not send "close" action when "closeOnConfirm" is false', function(assert) {
  const component = this.subject();
  component.set('closeCalled', false);
  component.set('closeOnConfirm', false);

  component.set('actions.close', () => {
    component.set('closeCalled', true);
  });

  this.render();

  assert.notOk(component.get('closeCalled'));
  component.send('confirm');
  assert.notOk(component.get('closeCalled'));
});

test('"cancel" action sends "close" action', function(assert) {
  const component = this.subject();
  component.set('closeCalled', false);

  component.set('actions.close', () => {
    component.set('closeCalled', true);
  });

  this.render();

  assert.notOk(component.get('closeCalled'));
  component.send('cancel');
  assert.ok(component.get('closeCalled'));
});

test('"cancel" action does not send "close" action when "closeOnCancel" is false', function(assert) {
  const component = this.subject();
  component.set('closeCalled', false);
  component.set('closeOnCancel', false);

  component.set('actions.close', () => {
    component.set('closeCalled', true);
  });

  this.render();

  assert.notOk(component.get('closeCalled'));
  component.send('cancel');
  assert.notOk(component.get('closeCalled'));
});

test('"close" action sends "close" to "modal"', function(assert) {
  const component = this.subject();
  component.set('modal', ModalMock.create());

  this.render();

  assert.notOk(component.get('modal.closeCalled'));
  component.send('close');
  assert.ok(component.get('modal.closeCalled'));
});

test('"open" action sends "open" to "modal"', function(assert) {
  const component = this.subject();
  component.set('modal', ModalMock.create());

  this.render();

  assert.notOk(component.get('modal.openCalled'));
  component.send('open');
  assert.ok(component.get('modal.openCalled'));
});
