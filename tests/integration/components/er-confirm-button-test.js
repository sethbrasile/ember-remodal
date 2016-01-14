import { moduleForComponent, test } from 'ember-qunit';
import hbs from 'htmlbars-inline-precompile';

moduleForComponent('er-confirm-button', 'Integration | Component | er confirm button', {
  integration: true
});

test('it renders', function(assert) {

  // Set any properties with this.set('myProperty', 'value');
  // Handle any actions with this.on('myAction', function(val) { ... });" + EOL + EOL +

  this.render(hbs`
    {{#ember-remodal}}
      {{er-confirm-button}}
    {{/ember-remodal}}
  `);

  assert.equal(this.$().text().trim(), '');

  // Template block usage:" + EOL +
  this.render(hbs`
    {{#ember-remodal}}
      {{#er-confirm-button}}
        template block text
      {{/er-confirm-button}}
    {{/ember-remodal}}
  `);

  assert.equal(this.$().text().trim(), 'template block text');
});
