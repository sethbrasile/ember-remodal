import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, getRootElement } from '@ember/test-helpers';
import { setupRemodal } from '#src/test-support/index.ts';
import type { ComponentLike } from '@glint/template';
import DemoToastsService from '../../demo-app/services/demo-toasts.ts';

interface DemoExampleModule {
  default: ComponentLike;
  noDialog?: boolean;
}

const examples = import.meta.glob<DemoExampleModule>(
  '../../demo-app/examples/**/*.gts',
  { eager: true },
);

module('Rendering | demo examples', function (hooks) {
  setupRenderingTest(hooks);
  setupRemodal(hooks, { disableAnimation: true });

  hooks.beforeEach(function () {
    this.owner.register('service:demo-toasts', DemoToastsService);
  });

  for (const [path, mod] of Object.entries(examples)) {
    const Example = mod.default;

    if (mod.noDialog === true) {
      test(path, async function (assert) {
        await render(<template><Example /></template>);

        const root = getRootElement() as Element;
        assert.dom(root).exists();
        assert.true(
          root.innerHTML.trim().length > 0,
          'the rendered container is not empty',
        );
      });
    } else {
      test(path, async function (assert) {
        await render(<template><Example /></template>);

        assert.dom('[data-test-id="modalWrapper"]').exists();
      });
    }
  }
});
