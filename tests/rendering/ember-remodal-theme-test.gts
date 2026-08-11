import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click, focus, settled, find } from '@ember/test-helpers';
import EmberRemodal from '#src/components/ember-remodal.gts';
import cssSource from '../../src/styles/ember-remodal.css?raw';
import { dialog } from '../helpers/remodal-test-helpers.ts';

/** The stylesheet with comments stripped — prose about `@keyframes` or about a
 *  dead vendor prefix must not be mistaken for a declaration of one. */
const css = cssSource.replace(/\/\*[\s\S]*?\*\//g, '');

/**
 * These tests measure the theme as the browser resolves it — computed styles and
 * real geometry — rather than asserting that a declaration exists in the
 * stylesheet. The bugs they cover were all invisible at the source level: a
 * missing `box-sizing` that only shows up as a rect 20px larger than the
 * viewport, contrast ratios that have to be computed from resolved colours, and
 * a `visibility: hidden !important` from a third-party stylesheet that only
 * matters once both sheets are in the same document.
 */

/** WCAG 2.x relative luminance (sRGB), per the definition in the guidelines. */
function relativeLuminance([r, g, b]: [number, number, number]): number {
  const channel = (value: number) => {
    const c = value / 255;
    return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  };
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);
}

function parseColor(value: string): [number, number, number] {
  const match = value.match(/-?[\d.]+/g);
  if (!match || match.length < 3) {
    throw new Error(`cannot parse colour: ${value}`);
  }
  return [Number(match[0]), Number(match[1]), Number(match[2])];
}

function contrastRatio(a: string, b: string): number {
  const [lighter, darker] = [
    relativeLuminance(parseColor(a)),
    relativeLuminance(parseColor(b)),
  ].sort((x, y) => y - x) as [number, number];
  return (lighter + 0.05) / (darker + 0.05);
}

/** Appends a stylesheet and hands back a disposer. */
function addStyleSheet(css: string, position: 'first' | 'last'): () => void {
  const style = document.createElement('style');
  style.textContent = css;
  if (position === 'first') {
    document.head.insertBefore(style, document.head.firstChild);
  } else {
    document.head.append(style);
  }
  return () => style.remove();
}

/**
 * The colour that actually shows behind `element`: its own background, or the
 * nearest ancestor's if it is fully transparent (the close button is).
 */
function effectiveBackground(element: Element): string {
  let current: Element | null = element;
  while (current) {
    const background = getComputedStyle(current).backgroundColor;
    const parsed = background.match(/-?[\d.]+/g) ?? [];
    const alpha = parsed.length > 3 ? Number(parsed[3]) : 1;
    if (alpha > 0) {
      return background;
    }
    current = current.parentElement;
  }
  return 'rgb(255, 255, 255)';
}

function rect(selector: string): DOMRect {
  const element = find(selector);
  if (!element) {
    throw new Error(`missing element: ${selector}`);
  }
  return element.getBoundingClientRect();
}

module('Rendering | ember-remodal theme', function (hooks) {
  setupRenderingTest(hooks);

  module('layout', function () {
    test('the open dialog fits the viewport exactly and centers the card', async function (assert) {
      // The dialog sets `inset: 0` AND `width/height: 100%` AND `padding: 10px`.
      // Without `box-sizing: border-box` the UA default (content-box) made the
      // box 20px larger than the viewport on both axes — an overflow that was
      // not even scrollable — and pushed the card 10px right and 10px down.
      await render(
        <template>
          <EmberRemodal
            @openButton="Open"
            @title="Centered"
            @disableAnimation={{true}}
          />
        </template>,
      );
      await click('[data-test-id="openButton"]');

      const viewportWidth = document.documentElement.clientWidth;
      const viewportHeight = document.documentElement.clientHeight;
      const dialogRect = rect('[data-test-id="modalWrapper"]');
      const cardRect = rect('[data-test-id="modalWindow"]');
      const element = dialog();

      assert.strictEqual(
        getComputedStyle(element).boxSizing,
        'border-box',
        'the dialog is border-box, so its padding stays inside the viewport box',
      );
      assert.strictEqual(dialogRect.x, 0, 'dialog left edge at the viewport');
      assert.strictEqual(dialogRect.y, 0, 'dialog top edge at the viewport');
      assert.strictEqual(
        dialogRect.width,
        viewportWidth,
        `dialog width ${dialogRect.width} matches the viewport ${viewportWidth}`,
      );
      assert.strictEqual(
        dialogRect.height,
        viewportHeight,
        `dialog height ${dialogRect.height} matches the viewport ${viewportHeight}`,
      );
      assert.ok(
        dialogRect.right <= viewportWidth &&
          dialogRect.bottom <= viewportHeight,
        'the dialog does not extend past the viewport',
      );
      assert.strictEqual(
        element.scrollWidth,
        element.clientWidth,
        'no horizontal overflow inside the dialog',
      );

      assert.ok(
        Math.abs(cardRect.x + cardRect.width / 2 - viewportWidth / 2) <= 1,
        `card centerX ${cardRect.x + cardRect.width / 2} matches viewport centerX ${viewportWidth / 2}`,
      );
      assert.ok(
        Math.abs(cardRect.y + cardRect.height / 2 - viewportHeight / 2) <= 1,
        `card centerY ${cardRect.y + cardRect.height / 2} matches viewport centerY ${viewportHeight / 2}`,
      );
    });

    test('a card as wide as the viewport is not clipped off-screen', async function (assert) {
      // On narrow screens `.remodal { width: 100% }` resolves against the
      // dialog's content box. Under content-box that box started at x = 10px and
      // was 20px too wide, so the card's right edge fell outside the viewport
      // with `html { overflow: hidden }` preventing any scroll to it. The media
      // query caps the card at 700px above 640px wide, so shrink the dialog's
      // available width instead of the window.
      const dispose = addStyleSheet(
        'dialog.remodal-wrapper { max-width: 400px !important; }',
        'last',
      );
      try {
        await render(
          <template>
            <EmberRemodal
              @openButton="Open"
              @title="Wide"
              @disableAnimation={{true}}
            />
          </template>,
        );
        await click('[data-test-id="openButton"]');

        const dialogRect = rect('[data-test-id="modalWrapper"]');
        const cardRect = rect('[data-test-id="modalWindow"]');

        assert.strictEqual(dialogRect.width, 400, 'the dialog box is 400px');
        assert.ok(
          cardRect.right <= dialogRect.right,
          `card right edge ${cardRect.right} stays inside the dialog ${dialogRect.right}`,
        );
        assert.strictEqual(
          dialog().scrollWidth,
          dialog().clientWidth,
          'the card creates no unscrollable horizontal overflow',
        );
      } finally {
        dispose();
      }
    });

    test('the scroll lock does not disable touch panning inside the modal', async function (assert) {
      // Effective touch-action is the intersection with every ancestor's, and a
      // top-layer <dialog> is still a DOM descendant of <html>: `touch-action:
      // none` on the locked <html> made a modal taller than the viewport
      // impossible to pan (WCAG 2.1.1, 1.4.10).
      await render(
        <template>
          <EmberRemodal
            @openButton="Open"
            @title="Tall"
            @disableAnimation={{true}}
          />
        </template>,
      );
      await click('[data-test-id="openButton"]');

      assert
        .dom(document.documentElement)
        .hasClass('remodal-is-locked', 'the scroll lock is engaged');
      assert.strictEqual(
        getComputedStyle(document.documentElement).overflow,
        'hidden',
        'the lock still works via overflow',
      );
      assert.strictEqual(
        getComputedStyle(document.documentElement).touchAction,
        'auto',
        'touch-action is not disabled on the locked root',
      );
      assert.strictEqual(
        getComputedStyle(dialog()).touchAction,
        'auto',
        'touch-action is not disabled on the dialog',
      );
      assert.strictEqual(
        getComputedStyle(dialog()).overscrollBehaviorY,
        'contain',
        'scroll chaining out of the dialog is contained instead',
      );
    });

    test('the card is not a containing block for fixed-position content', async function (assert) {
      // `transform: translate3d(0, 0, 0)` was upstream's GPU-layer hack. A
      // non-`none` transform makes the card a containing block for fixed
      // descendants, so consumer content using `position: fixed` was positioned
      // against the card instead of the viewport.
      const dispose = addStyleSheet(
        '.probe-fixed { position: fixed; top: 0; left: 0; width: 10px; height: 10px }',
        'last',
      );
      try {
        await render(
          <template>
            <EmberRemodal
              @openButton="Open"
              @title="Fixed"
              @disableAnimation={{true}}
            >
              <div class="probe-fixed" data-test-fixed></div>
            </EmberRemodal>
          </template>,
        );
        await click('[data-test-id="openButton"]');

        assert.strictEqual(
          getComputedStyle(find('[data-test-id="modalWindow"]')!).transform,
          'none',
          'the card has no transform while idle',
        );
        const fixedRect = rect('[data-test-fixed]');
        assert.strictEqual(
          fixedRect.x,
          0,
          'fixed content resolves against the viewport, not the card',
        );
        assert.strictEqual(fixedRect.y, 0, 'and on the y axis too');
      } finally {
        dispose();
      }
    });

    test('text inflation is suppressed on WebKit as well', async function (assert) {
      // Only the unprefixed property survived the port, and WebKit implements
      // only `-webkit-text-size-adjust` — leaving the declaration a no-op on
      // exactly the platform it exists for.
      await render(<template><EmberRemodal @title="Adjust" /></template>);

      const card = find('[data-test-id="modalWindow"]')!;
      assert.strictEqual(
        getComputedStyle(card).getPropertyValue('-webkit-text-size-adjust'),
        '100%',
        'the prefixed property is declared',
      );
      assert.notOk(
        /-webkit-overflow-scrolling|::-moz-focus-inner/.test(css),
        'the genuinely dead prefixes are gone',
      );
    });
  });

  module('contrast and focus', function () {
    test('confirm and cancel labels clear WCAG 1.4.3 AA against their backgrounds', async function (assert) {
      await render(
        <template>
          <EmberRemodal
            @openButton="Open"
            @confirmButton="Yes"
            @cancelButton="No"
            @disableAnimation={{true}}
          />
        </template>,
      );
      await click('[data-test-id="openButton"]');

      for (const id of ['confirmButton', 'cancelButton']) {
        const button = find(`[data-test-id="${id}"]`)!;
        const style = getComputedStyle(button);
        const ratio = contrastRatio(style.color, style.backgroundColor);
        assert.ok(
          ratio >= 4.5,
          `${id}: ${style.color} on ${style.backgroundColor} = ${ratio.toFixed(2)}:1 (>= 4.5:1)`,
        );
        // `font: inherit` leaves these at the inherited size, so the 3:1
        // large-text exemption does not apply — check the premise holds.
        assert.ok(
          parseFloat(style.fontSize) < 18.66,
          `${id} is not large text (${style.fontSize})`,
        );
      }
    });

    test('hover/focus backgrounds also clear AA', function (assert) {
      // The hover colours are what a pointer user actually reads text against.
      const probe = document.createElement('div');
      probe.innerHTML =
        '<button class="remodal-confirm" id="p1"></button><button class="remodal-cancel" id="p2"></button>';
      document.body.append(probe);
      const dispose = addStyleSheet(
        '#p1, #p2 { background: var(--ember-remodal-confirm-background-hover) }' +
          '#p2 { background: var(--ember-remodal-cancel-background-hover) }',
        'last',
      );
      try {
        for (const id of ['p1', 'p2']) {
          const style = getComputedStyle(document.getElementById(id)!);
          const ratio = contrastRatio(style.color, style.backgroundColor);
          assert.ok(
            ratio >= 4.5,
            `${id} hover: ${style.color} on ${style.backgroundColor} = ${ratio.toFixed(2)}:1`,
          );
        }
      } finally {
        dispose();
        probe.remove();
      }
    });

    test('every focusable part of the modal gets a visible focus ring', async function (assert) {
      // Upstream set `outline: none`/`0` on the dialog, the card and all three
      // buttons, leaving a background swap measured at 1.18:1 as the only focus
      // cue — and nothing at all on the dialog itself, which is what
      // showModal() focuses in the @disableForeground path.
      await render(
        <template>
          <EmberRemodal
            @openButton="Open"
            @title="Focus"
            @confirmButton="Yes"
            @cancelButton="No"
            @disableAnimation={{true}}
          />
        </template>,
      );
      await click('[data-test-id="openButton"]');

      for (const id of ['nativeClose', 'confirmButton', 'cancelButton']) {
        const selector = `[data-test-id="${id}"]`;
        await focus(selector);
        const element = find(selector)!;
        const style = getComputedStyle(element);
        assert.true(
          element.matches(':focus-visible'),
          `${id} is :focus-visible when focused`,
        );
        assert.notStrictEqual(
          style.outlineStyle,
          'none',
          `${id} draws an outline (${style.outlineStyle} ${style.outlineWidth} ${style.outlineColor})`,
        );
        assert.notStrictEqual(
          style.boxShadow,
          'none',
          `${id} draws the contrasting halo (${style.boxShadow})`,
        );
        // The ring must be perceivable against whatever is behind it: on the
        // white card the ink outline carries it, on a dark card the halo does.
        // The close button is transparent, so measure against the surface that
        // actually shows through it rather than its own background.
        const haloColor = style.boxShadow.match(/rgba?\([^)]*\)/)?.[0];
        assert.ok(haloColor, `${id} halo colour is resolvable`);
        const behind = effectiveBackground(element);
        const ring = contrastRatio(style.outlineColor, behind);
        const halo = contrastRatio(haloColor!, behind);
        assert.ok(
          Math.max(ring, halo) >= 3,
          `${id} focus indicator contrast: outline ${ring.toFixed(2)}:1, halo ${halo.toFixed(2)}:1 (>= 3:1)`,
        );
      }

      const element = dialog();
      element.focus();
      await settled();
      const dialogStyle = getComputedStyle(element);
      assert.strictEqual(
        document.activeElement,
        element,
        'the dialog itself can hold focus (the @disableForeground path)',
      );
      assert.notStrictEqual(
        dialogStyle.outlineStyle,
        'none',
        `the dialog draws an inset ring (${dialogStyle.outlineStyle} ${dialogStyle.outlineWidth} ${dialogStyle.outlineColor})`,
      );
      assert.ok(
        parseFloat(dialogStyle.outlineOffset) < 0,
        `the dialog ring is inset (${dialogStyle.outlineOffset}) so it is not drawn off-screen`,
      );
    });

    test('the card can take a focus ring too', async function (assert) {
      await render(
        <template>
          <EmberRemodal
            @openButton="Open"
            @title="Card focus"
            @disableAnimation={{true}}
          />
        </template>,
      );
      await click('[data-test-id="openButton"]');

      const card = find('[data-test-id="modalWindow"]') as HTMLElement;
      card.tabIndex = -1;
      card.focus();
      await settled();

      assert.strictEqual(document.activeElement, card, 'the card holds focus');
      if (card.matches(':focus-visible')) {
        const style = getComputedStyle(card);
        assert.notStrictEqual(
          style.outlineStyle,
          'none',
          `the card draws an outline (${style.outlineStyle} ${style.outlineWidth} ${style.outlineColor})`,
        );
      } else {
        // A programmatically focused, non-interactive element is not guaranteed
        // to match :focus-visible; fall back to checking the rule resolves.
        assert.ok(
          matchingSelectors('.remodal:focus-visible').length > 0,
          'a :focus-visible rule exists for the card',
        );
      }
    });
  });

  module('theming hooks', function () {
    test('a consumer stylesheet overrides the card colours without a specificity fight', async function (assert) {
      // The defaults live on `:where(html)` (zero specificity), so a consumer
      // rule wins even when its stylesheet is loaded FIRST — which is the case
      // the addon cannot control, since its CSS ships as a side-effect import
      // whose bundle position is bundler-determined.
      const dispose = addStyleSheet(
        `:root {
           --ember-remodal-background: rgb(1, 2, 3);
           --ember-remodal-color: rgb(4, 5, 6);
           --ember-remodal-color-scheme: dark;
           --ember-remodal-overlay: rgb(10, 20, 30);
         }`,
        'first',
      );
      try {
        await render(
          <template>
            <EmberRemodal
              @openButton="Open"
              @title="Themed"
              @disableAnimation={{true}}
            />
          </template>,
        );
        await click('[data-test-id="openButton"]');

        const style = getComputedStyle(find('[data-test-id="modalWindow"]')!);
        assert.strictEqual(
          style.backgroundColor,
          'rgb(1, 2, 3)',
          'the card background follows the consumer variable',
        );
        assert.strictEqual(
          style.color,
          'rgb(4, 5, 6)',
          'the card foreground follows the consumer variable',
        );
        assert.strictEqual(
          style.colorScheme,
          'dark',
          'form controls inside the modal follow the card, not the app',
        );
        // The overlay is only reachable through ::backdrop, which `@modifier`
        // can address but `@modalClasses` never can — hence the variable. It
        // resolves here because ::backdrop inherits from its originating element
        // in Chrome 122+; the inline var() fallback covers older engines.
        assert.strictEqual(
          getComputedStyle(dialog(), '::backdrop').backgroundColor,
          'rgb(10, 20, 30)',
          'the backdrop follows the consumer variable',
        );
      } finally {
        dispose();
      }
    });

    test('@modalClasses can retheme the card even though it ties on specificity', async function (assert) {
      // `.my-theme` (0,1,0) ties with `.remodal` (0,1,0), so who wins used to
      // depend on bundle order. Setting the variables sidesteps the cascade
      // entirely — proven here with the consumer sheet loaded first.
      const dispose = addStyleSheet(
        '.my-theme { --ember-remodal-background: rgb(7, 8, 9) }',
        'first',
      );
      try {
        await render(
          <template>
            <EmberRemodal
              @openButton="Open"
              @title="Themed"
              @modalClasses="my-theme"
              @disableAnimation={{true}}
            />
          </template>,
        );
        await click('[data-test-id="openButton"]');

        assert.strictEqual(
          getComputedStyle(find('[data-test-id="modalWindow"]')!)
            .backgroundColor,
          'rgb(7, 8, 9)',
          'the card background follows the @modalClasses variable',
        );
      } finally {
        dispose();
      }
    });

    test('the default colours still apply when the consumer does nothing', async function (assert) {
      await render(
        <template>
          <EmberRemodal
            @openButton="Open"
            @title="Default"
            @confirmButton="Yes"
            @cancelButton="No"
            @disableAnimation={{true}}
          />
        </template>,
      );
      await click('[data-test-id="openButton"]');

      assert.strictEqual(
        getComputedStyle(find('[data-test-id="modalWindow"]')!).backgroundColor,
        'rgb(255, 255, 255)',
        'card background default',
      );
      assert.strictEqual(
        getComputedStyle(find('[data-test-id="confirmButton"]')!)
          .backgroundColor,
        'rgb(46, 125, 50)',
        'confirm background default',
      );
      assert.strictEqual(
        getComputedStyle(find('[data-test-id="cancelButton"]')!)
          .backgroundColor,
        'rgb(198, 40, 40)',
        'cancel background default',
      );
    });

    test('remodal-bg content is blurred only while a modal is open', async function (assert) {
      // Upstream's remodal.css blurred `.remodal-bg` while the modal was open
      // and 2.x's styling docs led with it; the port dropped it silently.
      await render(
        <template>
          <div class="remodal-bg" data-test-page>Page content</div>
          <EmberRemodal
            @openButton="Open"
            @title="Blur"
            @disableAnimation={{true}}
          />
        </template>,
      );

      assert.strictEqual(
        getComputedStyle(find('[data-test-page]')!).filter,
        'none',
        'not blurred while closed',
      );

      await click('[data-test-id="openButton"]');
      assert.strictEqual(
        getComputedStyle(find('[data-test-page]')!).filter,
        'blur(3px)',
        'blurred while open',
      );

      await click('[data-test-id="modalWrapper"]');
      assert.strictEqual(
        getComputedStyle(find('[data-test-page]')!).filter,
        'none',
        'unblurred again after close',
      );
    });

    test('confirm and cancel stay distinguishable under forced-colors', function (assert) {
      // forced-colors cannot be emulated from inside the page, so assert the
      // rules the browser parsed: the two buttons must differ by something
      // other than background colour, since backgrounds are overridden.
      const forced = mediaBlock('(forced-colors: active)');
      assert.ok(forced.length > 0, 'a forced-colors block is present');

      const confirm = declarationsFor(forced, '.remodal-confirm');
      const cancel = declarationsFor(forced, '.remodal-cancel');
      assert.ok(confirm.borderStyle !== '', 'confirm gets a border');
      assert.strictEqual(
        cancel.borderStyle,
        'dashed',
        'cancel differs in kind',
      );
      assert.notStrictEqual(
        confirm.borderStyle,
        cancel.borderStyle,
        `confirm (${confirm.borderStyle}) and cancel (${cancel.borderStyle}) are told apart without colour`,
      );
      assert.ok(
        declarationsFor(forced, '.remodal-close').borderStyle !== '',
        'the close button gets a border too',
      );
    });

    test('reduced motion suppresses the transitions as well as the animations', async function (assert) {
      const reduced = mediaBlock('(prefers-reduced-motion: reduce)');
      assert.ok(reduced.length > 0, 'a reduced-motion block is present');
      for (const selector of [
        '.remodal-close',
        '.remodal-confirm',
        '.remodal-cancel',
      ]) {
        assert.strictEqual(
          declarationsFor(reduced, selector).transitionProperty,
          'none',
          `${selector} transition is suppressed`,
        );
      }
      // And the elements really do declare a transition outside that block, so
      // the assertions above are not vacuous.
      await render(
        <template>
          <EmberRemodal @title="Motion" @confirmButton="Yes" />
        </template>,
      );
      assert.notStrictEqual(
        getComputedStyle(find('[data-test-id="nativeClose"]')!)
          .transitionProperty,
        'none',
        'the close button transitions by default',
      );
    });
  });

  module('@disableForeground', function () {
    test('the frameless card is styled through a namespaced class', async function (assert) {
      await render(
        <template>
          <EmberRemodal
            @openButton="Open"
            @ariaLabel="Ghost"
            @disableForeground={{true}}
            @disableAnimation={{true}}
          />
        </template>,
      );
      await click('[data-test-id="openButton"]');

      const card = find('[data-test-id="modalWindow"]')!;
      assert
        .dom(card)
        .hasClass('invisible', 'the back-compat class is still emitted')
        .hasClass('ember-remodal-invisible', 'and the namespaced one');

      const style = getComputedStyle(card);
      assert.strictEqual(
        style.backgroundColor,
        'rgba(0, 0, 0, 0)',
        'the card is transparent',
      );
      assert.strictEqual(style.paddingTop, '0px', 'and unpadded');
      assert.strictEqual(
        style.pointerEvents,
        'none',
        'clicks fall through the empty card area to the backdrop',
      );
    });

    test('a Bootstrap-style .invisible cannot hide the modal', async function (assert) {
      // Bootstrap 3, 4 and 5 all ship `.invisible { visibility: hidden
      // !important }`. Against the old `.invisible.remodal.window` rules that
      // won outright, so @disableForeground rendered a fully hidden modal that
      // still held the top layer and trapped focus.
      const dispose = addStyleSheet(
        '.invisible { visibility: hidden !important }',
        'last',
      );
      try {
        await render(
          <template>
            <EmberRemodal
              @openButton="Open"
              @ariaLabel="Ghost"
              @disableForeground={{true}}
              @disableAnimation={{true}}
            >
              <p data-test-ghost>Frameless content</p>
            </EmberRemodal>
          </template>,
        );
        await click('[data-test-id="openButton"]');

        assert.strictEqual(
          getComputedStyle(find('[data-test-id="modalWindow"]')!).visibility,
          'visible',
          'the card survives a third-party !important',
        );
        assert.strictEqual(
          getComputedStyle(find('[data-test-ghost]')!).visibility,
          'visible',
          'and so does its content',
        );
      } finally {
        dispose();
      }
    });

    test('a backdrop click still closes a frameless modal', async function (assert) {
      // Load-bearing through the rename: `pointer-events: none` on the card with
      // `auto` on its children is what lets a click on the empty card area
      // reach the dialog and trigger closeOnOutsideClick.
      await render(
        <template>
          <EmberRemodal
            @openButton="Open"
            @ariaLabel="Ghost"
            @disableForeground={{true}}
            @disableAnimation={{true}}
          >
            <p data-test-ghost>Frameless content</p>
          </EmberRemodal>
        </template>,
      );
      await click('[data-test-id="openButton"]');
      assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-opened');

      assert.strictEqual(
        getComputedStyle(find('[data-test-ghost]')!.parentElement!)
          .pointerEvents,
        'auto',
        'the content wrapper stays interactive',
      );

      // A real click over the empty card area hits the dialog, because the card
      // does not accept pointer events.
      const cardRect = rect('[data-test-id="modalWindow"]');
      const target = document.elementFromPoint(
        Math.round(cardRect.x + 2),
        Math.round(cardRect.y + 2),
      );
      assert.strictEqual(
        target,
        dialog(),
        'a point over the empty card area hit-tests to the dialog',
      );

      await click('[data-test-id="modalWrapper"]');
      assert.dom('[data-test-id="modalWindow"]').hasClass('remodal-is-closed');
      assert.false(
        dialog().open,
        'the frameless modal closed on outside click',
      );
    });
  });

  module('animation contract', function () {
    test('every keyframe animation is namespaced and targets only the dialog or the card', function (assert) {
      // `ownAnimations()` recognises the component's own animations by exactly
      // two conditions: the animation name starts with `remodal-`, and the
      // effect target is the <dialog> or `.remodal`. A keyframe that breaks
      // either one is one that open()/close() will never await.
      const names = [...css.matchAll(/@keyframes\s+([\w-]+)/g)].map(
        (match) => match[1]!,
      );
      assert.ok(names.length > 0, `found keyframes: ${names.join(', ')}`);
      for (const name of names) {
        assert.ok(
          name.startsWith('remodal-'),
          `@keyframes ${name} is namespaced`,
        );
      }

      const users = ownStyleRules().filter((rule) =>
        rule.style.animationName.startsWith('remodal-'),
      );
      assert.ok(users.length > 0, 'some rules apply those animations');
      for (const rule of users) {
        for (const selector of rule.selectorText.split(',')) {
          const trimmed = selector.trim();
          assert.ok(
            /^dialog\.remodal-wrapper[\w.-]*(::backdrop)?$/.test(trimmed) ||
              /^\.remodal[\w.-]*$/.test(trimmed),
            `${trimmed} targets the dialog or the card`,
          );
        }
      }
    });
  });
});

/** Every top-level style rule in the addon's own stylesheet. */
function ownStyleRules(): CSSStyleRule[] {
  return addonSheets().flatMap((sheet) =>
    [...sheet.cssRules].filter(
      (rule): rule is CSSStyleRule => rule instanceof CSSStyleRule,
    ),
  );
}

/** The style rules inside a given media block of the addon's stylesheet. */
function mediaBlock(condition: string): CSSStyleRule[] {
  return addonSheets()
    .flatMap((sheet) => [...sheet.cssRules])
    .filter(
      (rule): rule is CSSMediaRule =>
        rule instanceof CSSMediaRule &&
        rule.conditionText.replace(/\s/g, '') === condition.replace(/\s/g, ''),
    )
    .flatMap((rule) =>
      [...rule.cssRules].filter(
        (inner): inner is CSSStyleRule => inner instanceof CSSStyleRule,
      ),
    );
}

/** Merged declarations of every rule in `rules` whose selector list includes `selector`. */
function declarationsFor(
  rules: CSSStyleRule[],
  selector: string,
): CSSStyleDeclaration {
  const merged = document.createElement('div').style;
  for (const rule of rules) {
    if (
      rule.selectorText
        .split(',')
        .some((candidate) => candidate.trim() === selector)
    ) {
      for (const property of rule.style) {
        merged.setProperty(
          property,
          rule.style.getPropertyValue(property),
          rule.style.getPropertyPriority(property),
        );
      }
    }
  }
  return merged;
}

function matchingSelectors(selector: string): CSSStyleRule[] {
  return ownStyleRules().filter((rule) =>
    rule.selectorText
      .split(',')
      .some((candidate) => candidate.trim() === selector),
  );
}

/** The document stylesheets that contain the addon's theme. */
function addonSheets(): CSSStyleSheet[] {
  return [...document.styleSheets].filter((sheet) => {
    try {
      return [...sheet.cssRules].some(
        (rule) =>
          rule instanceof CSSStyleRule &&
          rule.selectorText.includes('.remodal-wrapper'),
      );
    } catch {
      return false;
    }
  });
}
