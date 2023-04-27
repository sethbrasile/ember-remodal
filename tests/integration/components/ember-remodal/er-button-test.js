import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click } from '@ember/test-helpers';
import hbs from 'htmlbars-inline-precompile';

module('Integration | Component | ember-remodal/er button', function(hooks) {
  setupRenderingTest(hooks);

  test('renders', async function(assert) {
    await render(hbs`<EmberRemodal::ErButton />`);

    assert.dom(this.element).hasNoText();

    // Template block usage:" + EOL +
    await render(hbs`
      <EmberRemodal::ErButton>
        template block text
      </EmberRemodal::ErButton>
    `);

    assert.dom(this.element).hasText('template block text');
  });

  test('"click" sends "action" action', async function(assert) {
    this.set('myAction', () => assert.ok(true));

    await render(hbs`
      <EmberRemodal::ErButton @action={{this.myAction}}>
          <button class="button"></button>
      </EmberRemodal::ErButton>
    `);

    await click('.button');
  });
});
