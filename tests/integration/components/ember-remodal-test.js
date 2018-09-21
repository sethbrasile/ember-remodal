import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click, find, waitUntil } from '@ember/test-helpers';
import hbs from 'htmlbars-inline-precompile';

module('Integration | Component | ember remodal', function(hooks) {
  setupRenderingTest(hooks);

  test('renders', async function(assert) {
    await render(hbs`{{ember-remodal}}`);

    assert.equal(this.$().text().trim(), '');

    // Template block usage:" + EOL +
    await render(hbs`
      {{#ember-remodal}}
        template block text
      {{/ember-remodal}}
    `);

    assert.equal(this.$().text().trim(), 'template block text');
  });

  test('it works by clicking the provided button', async function(assert) {
    assert.expect(1);
    await render(hbs`{{ember-remodal openButton='open'}}`);
    let modal = find('[data-test-id="modalWindow"]');
    await click('[data-test-id="openButton"]');
    await waitUntil(() => modal.classList.contains('remodal-is-opened'));
    assert.ok(modal.classList.contains('remodal-is-opened'));
  });

  test('it works by clicking the provided link', async function(assert) {
    assert.expect(1);
    await render(hbs`{{ember-remodal openLink='open'}}`);
    let modal = find('[data-test-id="modalWindow"]');
    await click('[data-test-id="openLink"]');
    await waitUntil(() => modal.classList.contains('remodal-is-opened'));
    assert.ok(modal.classList.contains('remodal-is-opened'));
  });
});
