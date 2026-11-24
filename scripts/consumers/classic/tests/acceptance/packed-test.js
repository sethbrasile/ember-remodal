import Ember from 'ember';
import { VERSION } from '@ember/version';
import $ from 'jquery';
import { run } from '@ember/runloop';
import { Promise } from 'rsvp';
import { test } from 'qunit';
import moduleForAcceptance from '../helpers/module-for-acceptance';
// Written by scripts/test-consumer.sh for the consumer being run.
import expected from '../helpers/expected';

const TRIGGER = '[id^=open-button-]';
const TITLE = '.remodal-is-opened [data-test-id=title]';
const NATIVE_CLOSE = '[data-test-id=nativeClose]';

function registeredVersion() {
  let library = Ember.libraries._registry.filter((entry) => entry.name === 'Ember Remodal')[0];
  return library && library.version;
}

// remodal reaches its opened and closed states when its CSS animations end,
// which the acceptance helpers do not wait for.
function waitUntil(condition, description) {
  return new Promise((resolve, reject) => {
    let started = Date.now();
    let timer = setInterval(() => {
      if (condition()) {
        clearInterval(timer);
        run(null, resolve);
      } else if (Date.now() - started > 5000) {
        clearInterval(timer);
        run(null, reject, new Error(`Timed out waiting until ${description}`));
      }
    }, 10);
  });
}

function lookupService(application) {
  return application.__container__.lookup('service:remodal');
}

moduleForAcceptance('Acceptance | packed ember-remodal');

test('the browser runs the versions this consumer names', function(assert) {
  assert.expect(3);
  assert.strictEqual(VERSION, expected.ember, 'Ember');
  assert.strictEqual($.fn.jquery, expected.jquery, 'jQuery');
  assert.strictEqual(registeredVersion(), expected.remodal, 'ember-remodal');
});

test('the yielded trigger opens the modal and the native close button closes it', function(assert) {
  assert.expect(5);
  visit('/');
  andThen(() => {
    assert.strictEqual(find(TRIGGER).text().trim(), 'Show packed modal', 'the yielded trigger rendered its block');
    assert.strictEqual(find(TITLE).length, 0, 'the modal starts closed');
    click(TRIGGER);
  });
  andThen(() => waitUntil(() => find(TITLE).length === 1, 'the trigger opens the modal'));
  andThen(() => {
    assert.strictEqual(find(TITLE).text().trim(), 'Packed modal', 'the trigger opened the modal');
    assert.strictEqual(find(NATIVE_CLOSE).attr('title'), 'Close Modal', 'the native close button is named');
    click(NATIVE_CLOSE);
  });
  andThen(() => waitUntil(() => find(TITLE).length === 0, 'the native close button closes the modal'));
  andThen(() => {
    assert.strictEqual(find(TITLE).length, 0, 'the native close button closed the modal');
  });
});

test('the service opens and closes the modal', function(assert) {
  assert.expect(5);
  visit('/');
  andThen(() => {
    let done = assert.async();
    let service = lookupService(this.application);
    let component = service.get('ember-remodal');
    assert.ok(component, 'the rendered modal registered itself on the service');

    service.open().then((opened) => {
      assert.strictEqual(opened, component, 'open() resolves to the component');
      assert.strictEqual(find(TITLE).text().trim(), 'Packed modal', 'open() opened the modal');
      return service.close();
    }).then((closed) => {
      assert.strictEqual(closed, component, 'close() resolves to the component');
      assert.strictEqual(find(TITLE).length, 0, 'close() closed the modal');
    }).finally(done);
  });
});

test('closing through the service before opening resolves to the component', function(assert) {
  assert.expect(3);
  visit('/');
  andThen(() => {
    let done = assert.async();
    let service = lookupService(this.application);
    let component = service.get('ember-remodal');
    assert.ok(component, 'the rendered modal registered itself on the service');
    assert.notOk(component.get('modal'), 'the modal has never been opened');

    service.close().then((result) => {
      assert.strictEqual(result, component, 'close() resolves to the component');
    }).finally(done);
  });
});
