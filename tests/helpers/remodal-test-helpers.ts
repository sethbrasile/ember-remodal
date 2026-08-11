import { settled } from '@ember/test-helpers';
import { remodalDialog, remodalDialogs } from '#src/test-support/index.ts';
import type { TestContext } from '@ember/test-helpers';
import type RemodalService from '#src/services/remodal.ts';

/**
 * The addon's own published helpers, re-exported under the short names this
 * suite has always used. `dialog()` throws when more than one modal is rendered
 * and the lookup was not scoped — the previous single-`find()` shape silently
 * returned the first match, which is why nothing here could test stacked
 * modals. Pass a scope (`dialog('[data-test-inner]')`) or use `dialogs()`.
 */
export const dialog = remodalDialog;
export const dialogs = remodalDialogs;

export function lookupService(context: TestContext): RemodalService {
  return context.owner.lookup('service:remodal');
}

/**
 * Faithfully simulates a backgrounded tab: the browser suspends
 * requestAnimationFrame (and stops advancing CSS animations) while
 * `document.visibilityState === 'hidden'`. Returns a restore function.
 *
 * Do not call `settled()` while frames are suspended.
 */
export function suspendAnimationFrames(): () => void {
  const original = window.requestAnimationFrame;
  window.requestAnimationFrame = () => 0;
  return () => {
    window.requestAnimationFrame = original;
  };
}

/** Shadows `document.hidden` with an own property; returns a restore function. */
export function hideDocument(): () => void {
  Object.defineProperty(document, 'hidden', {
    configurable: true,
    get: () => true,
  });
  return () => {
    Reflect.deleteProperty(document, 'hidden');
  };
}

/**
 * Resolves 'settled' if `promise` settles (either way) within `ms`, otherwise
 * 'pending'. Lets a test assert that a promise settles at all without hanging
 * the whole suite when the bug under test leaves it dangling forever.
 */
export function settlesWithin(
  promise: Promise<unknown>,
  ms: number,
): Promise<'settled' | 'pending'> {
  let timer: number | undefined;
  const settledOutcome = promise.then(
    () => 'settled' as const,
    () => 'settled' as const,
  );
  const timeout = new Promise<'pending'>((resolve) => {
    timer = window.setTimeout(() => resolve('pending'), ms);
  });
  return Promise.race([settledOutcome, timeout]).finally(() => {
    window.clearTimeout(timer);
  });
}

/**
 * Resolves an element's accessible name the way the accname algorithm's
 * name-from-author steps do: `aria-labelledby` (resolved to its targets' text)
 * outranks `aria-label`, which outranks the `title` fallback. A dangling
 * `aria-labelledby` idref contributes nothing — which is the failure a naive
 * "the attribute is present" assertion would sail straight past.
 *
 * Name-from-contents is deliberately NOT implemented: `role="dialog"` does not
 * support it, and for the close button the whole point of the fix is that an
 * authored `aria-label` outranks contents (the ::before glyph) while `title`
 * does not.
 */
export function authoredAccessibleName(element: Element): string {
  const labelledBy = element.getAttribute('aria-labelledby');
  if (labelledBy !== null) {
    const name = labelledBy
      .split(/\s+/)
      .filter(Boolean)
      .map((id) => element.ownerDocument.getElementById(id))
      .map((target) => (target?.textContent ?? '').trim())
      .filter(Boolean)
      .join(' ');
    if (name !== '') {
      return name;
    }
  }
  const label = element.getAttribute('aria-label')?.trim();
  if (label) {
    return label;
  }
  return element.getAttribute('title')?.trim() ?? '';
}

/**
 * Runs `body` with `console.warn` captured, and hands back everything Ember's
 * `warn` (and anything else) emitted while it ran.
 */
export async function captureWarnings(body: () => unknown): Promise<string[]> {
  const warnings: string[] = [];
  const originalWarn = console.warn;
  console.warn = (...args: unknown[]) => {
    warnings.push(String(args[0]));
  };
  try {
    await body();
  } finally {
    console.warn = originalWarn;
  }
  return warnings;
}

/**
 * Presses Escape inside an open modal and resolves with the event's
 * `defaultPrevented`.
 *
 * The native `cancel` event is what the browser fires on Esc inside an open
 * <dialog>; synthetic keyboard events do not trigger it, so dispatch it
 * directly. Returning `defaultPrevented` is load-bearing: a synthetic `cancel`
 * has no browser default action, so `handleNativeCancel`'s `preventDefault()`
 * is invisible in a test that only inspects the resulting state — delete the
 * call and every "Escape" assertion still passes, while the real browser
 * force-closes the dialog without playing the closing animation.
 */
export async function pressEscape(
  target: HTMLDialogElement = dialog(),
): Promise<boolean> {
  const event = new Event('cancel', { cancelable: true });
  target.dispatchEvent(event);
  await settled();
  return event.defaultPrevented;
}
