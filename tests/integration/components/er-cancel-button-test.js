import { moduleForComponent, test } from 'ember-qunit';
import hbs from 'htmlbars-inline-precompile';

moduleForComponent('er-cancel-button', 'Integration | Component | er cancel button', {
  integration: true
});

test('it renders', function(assert) {
  assert.expect(1);

  this.render(hbs`
    {{#ember-remodal}}
      {{er-cancel-button}}
    {{/ember-remodal}}
  `);

  assert.equal(this.$().text().trim(), '');
});

test('it errors when not nested in an "ember-remodal"', function(assert) {
  assert.expect(1);

  this.set('_getModal', () => null);

  let component = () => {
    this.render(hbs`
      {{#er-cancel-button _getModal=_getModal}}
        template block text
      {{/er-cancel-button}}
    `);
  };

  assert.throws(component);
});

test('it does not error when nested in an "ember-remodal"', function(assert) {
  assert.expect(1);

  this.render(hbs`
    {{#ember-remodal}}
      {{#er-cancel-button}}
        template block text
      {{/er-cancel-button}}
    {{/ember-remodal}}
  `);

  assert.equal(this.$().text().trim(), 'template block text');
});
