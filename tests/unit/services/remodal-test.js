import Ember from 'ember';
import { moduleFor, test } from 'ember-qunit';

const {
  RSVP: { Promise },
  run
} = Ember;

moduleFor('service:remodal', 'Unit | Service | remodal', {
  // Specify the other units that are required for this test.
  // needs: ['service:foo']
});

const ModalMock = Ember.Object.extend({
  openCalled: false,
  closeCalled: false,

  open() {
    this.set('openCalled', true);
    return new Promise((resolve) => resolve(this));
  },

  close() {
    this.set('closeCalled', true);
  }
});

test('it exists', function(assert) {
  const service = this.subject();
  assert.ok(service);
});

test('if modal is not registered, open() calls "_modalNotSetError"', function(assert) {
  const service = this.subject();
  service.set('modalNotSetCalled', false);
  service.set('_modalNotSetError', () => service.set('modalNotSetCalled', true));

  assert.notOk(service.get('modalNotSetCalled'));
  run(() => service.open());
  assert.ok(service.get('modalNotSetCalled'));
});

test('if modal is not registered, close() calls "_modalNotSetError"', function(assert) {
  const service = this.subject();
  service.set('modalNotSetCalled', false);
  service.set('_modalNotSetError', () => service.set('modalNotSetCalled', true));

  assert.notOk(service.get('modalNotSetCalled'));
  run(() => service.close());
  assert.ok(service.get('modalNotSetCalled'));
});

test('"_modalNotSetError" throws an error', function(assert) {
  const service = this.subject();
  assert.throws(() => service._modalNotSetError('test'));
});

test("open() sets a random prop from 2nd param POJO onto 'modal'", function(assert) {
  const service = this.subject({ modal: ModalMock.create() });
  assert.notOk(service.get('modal.randomProp'));

  return run(() => {
    return service.open('modal', { randomProp: true }).then(() => {
      assert.ok(service.get('modal.randomProp'));
    });
  });
});

test('open() sets a random prop from 2nd param POJO onto named modal', function(assert) {
  const service = this.subject({ test: ModalMock.create() });
  assert.notOk(service.get('test.randomProp'));

  return run(() => {
    return service.open('test', { randomProp: true }).then(() => {
      assert.ok(service.get('test.randomProp'));
    });
  });
});

test("open() sets a supported prop from 2nd param POJO onto 'modal'", function(assert) {
  const service = this.subject({ modal: ModalMock.create() });
  assert.notOk(service.get('modal.disableForeground'));

  return run(() => {
    return service.open('modal', { disableForeground: true }).then(() => {
      assert.ok(service.get('modal.disableForeground'));
    });
  });
});

test('open() sets a supported prop from 2nd param POJO onto named modal', function(assert) {
  const service = this.subject({ test: ModalMock.create() });
  assert.notOk(service.get('test.disableForeground'));

  return run(() => {
    return service.open('test', { disableForeground: true }).then(() => {
      assert.ok(service.get('test.disableForeground'));
    });
  });
});

test("open() sends 'open' to 'modal'", function(assert) {
  const service = this.subject({ modal: ModalMock.create() });
  assert.notOk(service.get('modal.openCalled'));
  run(() => service.open());
  assert.ok(service.get('modal.openCalled'));
});

test("open() sends 'open' to named modal", function(assert) {
  const service = this.subject({ test: ModalMock.create() });
  assert.notOk(service.get('test.openCalled'));
  run(() => service.open('test'));
  assert.ok(service.get('test.openCalled'));
});

test("close() sends 'close' to 'modal'", function(assert) {
  const service = this.subject({ modal: ModalMock.create() });
  assert.notOk(service.get('modal.closeCalled'));
  run(() => service.close());
  assert.ok(service.get('modal.closeCalled'));
});

test("close() sends 'close' to named modal", function(assert) {
  const service = this.subject({ test: ModalMock.create() });
  assert.notOk(service.get('test.closeCalled'));
  run(() => service.close('test'));
  assert.ok(service.get('test.closeCalled'));
});
