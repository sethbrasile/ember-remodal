import { module, test } from 'qunit';
import { setupRenderingTest } from 'ember-qunit';
import { render } from '@ember/test-helpers';
import EmberRemodal from '#src/components/ember-remodal.gts';
import componentSource from '../../src/components/ember-remodal.gts?raw';
import { dialog } from '../helpers/remodal-test-helpers.ts';
import { setupRemodal } from '#src/test-support/index.ts';
import type { EmberRemodalOptions } from '#src/components/ember-remodal.gts';

/**
 * The blank-string class.
 *
 * The accname algorithm trims and collapses whitespace, so `" "` names nothing.
 * A consumer string that is only whitespace is therefore not a label — but it
 * IS truthy, so every `{{#if (this.opt "x")}}` in the template treated it as
 * one. That defect surfaced three times in three consecutive review units, on a
 * different argument each time: `@title` (an h2 with no perceivable text and an
 * aria-labelledby pointing at it), `@cancelButton` (a nameless button the
 * keyboard-exit enumeration counted as the way out of a modal with
 * `@closeOnEscape={{false}}`), and the open triggers (a nameless trigger).
 *
 * So this module does not test three arguments. It enumerates the string-valued
 * arguments from the source of `EmberRemodalOptions` and requires each one to be
 * either covered by a case below or listed in EXEMPT with a reason — a new
 * string argument cannot join the class silently.
 */

/** Whitespace-only and empty both mean "absent". */
const BLANK_VALUES = ['', '   '] as const;

interface BlankStringCase {
  /** The `EmberRemodalOptions` key under test. */
  arg: keyof EmberRemodalOptions;
  /** A real value, used to prove the blank assertions are not vacuous. */
  sample: string;
  /** Other options needed for the element under test to be reachable. */
  base: EmberRemodalOptions;
  /** Asserted after rendering with a blank value. */
  absent: (assert: Assert) => void;
  /** Asserted after rendering with `sample`. */
  present: (assert: Assert, sample: string) => void;
}

const CASES: BlankStringCase[] = [
  {
    arg: 'title',
    sample: 'Delete this record?',
    base: {},
    absent(assert) {
      assert
        .dom('[data-test-id="title"]')
        .doesNotExist('a blank title renders no heading');
      assert
        .dom('[data-test-id="modalWrapper"]')
        .doesNotHaveAttribute(
          'aria-labelledby',
          'and no idref pointing at a heading that is not there',
        );
    },
    present(assert, sample) {
      assert.dom('[data-test-id="title"]').hasText(sample);
      assert
        .dom('[data-test-id="modalWrapper"]')
        .hasAttribute('aria-labelledby');
    },
  },
  {
    arg: 'text',
    sample: 'This cannot be undone.',
    base: {},
    absent(assert) {
      assert
        .dom('[data-test-id="text"]')
        .doesNotExist('a blank text renders no empty paragraph');
    },
    present(assert, sample) {
      assert.dom('[data-test-id="text"]').hasText(sample);
    },
  },
  {
    arg: 'ariaLabel',
    sample: 'Session expiry notice',
    base: {},
    absent(assert) {
      assert
        .dom('[data-test-id="modalWrapper"]')
        .doesNotHaveAttribute(
          'aria-label',
          'a blank aria-label is not emitted, so it cannot shadow another name',
        );
    },
    present(assert, sample) {
      assert
        .dom('[data-test-id="modalWrapper"]')
        .hasAttribute('aria-label', sample);
    },
  },
  {
    arg: 'ariaLabelledBy',
    sample: 'consumer-authored-heading',
    base: {},
    absent(assert) {
      assert
        .dom('[data-test-id="modalWrapper"]')
        .doesNotHaveAttribute(
          'aria-labelledby',
          'a blank idref resolves to nothing and is not emitted',
        );
    },
    present(assert, sample) {
      assert
        .dom('[data-test-id="modalWrapper"]')
        .hasAttribute('aria-labelledby', sample);
    },
  },
  {
    arg: 'closeButtonLabel',
    sample: 'Dismiss',
    base: {},
    absent(assert) {
      assert
        .dom('[data-test-id="nativeClose"]')
        .hasAttribute(
          'aria-label',
          'Close Modal',
          'a blank label falls back to the default rather than naming nothing',
        )
        .hasAttribute('title', 'Close Modal');
    },
    present(assert, sample) {
      assert
        .dom('[data-test-id="nativeClose"]')
        .hasAttribute('aria-label', sample)
        .hasAttribute('title', sample);
    },
  },
  {
    arg: 'confirmButton',
    sample: 'Yes',
    base: {},
    absent(assert) {
      assert
        .dom('[data-test-id="confirmButton"]')
        .doesNotExist('a blank label renders no confirm button');
    },
    present(assert, sample) {
      assert.dom('[data-test-id="confirmButton"]').hasText(sample);
    },
  },
  {
    arg: 'cancelButton',
    sample: 'No',
    base: {},
    absent(assert) {
      assert
        .dom('[data-test-id="cancelButton"]')
        .doesNotExist('a blank label renders no cancel button');
    },
    present(assert, sample) {
      assert.dom('[data-test-id="cancelButton"]').hasText(sample);
    },
  },
  {
    arg: 'openButton',
    sample: 'Open',
    base: {},
    absent(assert) {
      assert
        .dom('[data-test-id="openButton"]')
        .doesNotExist('a blank label renders no nameless trigger (WCAG 4.1.2)');
    },
    present(assert, sample) {
      assert.dom('[data-test-id="openButton"]').hasText(sample);
    },
  },
  {
    arg: 'openLink',
    sample: 'Open',
    base: {},
    absent(assert) {
      assert
        .dom('[data-test-id="openLink"]')
        .doesNotExist('a blank label renders no nameless trigger (WCAG 4.1.2)');
    },
    present(assert, sample) {
      assert.dom('[data-test-id="openLink"]').hasText(sample);
    },
  },
  {
    arg: 'linkButton',
    sample: 'Open',
    base: {},
    absent(assert) {
      assert
        .dom('[data-test-id="linkButton"]')
        .doesNotExist('a blank label renders no nameless trigger (WCAG 4.1.2)');
    },
    present(assert, sample) {
      assert.dom('[data-test-id="linkButton"]').hasText(sample);
    },
  },
];

/**
 * String arguments that are deliberately NOT in the class, each with the reason
 * it is out. None of them decides whether an element renders, supplies an
 * accessible name, or is counted as a control: they are class tokens, a test
 * hook and a registry key, all of which a consumer may legitimately pass as a
 * blank string (whitespace in a class attribute is collapsed by the parser and
 * changes nothing).
 */
const EXEMPT: Record<string, string> = {
  name: 'registry key + a class token on the card; names no element and gates no render',
  dataTestId: 'test hook attribute; not an accessible name and gates no render',
  modifier: 'class token on the <dialog> and the card',
  modalClasses: 'class token',
  buttonClasses: 'class token',
  outerButtonClasses: 'class token',
  innerButtonClasses: 'class token',
  openButtonClasses: 'class token',
  openLinkClasses: 'class token',
  cancelButtonClasses: 'class token',
  confirmButtonClasses: 'class token',
};

/** The string-valued keys of `EmberRemodalOptions`, read from the source. */
function stringOptionKeys(): string[] {
  const start = componentSource.indexOf(
    'export interface EmberRemodalOptions {',
  );
  if (start === -1) {
    throw new Error(
      'could not find `export interface EmberRemodalOptions` in the component source',
    );
  }
  const end = componentSource.indexOf('\n}', start);
  if (end === -1) {
    throw new Error('could not find the end of the EmberRemodalOptions body');
  }
  const body = componentSource.slice(start, end);
  // Accept `name?: string;`, `name?: string | undefined;`, any indentation
  // and a trailing comment, so a new member cannot escape the enumeration on
  // formatting alone.
  return Array.from(
    body.matchAll(
      /^\s*(\w+)\?:\s*string(?:\s*\|\s*undefined)?\s*;\s*(?:\/\/.*)?$/gm,
    ),
  ).map((match) => match[1]!);
}

module('Rendering | ember-remodal | blank string arguments', function (hooks) {
  setupRenderingTest(hooks);
  setupRemodal(hooks);

  // --- the guard: the population cannot grow without a decision -------------

  test('every string-valued option is either blank-guarded or exempt with a reason', function (assert) {
    const declared = stringOptionKeys();

    assert.true(
      declared.length > 10,
      `the interface parse found real keys (got: ${JSON.stringify(declared)})`,
    );

    const accounted = new Set([
      ...CASES.map((testCase) => testCase.arg as string),
      ...Object.keys(EXEMPT),
    ]);
    const unaccounted = declared.filter((key) => !accounted.has(key));

    assert.deepEqual(
      unaccounted,
      [],
      'a new string argument must either get a blank-string case above or be listed in EXEMPT with a reason',
    );

    const stale = [...accounted].filter((key) => !declared.includes(key));
    assert.deepEqual(
      stale,
      [],
      'and nothing accounted for here has been removed from the interface',
    );
  });

  // --- the treatment, argument by argument ----------------------------------

  for (const testCase of CASES) {
    for (const blank of BLANK_VALUES) {
      test(`@${testCase.arg}=${JSON.stringify(blank)} is treated as absent`, async function (assert) {
        const options: EmberRemodalOptions = {
          ...testCase.base,
          [testCase.arg]: blank,
        };
        await render(
          <template><EmberRemodal @options={{options}} /></template>,
        );

        testCase.absent(assert);
      });
    }

    test(`@${testCase.arg} with a real value still renders (the blank cases are not vacuous)`, async function (assert) {
      const options: EmberRemodalOptions = {
        ...testCase.base,
        [testCase.arg]: testCase.sample,
      };
      await render(<template><EmberRemodal @options={{options}} /></template>);

      testCase.present(assert, testCase.sample);
    });
  }

  // --- the trigger chain is an if/else-if, so blanks must fall through -------

  test('a blank @linkButton falls through to @openLink', async function (assert) {
    await render(
      <template>
        <EmberRemodal @linkButton=" " @openLink="Open link" />
      </template>,
    );

    assert.dom('[data-test-id="linkButton"]').doesNotExist();
    assert.dom('[data-test-id="openLink"]').hasText('Open link');
  });

  test('blank @linkButton and @openLink fall through to @openButton', async function (assert) {
    await render(
      <template>
        <EmberRemodal @linkButton=" " @openLink="  " @openButton="Open" />
      </template>,
    );

    assert.dom('[data-test-id="linkButton"]').doesNotExist();
    assert.dom('[data-test-id="openLink"]').doesNotExist();
    assert.dom('[data-test-id="openButton"]').hasText('Open');
  });

  test('a modal whose every trigger is blank renders no trigger at all', async function (assert) {
    await render(
      <template>
        <EmberRemodal @linkButton=" " @openLink=" " @openButton=" " />
      </template>,
    );

    assert
      .dom('[data-test-id="modalWrapper"]')
      .exists('the modal itself still renders');
    assert.strictEqual(
      dialog().parentElement?.querySelectorAll('a, button.ember-remodal-outer')
        .length,
      0,
      'and it is reachable only through the service or a yielded m.open',
    );
  });
});
