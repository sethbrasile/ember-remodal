import Ember from 'ember';
import { moduleForComponent, test } from 'ember-qunit';

const {
  RSVP: { Promise },
  run,
  run: { next }
} = Ember;

moduleForComponent('ember-remodal', 'Unit | Component | ember remodal', {
  // Specify the other units that are required for this test
  // needs: ['component:foo', 'helper:bar'],
  unit: true
});

const ModalMock = Ember.Object.extend({
  openCalled: false,
  closeCalled: false,

  open() {
    this.set('openCalled', true);
  },

  close() {
    this.set('closeCalled', true);
  }
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
    let component = this.subject({ disableAnimation: true });
    this.render();
    assert.ok(component.open() instanceof Promise);
  });
});

test('"close()" returns a promise', function(assert) {
  assert.expect(1);

  return run(() => {
    let component = this.subject({ disableAnimation: true });
    this.render();

    return component.open().then((modal) => {
      assert.ok(modal.close() instanceof Promise);
    });
  });
});

test('if "modal" exists, "open" action calls "open()" on "modal"', function(assert) {
  assert.expect(2);

  run(() => {
    let component = this.subject({ modal: ModalMock.create() });

    this.render();

    assert.notOk(component.get('modal.openCalled'));
    run(() => component.send('open'));
    run(() => assert.ok(component.get('modal.openCalled')));
  });
});

test('if "modal" exists, "open" action calls "_openModal"', function(assert) {
  assert.expect(2);

  run(() => {
    let component = this.subject({
      _openModalCalled: false,
      modal: ModalMock.create(),

      _openModal() {
        this.set('_openModalCalled', true);
      }
    });

    this.render();

    assert.notOk(component.get('_openModalCalled'));
    run(() => component.send('open'));
    run(() => assert.ok(component.get('_openModalCalled')));
  });
});

test('if "modal" does not exist, "open" action calls "_createInstanceAndOpen"', function(assert) {
  assert.expect(2);

  run(() => {
    let component = this.subject({
      methodCalled: false,

      _createInstanceAndOpen() {
        this.set('methodCalled', true);
      }
    });

    this.render();

    assert.notOk(component.get('methodCalled'));
    run(() => component.send('open'));
    run(() => assert.ok(component.get('methodCalled')));
  });
});

test('if "modal" does not exist, "open" action calls "_createInstanceAndOpen"', function(assert) {
  assert.expect(2);

  run(() => {
    let component = this.subject({
      methodCalled: false,

      _createInstanceAndOpen() {
        this.set('methodCalled', true);
      }
    });

    this.render();

    assert.notOk(component.get('methodCalled'));
    run(() => component.send('open'));
    run(() => assert.ok(component.get('methodCalled')));
  });
});

test('_openModal calls "open" on "modal"', function(assert) {
  assert.expect(2);

  run(() => {
    let component = this.subject({ modal: ModalMock.create() });

    this.render();

    assert.notOk(component.get('modal.openCalled'));
    run(() => component._openModal());
    run(() => assert.ok(component.get('modal.openCalled')));
  });
});

test('_closeModal calls "close" on "modal"', function(assert) {
  assert.expect(2);

  run(() => {
    let component = this.subject({ modal: ModalMock.create() });

    this.render();

    assert.notOk(component.get('modal.closeCalled'));
    run(() => component._closeModal());
    run(() => assert.ok(component.get('modal.closeCalled')));
  });
});

test('"confirm" action sends "onConfirm" action', function(assert) {
  assert.expect(2);

  run(() => {
    let component = this.subject({ modal: ModalMock.create() });
    component.set('onConfirmCalled', false);

    component.set('onConfirm', () => {
      component.set('onConfirmCalled', true);
    });

    this.render();

    assert.notOk(component.get('onConfirmCalled'));
    component.send('confirm');
    assert.ok(component.get('onConfirmCalled'));
  });
});

test('"confirm" action sends "_closeModal" action', function(assert) {
  assert.expect(2);

  run(() => {
    let component = this.subject({
      closeModalCalled: false,

      _closeModal() {
        this.set('_closeModalCalled', true);
      }
    });

    this.render();

    assert.notOk(component.get('_closeModalCalled'));
    run(() => component.send('confirm'));
    next(() => assert.ok(component.get('_closeModalCalled')));
  });
});

test('"confirm" action does not send "close" action when "closeOnConfirm" is false', function(assert) {
  assert.expect(2);

  run(() => {
    let component = this.subject({
      closeOnConfirm: false,
      closeModalCalled: false,

      _closeModal() {
        this.set('_closeModalCalled', true);
      }
    });

    this.render();

    assert.notOk(component.get('_closeModalCalled'));

    run(() => component.send('confirm'));
    next(() => assert.notOk(component.get('_closeModalCalled')));
  });
});

test('"cancel" action sends "close" action', function(assert) {
  assert.expect(2);

  run(() => {
    let component = this.subject({
      closeModalCalled: false,

      _closeModal() {
        this.set('_closeModalCalled', true);
      }
    });

    this.render();

    assert.notOk(component.get('_closeModalCalled'));
    run(() => component.send('cancel'));
    next(() => assert.ok(component.get('_closeModalCalled')));
  });
});

test('"cancel" action does not send "close" action when "closeOnCancel" is false', function(assert) {
  assert.expect(2);

  run(() => {
    let component = this.subject({
      closeOnCancel: false,
      closeModalCalled: false,

      _closeModal() {
        this.set('_closeModalCalled', true);
      }
    });

    this.render();

    assert.notOk(component.get('_closeModalCalled'));
    run(() => component.send('cancel'));
    next(() => assert.notOk(component.get('_closeModalCalled')));
  });
});
