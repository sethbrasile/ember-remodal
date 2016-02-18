import { moduleForComponent, test } from 'ember-qunit';
import hbs from 'htmlbars-inline-precompile';

moduleForComponent('ember-remodal', 'Integration | Component | ember remodal', {
  integration: true
});

test('it renders', function(assert) {

  // Set any properties with this.set('myProperty', 'value');
  // Handle any actions with this.on('myAction', function(val) { ... });" + EOL + EOL +

  this.render(hbs`{{ember-remodal}}`);

  assert.equal(this.$().text().trim(), '');

  // Template block usage:" + EOL +
  this.render(hbs`
    {{#ember-remodal}}
      template block text
    {{/ember-remodal}}
  `);

  assert.equal(this.$().text().trim(), 'template block text');
});

test('it works by clicking the provided button', function(assert) {
  assert.expect(1);

  this.render(hbs`{{ember-remodal openButton='open'}}`);

  let modal = this.$('[data-test-id="modalWindow"]');
  let open = this.$('[data-test-id="openButton"]');

  open.click();
  assert.ok(modal.hasClass('remodal-is-opening'));
});

test('it works by clicking the provided link', function(assert) {
  assert.expect(1);

  this.render(hbs`{{ember-remodal openLink='open'}}`);

  let modal = this.$('[data-test-id="modalWindow"]');
  let open = this.$('[data-test-id="openLink"]');

  open.click();
  assert.ok(modal.hasClass('remodal-is-opening'));
});
