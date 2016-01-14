import { moduleForComponent, test } from 'ember-qunit';
import hbs from 'htmlbars-inline-precompile';

moduleForComponent('er-cancel-button', 'Integration | Component | er cancel button', {
  integration: true
});

test('it renders', function(assert) {

  // Set any properties with this.set('myProperty', 'value');
  // Handle any actions with this.on('myAction', function(val) { ... });" + EOL + EOL +

  this.render(hbs`
    {{#ember-remodal}}
      {{er-cancel-button}}
    {{/ember-remodal}}
    `);

  assert.equal(this.$().text().trim(), '');

  // Template block usage:" + EOL +
  this.render(hbs`
    {{#ember-remodal}}
      {{#er-cancel-button}}
        template block text
      {{/er-cancel-button}}
    {{/ember-remodal}}
  `);

  assert.equal(this.$().text().trim(), 'template block text');
});
