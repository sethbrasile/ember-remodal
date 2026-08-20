import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { click, render } from '@ember/test-helpers';
import { htmlSafe } from '@ember/template';
import type { SafeString } from '@ember/template';
import copyCode from '../../demo-app/modifiers/copy-code.ts';
import migrationSrc from '../../MIGRATION.md?highlight';

function trustedHtml(html: string): SafeString {
  return htmlSafe(html);
}

const MigrationArticle = <template>
  <article class="docs-markdown" {{copyCode}}>{{trustedHtml
      migrationSrc.html
    }}</article>
</template>;

module('Rendering | migration page', function (hooks) {
  setupRenderingTest(hooks);

  test('renders the two-step upgrade path with copy buttons', async function (assert) {
    await render(<template><MigrationArticle /></template>);

    assert.dom().includesText('The two-step upgrade path');
    assert.dom('.docs-markdown .demo-copy').exists();
  });

  test('copy writes the code block to the clipboard', async function (assert) {
    let written = '';
    const originalClipboard = navigator.clipboard;
    Object.defineProperty(navigator, 'clipboard', {
      configurable: true,
      value: {
        writeText(text: string) {
          written = text;
          return Promise.resolve();
        },
      },
    });

    try {
      await render(<template><MigrationArticle /></template>);

      const promptPre = [
        ...document.querySelectorAll('.docs-markdown pre'),
      ].find((pre) =>
        pre.textContent?.includes('Audit this Ember app for upgrade readiness'),
      );
      const promptCopy = promptPre?.parentElement?.querySelector('.demo-copy');

      if (!(promptCopy instanceof HTMLElement)) {
        throw new Error('the readiness prompt block has a copy button');
      }

      await click(promptCopy);

      assert.true(
        written.includes('Audit this Ember app for upgrade readiness'),
        'clipboard received the readiness prompt',
      );
      assert.dom(promptCopy).hasText('Copied');
    } finally {
      Object.defineProperty(navigator, 'clipboard', {
        configurable: true,
        value: originalClipboard,
      });
    }
  });
});
