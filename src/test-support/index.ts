import {
  resetScrollLockForTesting,
  scrollLockStateForTesting,
  setAnimationDisabledForTesting,
} from '../components/ember-remodal.gts';
import type { ScrollLockState } from '../components/ember-remodal.gts';

// NOTE: this docblock sits BELOW the imports on purpose. ember-eslint-parser
// mis-maps source offsets when a comment containing non-ASCII characters
// precedes the import block, and reports a bogus parse error on the last one.
/**
 * Test support for applications that render ember-remodal.
 *
 *     import { setupRemodal } from 'ember-remodal/test-support';
 *
 *     module('Integration | checkout', function (hooks) {
 *       setupRenderingTest(hooks);
 *       setupRemodal(hooks, { disableAnimation: true });
 *     });
 *
 * Why this exists: the addon keeps two pieces of state outside every component
 * instance — the shared scroll lock (a class on `<html>` plus an inline style on
 * `<body>`, both OUTSIDE `#ember-testing` and `#qunit-fixture`) and the
 * test-only animation switch. Neither is reachable by QUnit's fixture reset or
 * by `setupRenderingTest`'s teardown, so a test that ends with a transition
 * still in flight leaves the lock engaged for every test that follows.
 * `setupRemodal` closes that seam.
 *
 * Deliberately free of imports from `qunit` and `@ember/test-helpers`: this
 * module is published, and a published entry point that reaches for packages the
 * addon does not depend on is a resolution failure waiting to happen. The hook
 * and assert shapes below are structural, and QUnit's own `NestedHooks` /
 * `Assert` satisfy them.
 */

const CLEAN_LOCK: ScrollLockState = {
  holders: 0,
  locked: false,
  bodyPaddingRight: '',
};

const LEAK_PREFIX = "ember-remodal: the document's scroll lock";

const FORCE_RESET_NOTE =
  'It has been force-released, so the tests after this one are unaffected — this failure is the leak itself, not a consequence of one.';

/** The `<dialog>` element of a rendered modal. */
const DIALOG_SELECTOR = '[data-test-id="modalWrapper"]';

/** Structural stand-in for QUnit's `Assert` (only what this module calls). */
export interface RemodalTestAssert {
  pushResult(result: {
    result: boolean;
    actual: unknown;
    expected: unknown;
    message: string;
  }): void;
}

/** Structural stand-in for QUnit's `NestedHooks`. */
export interface RemodalTestHooks {
  beforeEach(callback: (assert: RemodalTestAssert) => void): void;
  afterEach(callback: (assert: RemodalTestAssert) => void): void;
}

export interface SetupRemodalOptions {
  /**
   * Skip the open/close animations for every ember-remodal modal rendered in
   * this module, so `open()`/`close()` resolve without waiting ~300ms each.
   *
   * This replaces the 2.x `config/environment` flag
   * (`ENV['ember-remodal'] = { disableAnimationWhileTesting: true }`), which
   * only ever worked in classic-resolver apps.
   */
  disableAnimation?: boolean;
}

/**
 * Force-releases the shared scroll lock: removes `remodal-is-locked` from
 * `<html>`, restores whatever `body.style.padding-right` was before the lock,
 * and drops the addon's record of which modals hold it.
 *
 * `setupRemodal` calls this for you. Call it directly only if you manage QUnit
 * hooks yourself.
 */
export function resetRemodalScrollLock(): void {
  resetScrollLockForTesting();
}

/**
 * Turns the open/close animations off (or back on) for every modal, process
 * wide. Prefer `setupRemodal(hooks, { disableAnimation: true })`, which also
 * turns it back off again when the test module is done.
 */
export function setRemodalAnimationDisabled(disabled: boolean): void {
  setAnimationDisabledForTesting(disabled);
}

/**
 * Installs the teardown the addon's module-level state needs:
 *
 * - resets the scroll lock before AND after every test, so a leak becomes one
 *   localized failure instead of a cascade through every later test;
 * - fails the test that leaked (and only that test) with a diagnostic;
 * - applies and then unwinds `disableAnimation`.
 *
 * The leak report is pushed only when there is a leak, so it never disturbs an
 * `assert.expect(n)` count in a passing test.
 */
export function setupRemodal(
  hooks: RemodalTestHooks,
  options: SetupRemodalOptions = {},
): void {
  const { disableAnimation = false } = options;

  hooks.beforeEach(function (assert) {
    // The lock must never be engaged as a test STARTS. If it is, the leak
    // outlived a previous test's teardown entirely — the one failure mode the
    // afterEach hook below cannot see, because it runs before that teardown.
    const state = scrollLockStateForTesting();
    resetScrollLockForTesting();
    setAnimationDisabledForTesting(disableAnimation);

    if (state.holders > 0 || state.locked) {
      assert.pushResult({
        result: false,
        actual: state,
        expected: CLEAN_LOCK,
        message: `${LEAK_PREFIX} was already engaged before this test began, so an earlier test leaked it past its own teardown. ${FORCE_RESET_NOTE}`,
      });
    }
  });

  hooks.afterEach(function (assert) {
    const state = scrollLockStateForTesting();
    // A modal that is still rendered and not closed legitimately holds the
    // lock: this hook runs BEFORE `setupRenderingTest`'s teardown (QUnit runs
    // afterEach hooks in reverse registration order), and destroying the modal
    // is what releases it. `setupTestIsolationValidation` is what catches the
    // related "finished with a transition still in flight" case.
    const accountedFor = remodalDialogs().some(
      (element) =>
        element.open || !element.classList.contains('remodal-is-closed'),
    );
    // Reset unconditionally, before judging: the force-reset is the
    // load-bearing half, and it turns a cascade into one localized failure.
    setAnimationDisabledForTesting(false);
    resetScrollLockForTesting();

    if (!accountedFor && (state.holders > 0 || state.locked)) {
      assert.pushResult({
        result: false,
        actual: state,
        expected: CLEAN_LOCK,
        message: `${LEAK_PREFIX} was still engaged when this test finished, with no open modal left to account for it. ${FORCE_RESET_NOTE}`,
      });
    }
  });
}

function resolveScope(scope: string | ParentNode = document): ParentNode {
  if (typeof scope !== 'string') {
    return scope;
  }
  const root = document.querySelector(scope);
  if (!root) {
    throw new Error(
      `ember-remodal/test-support: no element matched the scope selector "${scope}".`,
    );
  }
  return root;
}

/**
 * Every rendered modal `<dialog>`, in document order — the helper to reach for
 * with stacked modals. Pass a selector or element to scope the search.
 */
export function remodalDialogs(
  scope?: string | ParentNode,
): HTMLDialogElement[] {
  const root = resolveScope(scope);
  // A scope that IS a modal dialog names that dialog, rather than the modals
  // nested inside its content — which is what makes a modal-inside-a-modal
  // addressable at all.
  if (root instanceof HTMLDialogElement && root.matches(DIALOG_SELECTOR)) {
    return [root];
  }
  return Array.from(root.querySelectorAll<HTMLDialogElement>(DIALOG_SELECTOR));
}

/**
 * The one rendered modal `<dialog>`. Throws when there is none, or when there
 * is more than one and the search was not scoped — an ambiguous `find()` that
 * silently returns the first match is how a stacked-modal test ends up
 * asserting against the wrong element.
 */
export function remodalDialog(scope?: string | ParentNode): HTMLDialogElement {
  const dialogs = remodalDialogs(scope);
  if (dialogs.length === 0) {
    throw new Error(
      'ember-remodal/test-support: no modal <dialog> is rendered (looked for `[data-test-id="modalWrapper"]`).',
    );
  }
  if (dialogs.length > 1) {
    throw new Error(
      `ember-remodal/test-support: ${dialogs.length} modal <dialog> elements are rendered. Scope the lookup (remodalDialog('[data-test-id="my-modal"]')) or use remodalDialogs().`,
    );
  }
  return dialogs[0]!;
}
