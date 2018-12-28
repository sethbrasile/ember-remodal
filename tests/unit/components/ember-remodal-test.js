import EmberObject from '@ember/object';
import { Promise } from 'rsvp';
import { next, run } from '@ember/runloop';
import { moduleForComponent, test } from 'ember-qunit';

moduleForComponent('ember-remodal', 'Unit | Component | ember remodal', {
  // Specify the other units that are required for this test
  needs: ['service:remodal'],
  unit: true
});

const ModalMock = EmberObject.extend({
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

test('"_promiseAction()" returns a promise', function(assert) {
  assert.expect(1);

  run(() => {
    let component = this.subject({ disableAnimation: true });
    this.render();
    assert.ok(component._promiseAction('open') instanceof Promise);
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

test('"_pastTense" works', function(assert) {
  assert.expect(2);

  run(() => {
    let component = this.subject();
    this.render();
    assert.equal(component._pastTense('close'), 'closed');
    assert.equal(component._pastTense('open'), 'opened');
  });
});

test('options are set from the options hash', function(assert) {
  assert.expect(1);

  run(() => {
    let component = this.subject({
      options: { testingTesting: 123 }
    });

    this.render();
    assert.equal(component.get('testingTesting'), 123);
  });
});

test('if "forService" is true, "this" is set as "name" on the remodal service', function(assert) {
  assert.expect(1);
  const remodal = EmberObject.create();

  run(() => {
    let component = this.subject({ remodal, forService: true });

    this.render();
    assert.deepEqual(remodal.get('ember-remodal'), component);
  });
});

test('"_destroyDomElements" calls "destroy" on "modal"', function(assert) {
  assert.expect(2);

  run(() => {
    let component = this.subject({
      modal: EmberObject.create({
        destroyCalled: false,
        destroy() {
          this.set('destroyCalled', true);
        }
      })
    });

    this.render();

    assert.notOk(component.get('modal.destroyCalled'));
    component._destroyDomElements();
    assert.ok(component.get('modal.destroyCalled'));
  });
});

test('"_checkForTestingEnv" is called on "didInsertElement"', function(assert) {
  assert.expect(2);

  run(() => {
    let component = this.subject({
      checkForTestingCalled: false,
      _checkForTestingEnv() {
        this.set('checkForTestingCalled', true);
      }
    });

    assert.notOk(component.get('checkForTestingCalled'));
    this.render();
    assert.ok(component.get('checkForTestingCalled'));
  });
});

test('"_checkForTestingEnv" sets "disableAnimation" to true when "disableAnimationWhileTesting" is true in config', function(assert) {
  assert.expect(2);

  let component = this.subject();

  component.set('_getConfig', () => {
    return {
      environment: 'test',
      'ember-remodal': {
        disableAnimationWhileTesting: true
      }
    };
  });

  assert.notOk(component.get('disableAnimation'));
  component._checkForTestingEnv();
  assert.ok(component.get('disableAnimation'));
});

test('"_checkForTestingEnv" leaves "disableAnimation" alone when "disableAnimationWhileTesting" is false/undefined in config', function(assert) {
  assert.expect(2);

  let component = this.subject();

  component.set('_getConfig', () => {
    return {
      environment: 'test',
      'ember-remodal': {
        disableAnimationWhileTesting: false
      }
    };
  });

  assert.notOk(component.get('disableAnimation'));
  component._checkForTestingEnv();
  assert.notOk(component.get('disableAnimation'));
});

test('"_checkForTestingEnv" leaves "disableAnimation" alone when environment is not "test"', function(assert) {
  assert.expect(2);

  let component = this.subject();

  component.set('_getConfig', () => {
    return {
      environment: 'development',
      'ember-remodal': {
        disableAnimationWhileTesting: true
      }
    };
  });

  assert.notOk(component.get('disableAnimation'));
  component._checkForTestingEnv();
  assert.notOk(component.get('disableAnimation'));
});

test('"_checkForTestingEnv" leaves "disableAnimation" alone when environment is not "test" and "disableAnimation" was manually set to "true"', function(assert) {
  assert.expect(2);

  let component = this.subject({ disableAnimation: true });

  component.set('_getConfig', () => {
    return {
      environment: 'development',
      'ember-remodal': {
        disableAnimationWhileTesting: true
      }
    };
  });

  assert.ok(component.get('disableAnimation'));
  component._checkForTestingEnv();
  assert.ok(component.get('disableAnimation'));
});
