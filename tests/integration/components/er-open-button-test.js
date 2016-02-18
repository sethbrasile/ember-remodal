import { moduleForComponent, test } from 'ember-qunit';
import hbs from 'htmlbars-inline-precompile';

moduleForComponent('er-open-button', 'Integration | Component | er open button', {
  integration: true
});

test('it renders', function(assert) {
  assert.expect(1);

  this.render(hbs`
    {{#ember-remodal}}
      {{er-open-button}}
    {{/ember-remodal}}
  `);

  assert.equal(this.$().text().trim(), '');
});

test('it errors when not nested in an "ember-remodal"', function(assert) {
  assert.expect(1);

  this.set('_getModal', () => null);

  let component = () => {
    this.render(hbs`
      {{#er-open-button _getModal=_getModal}}
        template block text
      {{/er-open-button}}
    `);
  };

  assert.throws(component);
});

test('it does not error when nested in an "ember-remodal"', function(assert) {
  assert.expect(1);

  this.render(hbs`
    {{#ember-remodal}}
      {{#er-open-button}}
        template block text
      {{/er-open-button}}
    {{/ember-remodal}}
  `);

  assert.equal(this.$().text().trim(), 'template block text');
});
