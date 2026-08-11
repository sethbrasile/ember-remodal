import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render, click, focus, settled, find } from '@ember/test-helpers';
import EmberRemodal from '#src/components/ember-remodal.gts';
import cssSource from '../../src/styles/ember-remodal.css?raw';
import { dialog } from '../helpers/remodal-test-helpers.ts';
import { setupRemodal } from '#src/test-support/index.ts';

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
  setupRemodal(hooks);

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
        dialogRect.right <= viewportWidth,
        `dialog right edge ${dialogRect.right} does not extend past the viewport ${viewportWidth}`,
      );
      assert.ok(
        dialogRect.bottom <= viewportHeight,
        `dialog bottom edge ${dialogRect.bottom} does not extend past the viewport ${viewportHeight}`,
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
        'text inflation is suppressed',
      );
      // Chrome ALIASES `text-size-adjust` onto `-webkit-text-size-adjust`, so
      // the computed read above is satisfied by the unprefixed declaration on
      // its own and stayed green when the prefixed one was deleted. The whole
      // point of the deviation is WebKit, which implements only the prefixed
      // form and is not the engine running this suite — the source is the only
      // place where the two are distinguishable from here.
      assert.ok(
        /-webkit-text-size-adjust:\s*100%/.test(css),
        'the prefixed declaration is really in the stylesheet, not just its Chrome alias',
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

    test('the close glyph clears WCAG 1.4.11 against the card', async function (assert) {
      // Upstream's #95979c measured 2.92:1 on the white card. The glyph is the
      // only thing identifying the control visually, so it is a graphical
      // object under 1.4.11 and needs 3:1 — and at 25px it clears 1.4.3's
      // large-text 3:1 too, whichever way you classify it.
      await render(
        <template>
          <EmberRemodal @openButton="Open" @disableAnimation={{true}} />
        </template>,
      );
      await click('[data-test-id="openButton"]');

      const close = find('[data-test-id="nativeClose"]')!;
      const style = getComputedStyle(close);
      const card = getComputedStyle(find('[data-test-id="modalWindow"]')!);
      const ratio = contrastRatio(style.color, card.backgroundColor);

      assert.ok(
        ratio >= 3,
        `close glyph: ${style.color} on ${card.backgroundColor} = ${ratio.toFixed(2)}:1 (>= 3:1)`,
      );
      assert.ok(
        parseFloat(getComputedStyle(close, '::before').fontSize) >= 24,
        'the glyph is large text (25px), so 3:1 is the right threshold',
      );
    });

    test('the contrast figures quoted in the docs are the ones the theme produces', async function (assert) {
      // README, CHANGELOG, MIGRATION and the stylesheet header all quote exact
      // ratios as the justification for the deliberate colour deviations. The
      // threshold assertions elsewhere in this module would survive any change
      // that stayed above the threshold, so the published numbers themselves
      // are pinned here — recomputed from the rendered elements, not from the
      // hex values, so a token change moves them.
      await render(
        <template>
          <EmberRemodal
            @openButton="Open"
            @title="Figures"
            @confirmButton="Yes"
            @cancelButton="No"
            @disableAnimation={{true}}
          />
        </template>,
      );
      await click('[data-test-id="openButton"]');

      const card = find('[data-test-id="modalWindow"]') as HTMLElement;
      const cardBackground = getComputedStyle(card).backgroundColor;

      for (const [id, published] of [
        ['confirmButton', '5.13'],
        ['cancelButton', '5.62'],
      ] as const) {
        const style = getComputedStyle(find(`[data-test-id="${id}"]`)!);
        assert.strictEqual(
          contrastRatio(style.color, style.backgroundColor).toFixed(2),
          published,
          `${id} measures the published ${published}:1`,
        );
      }

      // showModal() puts initial focus on the close button, and
      // `.remodal-close:focus` transitions its colour towards the hover value
      // over 0.2s — so a naive read here returns a value some way along that
      // transition, which is what made an exact-figure assertion flaky. The
      // published figure is the resting colour: drop focus and let the
      // transition back to it finish before measuring.
      const close = find('[data-test-id="nativeClose"]') as HTMLElement;
      close.blur();
      await Promise.all(
        close
          .getAnimations()
          .map((animation) => animation.finished.catch(() => undefined)),
      );
      const glyphColor = getComputedStyle(close).color;
      assert.strictEqual(
        contrastRatio(glyphColor, cardBackground).toFixed(2),
        '4.35',
        'the close glyph measures the published 4.35:1 against the card',
      );

      const inline = card.style.cssText;
      card.style.cssText = declaredStyle(assert, '.remodal:focus-visible');
      const ringColor = getComputedStyle(card).outlineColor;
      card.style.cssText = inline;
      assert.strictEqual(
        contrastRatio(ringColor, cardBackground).toFixed(1),
        '13.5',
        'the ink focus ring measures the published 13.5:1 on the light card',
      );
    });

    test('hover/focus backgrounds also clear AA', async function (assert) {
      // The hover colours are what a pointer user actually reads text against.
      // :hover cannot be synthesised from inside the page, so the next best
      // thing is measured here: the declaration is read off the addon's OWN
      // `.remodal-confirm:hover` / `.remodal-cancel:hover` rules and then
      // resolved on the real rendered button, in the real cascade. Deleting
      // either rule, or lowering either token, fails this test.
      //
      // The version this replaces built a detached <div>, fed it an injected
      // stylesheet that merely named the same custom property, and measured
      // that — proving the colour maths and nothing at all about the selectors,
      // so deleting both real rules left it green (QC-2-07).
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

      for (const [id, selector, token] of [
        [
          'confirmButton',
          '.remodal-confirm:hover',
          '--ember-remodal-confirm-background-hover',
        ],
        [
          'cancelButton',
          '.remodal-cancel:hover',
          '--ember-remodal-cancel-background-hover',
        ],
      ] as const) {
        const declaration = declaredStyle(assert, selector);
        assert.ok(
          declaration.includes(token),
          `${selector} paints its background from ${token} (${declaration})`,
        );

        const button = find(`[data-test-id="${id}"]`) as HTMLElement;
        const resting = getComputedStyle(button).backgroundColor;
        const inline = button.style.cssText;
        // `transition: background 0.2s` is part of the real rule set, and a
        // computed style read while a transition is running returns the value
        // it is animating FROM — the resting colour. Suppressed so the read is
        // of the hover colour rather than of the transition's first frame.
        button.style.cssText = `transition: none; ${declaration}`;
        const style = getComputedStyle(button);
        const hovered = style.backgroundColor;
        const ratio = contrastRatio(style.color, hovered);
        button.style.cssText = inline;

        assert.notStrictEqual(
          hovered,
          resting,
          `${id} hover (${hovered}) differs from its resting background (${resting})`,
        );
        assert.ok(
          ratio >= 4.5,
          `${id} hover: ${style.color} on ${hovered} = ${ratio.toFixed(2)}:1 (>= 4.5:1)`,
        );
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

      // `.remodal:focus-visible` is the only rule that draws the card's ring,
      // and neither of the obvious ways to check it works: a programmatically
      // focused, non-interactive element is not guaranteed to match
      // :focus-visible, and when it does, Chrome's own UA focus ring satisfies
      // a bare `outlineStyle !== 'none'` read with zero author CSS — which is
      // exactly why the version this replaces stayed green after the rule was
      // deleted (QC-2-06). Read the addon's own declaration instead and resolve
      // it on the real card, so the rule, the values it resolves to and the
      // contrast they produce are all under test.
      const declaration = declaredStyle(assert, '.remodal:focus-visible');
      const behind = effectiveBackground(card);
      const inline = card.style.cssText;
      card.style.cssText = declaration;
      const style = getComputedStyle(card);
      const outlineStyle = style.outlineStyle;
      const outlineWidth = style.outlineWidth;
      const outlineColor = style.outlineColor;
      const boxShadow = style.boxShadow;
      card.style.cssText = inline;

      assert.strictEqual(
        outlineStyle,
        'solid',
        `the card draws a solid focus outline (${outlineStyle} ${outlineWidth} ${outlineColor})`,
      );
      assert.ok(
        parseFloat(outlineWidth) >= 2,
        `the outline is at least 2px (${outlineWidth})`,
      );
      assert.notStrictEqual(
        boxShadow,
        'none',
        `the card draws the contrasting halo too (${boxShadow})`,
      );
      const haloColor = boxShadow.match(/rgba?\([^)]*\)/)?.[0];
      assert.ok(haloColor, `the halo colour is resolvable (${boxShadow})`);
      const ring = contrastRatio(outlineColor, behind);
      const halo = contrastRatio(haloColor!, behind);
      assert.ok(
        Math.max(ring, halo) >= 3,
        `card focus indicator contrast: outline ${ring.toFixed(2)}:1, halo ${halo.toFixed(2)}:1 (>= 3:1)`,
      );
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

      // Again with the consumer's declaration INSIDE `@layer ember-remodal`.
      // That is what the cascade looks like on an engine with no `@layer`
      // support (deviation eleven), where the layer separates nothing and the
      // only thing left protecting the override is that the addon declares its
      // tokens on `:where(html)` — zero specificity — against a consumer's
      // `:root` (0,1,0). Without this the `:where()` claim is untested: the
      // layer alone makes the assertions above pass at any specificity.
      const layered = addStyleSheet(
        '@layer ember-remodal { :root { --ember-remodal-background: rgb(9, 9, 9) } }',
        'first',
      );
      try {
        assert.strictEqual(
          getComputedStyle(find('[data-test-id="modalWindow"]')!)
            .backgroundColor,
          'rgb(9, 9, 9)',
          'a same-layer consumer rule still wins, because the defaults carry no specificity',
        );
      } finally {
        layered();
      }
    });

    test('an unlayered consumer rule beats the addon at equal specificity, layer-first or not', async function (assert) {
      // The addon's whole sheet is inside `@layer ember-remodal`. Unlayered
      // author CSS beats layered author CSS regardless of specificity OR source
      // order, so `.remodal { background }` — a straight tie with the addon's
      // own `.remodal`, loaded FIRST, which before the layer lost to the
      // addon's later sheet — now wins. This covers what the custom properties
      // cannot: geometry and layout, not just colour.
      const dispose = addStyleSheet(
        '.remodal { background: rgb(255, 0, 0); padding: 1px }',
        'first',
      );
      try {
        await render(
          <template>
            <EmberRemodal
              @openButton="Open"
              @title="Layered"
              @disableAnimation={{true}}
            />
          </template>,
        );
        await click('[data-test-id="openButton"]');

        const style = getComputedStyle(find('[data-test-id="modalWindow"]')!);
        assert.strictEqual(
          style.backgroundColor,
          'rgb(255, 0, 0)',
          'the unlayered consumer colour wins over the layered default',
        );
        assert.strictEqual(
          style.paddingTop,
          '1px',
          'and so does a non-colour declaration, which no custom property could carry',
        );
      } finally {
        dispose();
      }
    });

    test('the same rule inside the addon layer loses, a later layer wins', async function (assert) {
      // The control for the test above: identical selector, identical
      // declarations, identical position — but inside `@layer ember-remodal`,
      // so it is ordered by the layer rather than ahead of it. Earlier in the
      // same layer loses to the addon's own rule.
      //
      // That first half does NOT prove the layer is there: strip the wrapper
      // off the addon's sheet and it still passes, because unlayered CSS
      // outranks every layer, so an unlayered addon beats this layered rule
      // just as the layered addon does. The second half below is the half that
      // goes red when the wrapper comes off.
      const dispose = addStyleSheet(
        '@layer ember-remodal { .remodal { background: rgb(255, 0, 0); padding: 1px } }',
        'first',
      );
      try {
        await render(
          <template>
            <EmberRemodal
              @openButton="Open"
              @title="Layered"
              @disableAnimation={{true}}
            />
          </template>,
        );
        await click('[data-test-id="openButton"]');

        const style = getComputedStyle(find('[data-test-id="modalWindow"]')!);
        assert.strictEqual(
          style.backgroundColor,
          'rgb(255, 255, 255)',
          'the addon default still applies',
        );
        assert.strictEqual(style.paddingTop, '35px', 'and so does its padding');
      } finally {
        dispose();
      }

      // A consumer layer ordered after `ember-remodal` does win — which is only
      // true while the addon's rules are inside a layer at all. Unlayered CSS
      // outranks every layer, so if the wrapper came off the sheet the addon's
      // own `padding: 35px` would beat this.
      const later = addStyleSheet(
        '@layer ember-remodal, ember-remodal-consumer;' +
          '@layer ember-remodal-consumer { .remodal { padding: 2px } }',
        'first',
      );
      try {
        assert.strictEqual(
          getComputedStyle(find('[data-test-id="modalWindow"]')!).paddingTop,
          '2px',
          'a layer declared after ember-remodal overrides the addon',
        );
      } finally {
        later();
      }
    });

    test('a layered !important outranks an unlayered one', async function (assert) {
      // Deviation ten's accepted cost, pinned so it cannot change unnoticed.
      // For IMPORTANT declarations the cascade reverses layer order and puts
      // unlayered author styles last, so the sheet's two deliberate
      // `!important`s outrank a consumer `!important` — a consumer who needs to
      // win has to declare their own layer after `ember-remodal`, which is what
      // MIGRATION.md tells them. Without the wrapper the rule below would win
      // outright: same specificity, same origin, loaded later.
      const dispose = addStyleSheet(
        '.remodal-close::before { font-family: monospace !important }',
        'last',
      );
      try {
        await render(
          <template>
            <EmberRemodal @openButton="Open" @disableAnimation={{true}} />
          </template>,
        );
        await click('[data-test-id="openButton"]');

        const glyph = getComputedStyle(
          find('[data-test-id="nativeClose"]')!,
          '::before',
        );
        assert.ok(
          glyph.fontFamily.startsWith('Arial'),
          `the layered !important still paints the glyph (${glyph.fontFamily})`,
        );
      } finally {
        dispose();
      }
    });

    test('the stylesheet ships inside @layer ember-remodal', function (assert) {
      // A source-level guard on the wrapper itself, so removing it is a test
      // failure rather than a silent loss of the override contract.
      // Both the `#src` copy and the built `dist` copy are in the document
      // (published-package-test imports the package specifier), so assert per
      // sheet rather than over the flattened list.
      const sheets = addonSheets();
      assert.ok(sheets.length > 0, 'the addon sheet is in the document');
      for (const sheet of sheets) {
        const layers = [...sheet.cssRules].filter(
          (rule): rule is CSSLayerBlockRule =>
            rule instanceof CSSLayerBlockRule,
        );
        assert.deepEqual(
          layers.map((layer) => layer.name),
          ['ember-remodal'],
          'exactly one layer block, named ember-remodal',
        );
        assert.ok(
          layers[0]!.cssRules.length > 20,
          `the theme rules are inside it (${layers[0]!.cssRules.length} rules)`,
        );
        // Scoped to the addon's own selectors: the dev build bundles this
        // stylesheet together with the test harness's, whose rules legitimately
        // sit outside any layer.
        const strays = [...sheet.cssRules].filter(
          (rule): rule is CSSStyleRule =>
            rule instanceof CSSStyleRule && /remodal/.test(rule.selectorText),
        );
        assert.deepEqual(
          strays.map((rule) => rule.selectorText),
          [],
          'no addon style rule sits outside the layer',
        );
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
      assert.notStrictEqual(confirm.borderStyle, '', 'confirm gets a border');
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
      assert.notStrictEqual(
        declarationsFor(forced, '.remodal-close').borderStyle,
        '',
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
        .hasClass('ember-remodal-invisible', 'the namespaced class is emitted')
        .doesNotHaveClass(
          'invisible',
          'and the bare Bootstrap-owned one is retired (@legacyClassNames restores it)',
        );

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
      // still held the top layer and trapped focus. Two independent defences
      // now: the card does not carry the bare class at all unless the consumer
      // opts in, and the addon's `visibility: visible !important` outranks
      // Bootstrap's. Opted INTO the legacy classes here, so the second defence
      // is the one under test.
      //
      // Against Bootstrap's own rule the `!important` alone is what wins:
      // `.ember-remodal-invisible.remodal` (0,2,0) already outweighs
      // `.invisible` (0,1,0), and unwrapping the layer leaves this half green.
      // The second half below is where the layer is load-bearing.
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
              @legacyClassNames={{true}}
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

        // And against a more specific form of the same rule — an app whose
        // build emits the utility under a wrapper selector, or repeats the
        // class. (0,2,1) outweighs the addon's (0,2,0), so specificity no
        // longer saves the modal and the layer is what does: among important
        // author declarations, unlayered ones rank below every layer.
        const stronger = addStyleSheet(
          'body .invisible.invisible { visibility: hidden !important }',
          'last',
        );
        try {
          assert.strictEqual(
            getComputedStyle(find('[data-test-id="modalWindow"]')!).visibility,
            'visible',
            'and one that outweighs the addon on specificity as well',
          );
        } finally {
          stronger();
        }
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
          const targetsDialogOrCard =
            /^dialog\.remodal-wrapper[\w.-]*(::backdrop)?$/.test(trimmed) ||
            /^\.remodal[\w.-]*$/.test(trimmed);
          assert.true(
            targetsDialogOrCard,
            `${trimmed} targets the dialog or the card`,
          );
        }
      }
    });
  });
});

/**
 * A sheet's rules with `@layer` blocks flattened away. The addon's whole
 * stylesheet lives inside `@layer ember-remodal`, so its top level is a single
 * `CSSLayerBlockRule`; every helper here wants what is inside it. Nested
 * because a layer block may contain another. Media blocks are deliberately NOT
 * flattened — `mediaBlock()` addresses those by condition.
 */
function unlayered(rules: Iterable<CSSRule>): CSSRule[] {
  return [...rules].flatMap((rule) =>
    rule instanceof CSSLayerBlockRule ? unlayered(rule.cssRules) : [rule],
  );
}

/** Every top-level style rule in the addon's own stylesheet. */
function ownStyleRules(): CSSStyleRule[] {
  return addonSheets().flatMap((sheet) =>
    unlayered(sheet.cssRules).filter(
      (rule): rule is CSSStyleRule => rule instanceof CSSStyleRule,
    ),
  );
}

/** The style rules inside a given media block of the addon's stylesheet. */
function mediaBlock(condition: string): CSSStyleRule[] {
  return addonSheets()
    .flatMap((sheet) => unlayered(sheet.cssRules))
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

/**
 * The declaration block the addon declares for `selector`, as text ready to
 * assign to an element's `style.cssText` — which resolves its `var()`s in that
 * element's real cascade.
 *
 * This is how a rule that only applies in a state the test runner cannot enter
 * (`:hover`, and `:focus-visible` on a programmatically focused element) is
 * measured without a detached probe: the values come from the addon's own rule
 * and resolve against the real element, so deleting the rule empties the
 * declaration and the caller's assertions go red.
 *
 * The dev test build carries the stylesheet twice — the `#src` copy the
 * component imports and the `dist` copy `published-package-test` pulls in via
 * the package specifier — so more than one match is expected; they must agree.
 */
function declaredStyle(assert: Assert, selector: string): string {
  const rules = matchingSelectors(selector);
  assert.ok(rules.length > 0, `${selector} is declared by the addon`);
  const declarations = [...new Set(rules.map((rule) => rule.style.cssText))];
  assert.strictEqual(
    declarations.length,
    Math.min(rules.length, 1),
    `every copy of ${selector} declares the same thing (${declarations.join(' | ')})`,
  );
  return declarations[0] ?? '';
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
      return unlayered(sheet.cssRules).some(
        (rule) =>
          rule instanceof CSSStyleRule &&
          rule.selectorText.includes('.remodal-wrapper'),
      );
    } catch {
      return false;
    }
  });
}
