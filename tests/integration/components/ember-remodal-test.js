import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click, find, waitUntil } from '@ember/test-helpers';
import { hbs } from 'ember-cli-htmlbars';

module('Integration | Component | ember remodal', function(hooks) {
  setupRenderingTest(hooks);

  test('renders', async function(assert) {
    await render(hbs`<EmberRemodal />`);

    assert.dom(this.element).hasNoText();

    // Template block usage:" + EOL +
    await render(hbs`
      <EmberRemodal>
        template block text
      </EmberRemodal>
    `);

    assert.dom(this.element).hasText('template block text');
  });

  test('it works by clicking the provided button', async function(assert) {
    assert.expect(1);

    await render(hbs`<EmberRemodal @openButton="open" />`);
    const modal = find('[data-test-id="modalWindow"]');
    await click('[data-test-id="openButton"]');
    await waitUntil(() => modal.classList.contains('remodal-is-opened'));
    assert.ok(modal.classList.contains('remodal-is-opened'));
  });

  test('it works by clicking the provided link', async function(assert) {
    assert.expect(1);
    await render(hbs`<EmberRemodal @openLink="open" />`);
    const modal = find('[data-test-id="modalWindow"]');
    await click('[data-test-id="openLink"]');
    await waitUntil(() => modal.classList.contains('remodal-is-opened'));
    assert.ok(modal.classList.contains('remodal-is-opened'));
  });
});
