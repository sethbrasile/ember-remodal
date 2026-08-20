import { module, test } from 'qunit';
import { setupRemodal } from '#src/test-support/index.ts';
import type {
  RemodalTestAssert,
  RemodalTestHooks,
} from '#src/test-support/index.ts';

interface PushedResult {
  result: boolean;
  actual: unknown;
  expected: unknown;
  message: string;
}

/**
 * `setupRemodal`'s hooks only run inside a real QUnit module, so the only way to
 * assert what they do — including that they FAIL a leaking test — is to drive
 * them directly with stand-in hooks and a stand-in assert. Without this, the
 * leak detector is a mechanism the suite trusts but never exercises: it would
 * still "pass" if it silently stopped reporting.
 */
function collectHooks(options?: { disableAnimation?: boolean }) {
  const before: ((assert: RemodalTestAssert) => void)[] = [];
  const after: ((assert: RemodalTestAssert) => void)[] = [];
  const hooks: RemodalTestHooks = {
    beforeEach: (callback) => before.push(callback),
    afterEach: (callback) => after.push(callback),
  };
  setupRemodal(hooks, options);

  const pushed: PushedResult[] = [];
  const assertStub: RemodalTestAssert = {
    pushResult: (result) => pushed.push(result),
  };
  return {
    pushed,
    runBeforeEach: () => before.forEach((callback) => callback(assertStub)),
    runAfterEach: () => after.forEach((callback) => callback(assertStub)),
  };
}

function lockDocument(): void {
  document.documentElement.classList.add('remodal-is-locked');
}

module('Unit | test-support | setupRemodal', function (hooks) {
  hooks.afterEach(function () {
    // This module deliberately dirties the very state the helper cleans up.
    document.documentElement.classList.remove('remodal-is-locked');
    document.body.style.paddingRight = '';
  });

  test('afterEach reports a leaked lock and force-releases it', function (assert) {
    const { pushed, runAfterEach } = collectHooks();

    // A padding the addon never set: the reset must leave it alone, because it
    // has no saved value to restore and guessing '' would silently break an app
    // (or another addon) that owns that inline style. Restoring a padding the
    // addon DID set is covered end to end by the stacked-modal test.
    document.body.style.paddingRight = '15px';

    lockDocument();
    runAfterEach();

    assert.strictEqual(pushed.length, 1, 'exactly one failure was reported');
    assert.false(pushed[0]?.result, 'and it is a failure, not a pass');
    assert.true(
      pushed[0]?.message.includes('still engaged when this test finished'),
      `the message names the leak (got: ${pushed[0]?.message ?? 'nothing'})`,
    );
    assert
      .dom(document.documentElement)
      .doesNotHaveClass(
        'remodal-is-locked',
        'the lock was force-released, so the next test starts clean',
      );
    assert.strictEqual(
      document.body.style.paddingRight,
      '15px',
      'a body padding the addon never set is left untouched',
    );
  });

  test('afterEach reports nothing when the lock was released properly', function (assert) {
    const { pushed, runAfterEach } = collectHooks();

    runAfterEach();

    assert.deepEqual(
      pushed,
      [],
      'a passing test gains no extra assertion, so assert.expect() counts are safe',
    );
  });

  test('beforeEach catches a leak that outlived a previous teardown', function (assert) {
    const { pushed, runBeforeEach } = collectHooks();

    lockDocument();
    runBeforeEach();

    assert.strictEqual(pushed.length, 1);
    assert.true(
      pushed[0]?.message.includes('before this test began'),
      `the message points at the previous test (got: ${pushed[0]?.message ?? 'nothing'})`,
    );
    assert
      .dom(document.documentElement)
      .doesNotHaveClass('remodal-is-locked', 'and it is cleared going in');
  });
});
