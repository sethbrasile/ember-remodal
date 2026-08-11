import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click, find } from '@ember/test-helpers';
import ErButton from '#src/components/ember-remodal/er-button.gts';
import { hasFocusableDescendant } from '#src/components/ember-remodal/er-button.gts';
import { setupRemodal } from '#src/test-support/index.ts';
import { captureWarnings } from '../helpers/remodal-test-helpers.ts';

/**
 * ErButton is a public export (`ember-remodal` re-exports it) and the component
 * behind every yielded `m.open` / `m.confirm` / `m.cancel`, but it had no tests
 * of its own — in particular none for the `{{#unless @destination}}` branch,
 * which is what runs whenever the modal has no portal target (SSR, or any use
 * of ErButton directly).
 */
module('Rendering | er-button', function (hooks) {
  setupRenderingTest(hooks);
  setupRemodal(hooks);

  test('@destination={{null}} renders inline, forwards clicks, and passes ...attributes', async function (assert) {
    const events: Event[] = [];
    const handleClick = (event?: Event) => {
      if (event) events.push(event);
    };

    await render(
      <template>
        <ErButton
          @destination={{null}}
          @onClick={{handleClick}}
          class="extra-class"
          data-test-trigger
          title="A trigger"
        >
          <button type="button" data-test-inner-button>Go</button>
        </ErButton>
      </template>,
    );

    const wrapper = find('[data-test-trigger]');
    assert.dom(wrapper).hasTagName('span', 'the inline branch renders a span');
    assert
      .dom(wrapper)
      .hasClass('er-button', 'keeps its own class')
      .hasClass('extra-class', '...attributes merges the consumer class')
      .hasAttribute('title', 'A trigger', 'and forwards other attributes');
    assert
      .dom('[data-test-trigger] [data-test-inner-button]')
      .exists('the block renders inside the wrapper');

    await click('[data-test-inner-button]');

    assert.strictEqual(events.length, 1, '@onClick fired once');
    assert.strictEqual(
      events[0]?.type,
      'click',
      'and was handed the real click event',
    );
    assert.strictEqual(
      events[0]?.target,
      find('[data-test-inner-button]'),
      'whose target is the consumer control, not the wrapper span',
    );
  });

  test('a @destination portals the block out of the call site', async function (assert) {
    // Deliberately outside #ember-testing: that is the shape the modal itself
    // relies on, where the open trigger has to escape the <dialog> subtree.
    const destination = document.createElement('div');
    document.body.append(destination);
    const noop = () => {};

    try {
      await render(
        <template>
          <div data-test-origin>
            <ErButton @destination={{destination}} @onClick={{noop}}>
              <button type="button" data-test-portaled>Go</button>
            </ErButton>
          </div>
        </template>,
      );

      assert.ok(
        destination.querySelector('[data-test-portaled]'),
        'the content is portaled into the destination element',
      );
      assert
        .dom('[data-test-origin] [data-test-portaled]')
        .doesNotExist('and not left at the call site');
    } finally {
      destination.remove();
    }
  });

  test('a block with no focusable control warns, and the warning names the fix', async function (assert) {
    const noop = () => {};

    const warnings = await captureWarnings(() =>
      render(
        <template>
          <ErButton @destination={{null}} @onClick={{noop}}>Bare label</ErButton>
        </template>,
      ),
    );

    assert.true(
      warnings.some((warning) =>
        warning.includes('keyboard users can never reach'),
      ),
      `warned about the unreachable trigger (got: ${JSON.stringify(warnings)})`,
    );
  });

  test('hasFocusableDescendant is lenient about what counts as focusable', function (assert) {
    const probe = document.createElement('div');

    probe.innerHTML = '<span>just text</span>';
    assert.false(hasFocusableDescendant(probe), 'plain text does not count');

    probe.innerHTML = '<span><input disabled /></span>';
    assert.true(
      hasFocusableDescendant(probe),
      'a disabled control still counts: a false "unreachable" warning is worse than a missed one',
    );

    assert.false(hasFocusableDescendant(null), 'null is not focusable');
  });
});
