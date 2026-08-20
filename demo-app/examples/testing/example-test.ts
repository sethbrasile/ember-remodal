// A complete, realistic consumer test. It is never run as part of this
// repo's own suite (it lives under demo-app/examples/, not tests/) — it is
// shown source-only on the Testing page, imported through the package names
// a consumer would use rather than #src.
import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click } from '@ember/test-helpers';
import { precompileTemplate } from '@ember/template-compilation';
import EmberRemodal from 'ember-remodal';
import { setupRemodal, remodalDialog } from 'ember-remodal/test-support';

module('Integration | checkout modal', function (hooks) {
  setupRenderingTest(hooks);
  setupRemodal(hooks, { disableAnimation: true });

  test('confirming closes the modal', async function (assert) {
    await render(
      precompileTemplate(
        `<EmberRemodal
          @openButton="Checkout"
          @title="Confirm your order"
          @confirmButton="Place order"
          @cancelButton="Cancel"
        />`,
        { scope: () => ({ EmberRemodal }), strictMode: true },
      ),
    );

    await click('[data-test-id="openButton"]');
    assert.dom(remodalDialog()).exists();

    await click('[data-test-id="confirmButton"]');
    assert.dom('[data-test-id="modalWrapper"]').doesNotExist();
  });
});
