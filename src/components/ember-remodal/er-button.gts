import Component from '@glimmer/component';
import { warn } from '@ember/debug';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';

export interface ErButtonSignature {
  Args: {
    destination?: Element | null;
    onClick: (event?: Event) => unknown;
  };
  Blocks: {
    default: [];
  };
  Element: HTMLSpanElement;
}

// Anything that can take keyboard focus. Deliberately lenient — disabled
// controls, `tabindex="-1"` and programmatically-focused containers all count,
// because a false "your trigger is keyboard-unreachable" warning is worse than
// a missed one. `<button>` alone covers the overwhelmingly common case.
//
// That error bias is correct HERE and nowhere else. This predicate is for the
// trigger-reachability warning below, full stop. It used to back the modal's
// "does this have a way out?" gate too, where the bias inverts: a false
// positive there suppressed Escape and left the user trapped. The modal now
// enumerates its exits instead (see `exits` in ember-remodal.gts) — do not
// wire this back into that decision.
const FOCUSABLE_SELECTOR = [
  'a[href]',
  'area[href]',
  'button',
  'details',
  'summary',
  'iframe',
  'input',
  'select',
  'textarea',
  'audio[controls]',
  'video[controls]',
  '[contenteditable]:not([contenteditable="false"])',
  '[tabindex]',
].join(',');

export function hasFocusableDescendant(root: Element | null): boolean {
  return root !== null && root.querySelector(FOCUSABLE_SELECTOR) !== null;
}

const MISSING_FOCUSABLE_CONTENT_MESSAGE =
  'ember-remodal: the yielded <m.open> / <m.confirm> / <m.cancel> components render a click-delegating <span>, so the block must contain your own focusable control. `<m.open>Open modal</m.open>` produces a trigger that mouse users can click but keyboard users can never reach (WCAG 2.1.1). Wrap the label in a real control: `<m.open><button type="button">Open modal</button></m.open>`.';

export default class ErButton extends Component<ErButtonSignature> {
  handleClick = (event: Event): void => {
    // Deliberately no preventDefault here: the wrapper must not swallow the
    // default behavior of consumer content (checkboxes, form controls, real
    // links). The open trigger's link-safety preventDefault lives in the
    // modal's handleOpenClick instead.
    //
    // The return value is not discarded. `@onClick` is public and returns
    // `unknown`: the modal's own handlers come out of its error funnel and
    // never reject, but a consumer-supplied handler can, and a rejection
    // dropped here becomes a global unhandledrejection attributable to nothing
    // — a hard failure under Ember's test error validation. Promise.resolve()
    // makes a non-promise return a no-op. A synchronous throw is left alone:
    // it reaches window.onerror with this listener still on the stack, which is
    // both attributable and what a DOM event handler is supposed to do.
    void Promise.resolve(this.args.onClick(event)).catch((error: unknown) => {
      console.error(error);
    });
  };

  // Dev-only guardrail. `warn` rather than `assert` on purpose: the check reads
  // the consumer's rendered DOM, and content that arrives a tick late (an
  // awaited component, a flipped {{#if}}) can legitimately be focusable without
  // being focusable *yet*. A throwing assert would take a working application
  // down over a heuristic; a warning is loud, dev-only, and harmless when wrong.
  // The re-check on a microtask covers the synchronously-resolved async case.
  auditFocusableContent = modifier((element: Element) => {
    let cancelled = false;
    if (!hasFocusableDescendant(element)) {
      void Promise.resolve().then(() => {
        if (cancelled || !element.isConnected) {
          return;
        }
        warn(
          MISSING_FOCUSABLE_CONTENT_MESSAGE,
          hasFocusableDescendant(element),
          {
            id: 'ember-remodal.er-button-without-focusable-content',
          },
        );
      });
    }
    return () => {
      cancelled = true;
    };
  });

  <template>
    {{! The span is a click-delegating wrapper: consumers put their own real
        interactive element (usually a <button>) in the block, so giving the
        wrapper a role or tabindex would double up on semantics/focus. The
        disable is re-armed below, so it covers only these two spans rather
        than everything to the end of the template. }}
    {{! template-lint-disable no-invalid-interactive }}
    {{#if @destination}}
      {{#in-element @destination insertBefore=null}}
        <span
          class="er-button"
          {{on "click" this.handleClick}}
          {{this.auditFocusableContent}}
          ...attributes
        >{{yield}}</span>
      {{/in-element}}
    {{else}}
      <span
        class="er-button"
        {{on "click" this.handleClick}}
        {{this.auditFocusableContent}}
        ...attributes
      >{{yield}}</span>
    {{/if}}
    {{! template-lint-enable no-invalid-interactive }}
  </template>
}
