import { moduleForComponent, test } from 'ember-qunit';
import hbs from 'htmlbars-inline-precompile';

moduleForComponent('ember-remodal/er-button', 'Integration | Component | ember-remodal/er button', {
  integration: true
});

test('it renders', function(assert) {
  // Set any properties with this.set('myProperty', 'value');
  // Handle any actions with this.on('myAction', function(val) { ... });

  this.render(hbs`{{ember-remodal/er-button}}`);

  assert.equal(this.$().text().trim(), '');

  // Template block usage:
  this.render(hbs`
    {{#ember-remodal/er-button}}
      template block text
    {{/ember-remodal/er-button}}
  `);

  assert.equal(this.$().text().trim(), 'template block text');
});

test('"click" sends "action" action', function(assert) {
  this.set('myAction', () => assert.ok(true));

  this.render(hbs`
    {{#ember-remodal/er-button action=(action myAction)}}
      <button class="button"></button>
    {{/ember-remodal/er-button}}
  `);

  this.$('.button').click();
});
