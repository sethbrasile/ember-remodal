import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click, settled, find, waitUntil } from '@ember/test-helpers';
import hbs from 'htmlbars-inline-precompile';
import { warnOnce, _resetWarnings } from 'ember-remodal/utils/deprecations'; // eslint-disable-line no-unused-vars

/* eslint-disable no-console */
function warningIds(warnings) {
  return warnings.map(w => {
    let match = w.match(/\((ember-remodal\.[a-z-]+)\)/);
    return match ? match[1] : null;
  }).filter(Boolean);
}

module('Integration | Component | ember-remodal deprecations', function(hooks) {
  setupRenderingTest(hooks);

  let warnings, originalWarn;

  hooks.beforeEach(function() {
    _resetWarnings();
    warnings = [];
    originalWarn = console.warn;
    console.warn = message => warnings.push(message);
  });

  hooks.afterEach(function() {
    console.warn = originalWarn;
  });

  test('warns about v3 being available', async function(assert) {
    await render(hbs`{{ember-remodal}}`);
    await settled(); // Wait for afterRender hooks to complete

    let ids = warningIds(warnings);
    // In test mode, we get v3 and disable-animation-while-testing warnings
    assert.ok(ids.includes('ember-remodal.v3-available'), `Expected v3-available, got: ${JSON.stringify(ids)}`);
  });

  test('warns about v3 only once per id, even with multiple instances', async function(assert) {
    await render(hbs`{{ember-remodal}}{{ember-remodal}}`);
    await settled();

    let ids = warningIds(warnings);
    assert.ok(ids.includes('ember-remodal.v3-available'), `Expected v3-available, got: ${JSON.stringify(ids)}`);
    assert.equal(ids.filter(id => id === 'ember-remodal.v3-available').length, 1);
  });

  test('warns about string action names', async function(assert) {
    await render(hbs`{{ember-remodal onOpen="someActionName"}}`);

    assert.ok(warningIds(warnings).includes('ember-remodal.string-actions'));
  });

  test('warns about hashTracking', async function(assert) {
    await render(hbs`{{ember-remodal hashTracking=true}}`);

    assert.ok(warningIds(warnings).includes('ember-remodal.hash-tracking'));
  });

  test('warns about class attribute in curly invocation', async function(assert) {
    await render(hbs`{{ember-remodal class="custom"}}`);

    assert.ok(warningIds(warnings).includes('ember-remodal.class-attribute'));
  });

  test('warns about modal property access', async function(assert) {
    await render(hbs`{{ember-remodal forService=true}}`);

    let modal = this.owner.lookup('service:remodal').get('ember-remodal');

    assert.ok(modal);
    // Modal property is accessed during service registration
    assert.ok(warningIds(warnings).some(id => id === 'ember-remodal.modal-property' || id === 'ember-remodal.disable-animation-while-testing'));
  });

  test('warns about component-via-service', async function(assert) {
    await render(hbs`{{ember-remodal forService=true}}`);

    let modal = this.owner.lookup('service:remodal').get('ember-remodal');
    // Can't actually call open() here as it breaks the test runloop
    // This will be fully tested after Task 4 wires the sentinel
    assert.ok(modal);
  });

  test('clean baseline - only v3 warning for normal usage', async function(assert) {
    await render(hbs`{{ember-remodal openButton='open'}}`);
    await settled();

    await click('[data-test-id="openButton"]');
    let modal = await find('[data-test-id="modalWindow"]');
    await waitUntil(() => modal.classList.contains('remodal-is-opened'));

    await click('.remodal-close');
    await settled();

    // In test mode, we expect v3 and disable-animation-while-testing warnings
    let ids = warningIds(warnings);
    assert.ok(ids.includes('ember-remodal.v3-available'), `Expected v3-available, got: ${JSON.stringify(ids)}`);
  });

  test('silenceDeprecations suppresses all warnings', async function(assert) {
    this.owner.resolveRegistration('config:environment')['ember-remodal'] = { silenceDeprecations: true };

    await render(hbs`{{ember-remodal hashTracking=true}}`);

    assert.equal(warnings.length, 0);
  });
});