import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click } from '@ember/test-helpers';
import hbs from 'htmlbars-inline-precompile';

module('Integration | Component | ember-remodal/er button', function(hooks) {
  setupRenderingTest(hooks);

  test('renders', async function(assert) {
    await render(hbs`{{ember-remodal/er-button}}`);

    assert.equal(this.$().text().trim(), '');

    // Template block usage:" + EOL +
    await render(hbs`
      {{#ember-remodal/er-button}}
        template block text
      {{/ember-remodal/er-button}}
    `);

    assert.equal(this.$().text().trim(), 'template block text');
  });

  test('"click" sends "action" action', async function(assert) {
    this.set('myAction', () => assert.ok(true));

    await render(hbs`
      {{#ember-remodal/er-button action=(action myAction)}}
        <button class="button"></button>
      {{/ember-remodal/er-button}}
    `);

    await click('.button');
  });
});
