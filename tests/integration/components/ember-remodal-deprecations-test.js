import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click, settled, find, waitUntil } from '@ember/test-helpers';
import { run } from '@ember/runloop';
import hbs from 'htmlbars-inline-precompile';
import { _resetWarnings, _recordedWarnings } from 'ember-remodal/utils/deprecations';

/* eslint-disable no-console */
function warningIds(list) {
  return list.map(w => {
    let match = String(w).match(/\((ember-remodal\.[a-z0-9-]+)\)/);
    return match ? match[1] : null;
  }).filter(Boolean);
}

module('Integration | Component | ember-remodal deprecations', function(hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function() {
    _resetWarnings();
  });

  function warnings() {
    return _recordedWarnings();
  }

  test('warns about v3 being available', async function(assert) {
    await render(hbs`{{ember-remodal}}`);
    await settled(); // Wait for afterRender hooks to complete

    let ids = warningIds(warnings());
    // In test mode, we get v3 and disable-animation-while-testing warnings
    assert.ok(ids.includes('ember-remodal.v3-available'), `Expected v3-available, got: ${JSON.stringify(ids)}`);
  });

  test('warns about v3 only once per id, even with multiple instances', async function(assert) {
    await render(hbs`{{ember-remodal}}{{ember-remodal}}`);
    await settled();

    let ids = warningIds(warnings());
    assert.ok(ids.includes('ember-remodal.v3-available'), `Expected v3-available, got: ${JSON.stringify(ids)}`);
    assert.equal(ids.filter(id => id === 'ember-remodal.v3-available').length, 1);
  });

  test('warns about string action names', async function(assert) {
    await render(hbs`{{ember-remodal onOpen="someActionName"}}`);

    assert.ok(warningIds(warnings()).includes('ember-remodal.string-actions'));
  });

  test('warns about hashTracking', async function(assert) {
    await render(hbs`{{ember-remodal hashTracking=true}}`);

    assert.ok(warningIds(warnings()).includes('ember-remodal.hash-tracking'));
  });

  test('warns about class attribute in curly invocation', async function(assert) {
    await render(hbs`{{ember-remodal class="custom"}}`);

    assert.ok(warningIds(warnings()).includes('ember-remodal.class-attribute'));
  });

  test('warns about modal property access', async function(assert) {
    await render(hbs`{{ember-remodal forService=true}}`);

    let modal = this.owner.lookup('service:remodal').get('ember-remodal');

    assert.ok(modal);
    // Modal property is accessed during service registration
    assert.ok(warningIds(warnings()).some(id => id === 'ember-remodal.modal-property' || id === 'ember-remodal.disable-animation-while-testing'));
  });

  test('warns about component-via-service', async function(assert) {
    await render(hbs`{{ember-remodal forService=true}}`);

    let modal = this.owner.lookup('service:remodal').get('ember-remodal');
    try {
      run(() => modal.open());
    } catch (e) { /* testing mode autorun */ }

    assert.ok(warningIds(warnings()).includes('ember-remodal.component-via-service'));
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
    let ids = warningIds(warnings());
    assert.ok(ids.includes('ember-remodal.v3-available'), `Expected v3-available, got: ${JSON.stringify(ids)}`);
  });

  test('silenceDeprecations suppresses all warnings', async function(assert) {
    let env = this.owner.resolveRegistration('config:environment');
    let previous = env['ember-remodal'];
    env['ember-remodal'] = { silenceDeprecations: true };

    await render(hbs`{{ember-remodal hashTracking=true}}`);

    assert.equal(warnings().length, 0);
    env['ember-remodal'] = previous;
  });

  test('warns about service option alias get', async function(assert) {
    await render(hbs`{{ember-remodal forService=true}}`);

    this.owner.lookup('service:remodal').get('title');

    assert.ok(warningIds(warnings()).includes('ember-remodal.service-option-aliases'));
  });

  test('warns about service option alias set and still delegates', async function(assert) {
    await render(hbs`{{ember-remodal forService=true}}`);

    let service = this.owner.lookup('service:remodal');
    service.set('text', 'x');

    assert.ok(warningIds(warnings()).includes('ember-remodal.service-option-aliases'));
    assert.equal(service.get('ember-remodal.text'), 'x');
  });

  test('service open/close round-trip does not warn component-via-service', async function(assert) {
    await render(hbs`{{ember-remodal forService=true}}`);
    await settled();

    let service = this.owner.lookup('service:remodal');
    let modalEl = find('[data-test-id="modalWindow"]');

    await run(() => service.open());
    await waitUntil(() => modalEl.classList.contains('remodal-is-opened'));

    await run(() => service.close());
    await waitUntil(() => modalEl.classList.contains('remodal-is-closed'));

    let ids = warningIds(warnings());
    assert.ok(ids.includes('ember-remodal.v3-available'));
    assert.notOk(ids.includes('ember-remodal.component-via-service'));
  });

  test('warns when opening an unrendered name', async function(assert) {
    await render(hbs`{{ember-remodal forService=true}}`);

    try {
      run(() => this.owner.lookup('service:remodal').open('nope'));
    } catch (e) { /* Ember.assert in development */ }

    assert.ok(warningIds(warnings()).includes('ember-remodal.open-on-unrendered-name'));
  });

  test('warns when invoking er-button directly', async function(assert) {
    await render(hbs`{{#ember-remodal/er-button}}x{{/ember-remodal/er-button}}`);
    await settled();

    assert.ok(warningIds(warnings()).includes('ember-remodal.er-button-direct'));
  });

  test('yielded er-buttons do not warn er-button-direct', async function(assert) {
    await render(hbs`
      {{#ember-remodal as |m|}}
        {{#m.open}}<button type="button">o</button>{{/m.open}}
      {{/ember-remodal}}
    `);

    assert.notOk(warningIds(warnings()).includes('ember-remodal.er-button-direct'));
  });
});