import { module, test } from 'qunit';
import { warnOnce, _resetWarnings } from 'ember-remodal/utils/deprecations';

module('Unit | Utility | deprecations', function(hooks) {
  let warnings, originalWarn;

  /* eslint-disable no-console */
  hooks.beforeEach(function() {
    _resetWarnings();
    warnings = [];
    originalWarn = console.warn;
    console.warn = message => warnings.push(message);
  });

  hooks.afterEach(function() {
    console.warn = originalWarn;
  });

  test('formats id, message and anchor link', function(assert) {
    warnOnce(null, 'ember-remodal.test-id', 'Thing is going away.', 'some-anchor');

    assert.deepEqual(warnings, [
      '[ember-remodal] DEPRECATION (ember-remodal.test-id): Thing is going away. See https://github.com/sethbrasile/ember-remodal/blob/master/MIGRATION.md#some-anchor'
    ]);
  });

  test('warns once per id, but separately per distinct id', function(assert) {
    warnOnce(null, 'ember-remodal.a', 'A.', 'a');
    warnOnce(null, 'ember-remodal.a', 'A.', 'a');
    warnOnce(null, 'ember-remodal.b', 'B.', 'b');

    assert.equal(warnings.length, 2);
  });

  test('silenceDeprecations suppresses everything', function(assert) {
    let config = { 'ember-remodal': { silenceDeprecations: true } };
    warnOnce(config, 'ember-remodal.test-id', 'Thing.', 'a');

    assert.equal(warnings.length, 0);
  });

  test('missing anchor links the guide root', function(assert) {
    warnOnce(null, 'ember-remodal.test-id', 'Thing.', null);

    assert.ok(warnings[0].indexOf('MIGRATION.md') === warnings[0].length - 'MIGRATION.md'.length);
  });
});