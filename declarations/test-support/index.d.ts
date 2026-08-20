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
export declare function resetRemodalScrollLock(): void;
/**
 * Turns the open/close animations off (or back on) for every modal, process
 * wide. Prefer `setupRemodal(hooks, { disableAnimation: true })`, which also
 * turns it back off again when the test module is done.
 */
export declare function setRemodalAnimationDisabled(disabled: boolean): void;
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
export declare function setupRemodal(hooks: RemodalTestHooks, options?: SetupRemodalOptions): void;
/**
 * Every rendered modal `<dialog>`, in document order — the helper to reach for
 * with stacked modals. Pass a selector or element to scope the search.
 */
export declare function remodalDialogs(scope?: string | ParentNode): HTMLDialogElement[];
/**
 * The one rendered modal `<dialog>`. Throws when there is none, or when there
 * is more than one and the search was not scoped — an ambiguous `find()` that
 * silently returns the first match is how a stacked-modal test ends up
 * asserting against the wrong element.
 */
export declare function remodalDialog(scope?: string | ParentNode): HTMLDialogElement;
//# sourceMappingURL=index.d.ts.map