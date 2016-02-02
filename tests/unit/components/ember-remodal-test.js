import Ember from 'ember';
import { moduleForComponent, test } from 'ember-qunit';

const {
  RSVP: { Promise },
  run
} = Ember;

moduleForComponent('ember-remodal', 'Unit | Component | ember remodal', {
  // Specify the other units that are required for this test
  // needs: ['component:foo', 'helper:bar'],
  unit: true
});

test('it renders', function(assert) {
  assert.expect(1);

  run(() => {
    this.subject();
    this.render();
    assert.equal(this.$().text().trim(), '');
  });
});

test('"open()" returns a promise', function(assert) {
  assert.expect(1);

  run(() => {
    const component = this.subject({ disableAnimation: true });
    this.render();
    assert.ok(component.open() instanceof Promise);
  });
});

test('"close()" returns a promise', function(assert) {
  assert.expect(1);

  return run(() => {
    const component = this.subject({ disableAnimation: true });
    this.render();

    return component.open().then((modal) => {
      assert.ok(modal.close() instanceof Promise);
    });
  });
});

test('"confirm" action sends "onConfirm" action', function(assert) {
  assert.expect(2);

  run(() => {
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
});

test('"confirm" action sends "close" action', function(assert) {
  assert.expect(2);

  run(() => {
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
});

test('"confirm" action does not send "close" action when "closeOnConfirm" is false', function(assert) {
  assert.expect(2);

  run(() => {
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
});

test('"cancel" action sends "close" action', function(assert) {
  assert.expect(2);

  run(() => {
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
});

test('"cancel" action does not send "close" action when "closeOnCancel" is false', function(assert) {
  assert.expect(2);

  run(() => {
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
});
