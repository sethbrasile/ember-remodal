import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { warn } from '@ember/debug';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';
import { service } from '@ember/service';
import { waitForPromise } from '@ember/test-waiters';
import { modifier } from 'ember-modifier';
import type Owner from '@ember/owner';
import type { WithBoundArgs } from '@glint/template';
import type RemodalService from '../services/remodal.ts';
import ErButton, {
  hasFocusableDescendant,
} from './ember-remodal/er-button.gts';
import '../styles/ember-remodal.css';

export type ModalState = 'closed' | 'opening' | 'opened' | 'closing';
export type CloseReason = 'confirmation' | 'cancellation';

export interface EmberRemodalOptions {
  title?: string;
  text?: string;
  // `showModal()` gives the <dialog> `role="dialog"` and implicit `aria-modal`,
  // but not a name. `title` names it via aria-labelledby; `ariaLabel` is the
  // escape hatch for a modal with no visible title (a @disableForeground
  // overlay, or a block whose heading is consumer markup we cannot reference).
  ariaLabel?: string;
  // Accessible name of the built-in close button. An option (rather than a
  // hardcoded string) so it can be translated.
  closeButtonLabel?: string;
  confirmButton?: string;
  cancelButton?: string;
  openButton?: string;
  openLink?: string;
  linkButton?: string;
  name?: string;
  forService?: boolean;
  dataTestId?: string;
  modifier?: string;
  modalClasses?: string;
  buttonClasses?: string;
  outerButtonClasses?: string;
  innerButtonClasses?: string;
  openButtonClasses?: string;
  openLinkClasses?: string;
  cancelButtonClasses?: string;
  confirmButtonClasses?: string;
  closeOnEscape?: boolean;
  closeOnCancel?: boolean;
  closeOnConfirm?: boolean;
  closeOnOutsideClick?: boolean;
  disableForeground?: boolean;
  disableNativeClose?: boolean;
  disableAnimation?: boolean;
  // Callbacks live here (rather than only on the args) so they can be passed
  // through `@options` or `service.open(name, opts)` as well as directly,
  // which is what 2.x's setProperties-based option merge allowed.
  onBeforeOpen?: () => unknown;
  onOpen?: () => void;
  onClose?: (reason?: CloseReason) => void;
  onConfirm?: () => void;
  onCancel?: () => void;
}

export interface EmberRemodalArgs extends EmberRemodalOptions {
  options?: EmberRemodalOptions;
}

export interface EmberRemodalYield {
  open: WithBoundArgs<typeof ErButton, 'destination' | 'onClick'>;
  confirm: WithBoundArgs<typeof ErButton, 'onClick'>;
  cancel: WithBoundArgs<typeof ErButton, 'onClick'>;
  isOpen: boolean;
  openAction: () => void;
  closeAction: () => void;
  confirmAction: () => void;
  cancelAction: () => void;
}

export interface EmberRemodalSignature {
  Args: EmberRemodalArgs;
  Blocks: {
    default: [modal: EmberRemodalYield];
  };
  Element: HTMLSpanElement;
}

interface Deferred<T> {
  promise: Promise<T>;
  resolve: (value: T) => void;
}

function defer<T>(): Deferred<T> {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>((res) => {
    resolve = res;
  });
  return { promise, resolve };
}

function nextFrame(): Promise<void> {
  return new Promise((resolve) => requestAnimationFrame(() => resolve()));
}

function documentIsHidden(): boolean {
  return typeof document !== 'undefined' && document.hidden;
}

// Resolves the first time the document becomes hidden, and hands back a
// disposer for the listener. requestAnimationFrame is suspended and CSS
// animations stop advancing while a tab is backgrounded, so anything waiting on
// either (our frame preamble, `animation.finished`) can hang indefinitely —
// racing this lets the transition finalize immediately instead.
function whenDocumentHidden(): { promise: Promise<void>; dispose: () => void } {
  if (typeof document === 'undefined') {
    return { promise: new Promise<void>(() => {}), dispose: () => {} };
  }
  let dispose = (): void => {};
  const promise = new Promise<void>((resolve) => {
    const onVisibilityChange = (): void => {
      if (document.hidden) {
        resolve();
      }
    };
    document.addEventListener('visibilitychange', onVisibilityChange);
    dispose = (): void => {
      document.removeEventListener('visibilitychange', onVisibilityChange);
    };
  });
  return { promise, dispose };
}

// The wrapper <dialog> is `overflow: auto`, so a press on its own scrollbar
// targets the dialog element itself just like a press on the backdrop does.
// The scrollbar gutter is the only region of the element outside its client
// box, and `offsetX/offsetY` are measured from the padding edge.
function isScrollbarPress(event: Event): boolean {
  if (!(event instanceof MouseEvent) || !(event.target instanceof Element)) {
    return false;
  }
  const { clientWidth, clientHeight } = event.target;
  return event.offsetX > clientWidth || event.offsetY > clientHeight;
}

const MISSING_DIALOG_MESSAGE =
  'ember-remodal: "open" was called, but the modal\'s <dialog> element never rendered, so there is nothing to open.';

// Shared scroll-lock bookkeeping so multiple simultaneously-open modals
// only lock/unlock the document once. The set tracks which modal instances
// currently hold the lock; the document locks on 0 → 1 and unlocks on 1 → 0.
const lockHolders = new Set<object>();
let savedBodyPaddingRight: string | null = null;

function acquireScrollLock(holder: object): void {
  const wasEmpty = lockHolders.size === 0;
  lockHolders.add(holder);
  if (wasEmpty) {
    // Measure before locking: overflow-hidden removes the scrollbar.
    const scrollbarWidth =
      window.innerWidth - document.documentElement.clientWidth;
    savedBodyPaddingRight = document.body.style.paddingRight;
    if (scrollbarWidth > 0) {
      document.body.style.paddingRight = `${scrollbarWidth}px`;
    }
    document.documentElement.classList.add('remodal-is-locked');
  }
}

function releaseScrollLock(holder: object): void {
  const removed = lockHolders.delete(holder);
  if (removed && lockHolders.size === 0) {
    document.documentElement.classList.remove('remodal-is-locked');
    document.body.style.paddingRight = savedBodyPaddingRight ?? '';
    savedBodyPaddingRight = null;
  }
}

function createOpenButtonTarget(): HTMLSpanElement | null {
  if (typeof document === 'undefined') {
    return null;
  }
  const span = document.createElement('span');
  span.className = 'ember-remodal-open-button-target';
  return span;
}

export default class EmberRemodal extends Component<EmberRemodalSignature> {
  @service declare remodal: RemodalService;

  @tracked state: ModalState = 'closed';
  @tracked serviceOverrides: EmberRemodalOptions | null = null;

  dialogElement: HTMLDialogElement | null = null;

  // Created eagerly (not tracked) so yielded `m.open` buttons have a stable
  // portal destination from the very first render; the element is attached to
  // the DOM by `attachOpenButtonTarget`. Only null in SSR, where ErButton
  // falls back to rendering inline.
  openButtonTarget: HTMLSpanElement | null = createOpenButtonTarget();

  private openDeferred: Deferred<this> | null = null;
  private closeDeferred: Deferred<this> | null = null;
  // Bumped whenever a new transition (open/close/forced close/destroy) takes
  // over; stale in-flight transitions notice and settle without side effects.
  private transitionId = 0;
  // The name this instance was registered under; name changes after
  // registration do not re-key the registry.
  private registeredName: string | null = null;
  // Whether open() has ever actually started a transition; used to scope the
  // "close before open" warning.
  private hasOpened = false;
  // The reason of the close currently in flight. Stashed on the instance so a
  // stale native `close` event that finalizes the close on our behalf still
  // reports the reason to @onClose instead of dropping it.
  private pendingCloseReason: CloseReason | undefined = undefined;
  // Latched on mousedown so backdrop dismissal requires the press AND the
  // release to land on the dialog itself.
  private pressedOnBackdrop = false;
  private readonly testingAnimationDisabled: boolean;

  constructor(owner: Owner, args: EmberRemodalArgs) {
    super(owner, args);
    this.testingAnimationDisabled = this.resolveTestingAnimationDisabled(owner);
    if (this.forService) {
      this.registeredName = this.name;
      this.remodal.register(this.registeredName, this);
    }
  }

  override willDestroy(): void {
    super.willDestroy();
    this.transitionId += 1;
    if (this.registeredName !== null) {
      this.remodal.unregister(this.registeredName, this);
    }
    const wasOpen = this.state !== 'closed';
    const reason = this.pendingCloseReason;
    this.pendingCloseReason = undefined;
    // Releases the scroll lock. The <dialog> element itself is closed by the
    // registerDialog modifier's destructor: that runs one `actions`-queue hop
    // before this hook, so by now `dialogElement` is already null.
    this.setState('closed');
    this.settlePendingTransitions();
    if (wasOpen) {
      // 2.x fired its `closed` callback from the destroy path, so keep that
      // parity: a modal torn down while open (a route transition, a
      // `{{#if}}` flipping) is still a close as far as the consumer's state
      // is concerned. Errors are reported, not thrown — we are already inside
      // destruction and there is no caller left to hand a rejection to.
      try {
        this.opt('onClose')?.(reason);
      } catch (error) {
        this.reportError(error);
      }
    }
  }

  private resolveTestingAnimationDisabled(owner: Owner): boolean {
    try {
      const resolverOwner = owner as unknown as
        { resolveRegistration?: (name: string) => unknown } | undefined;
      const config = resolverOwner?.resolveRegistration?.(
        'config:environment',
      ) as
        | {
            environment?: string;
            'ember-remodal'?: { disableAnimationWhileTesting?: boolean };
          }
        | undefined;
      return (
        config?.environment === 'test' &&
        Boolean(config?.['ember-remodal']?.disableAnimationWhileTesting)
      );
    } catch {
      return false;
    }
  }

  // --- option resolution: serviceOverrides → @options → args → default ---
  // (matches 2.x, where service opts and the options hash overwrote direct
  // attrs via setProperties)

  opt = <K extends keyof EmberRemodalOptions>(
    key: K,
  ): EmberRemodalOptions[K] => {
    return (
      this.serviceOverrides?.[key] ?? this.args.options?.[key] ?? this.args[key]
    );
  };

  get name(): string {
    return this.opt('name') ?? 'ember-remodal';
  }

  get forService(): boolean {
    return this.opt('forService') ?? false;
  }

  get modifier(): string {
    return this.opt('modifier') ?? '';
  }

  // --- accessible naming ---

  // Stable per-instance id for the rendered <h2>, so the <dialog> can point
  // aria-labelledby at it. Multiple modals on a page each get their own.
  get titleId(): string {
    return `${guidFor(this)}-title`;
  }

  // Falsy strings are treated as absent: `aria-label=""` names nothing and an
  // empty @title renders no <h2> for aria-labelledby to reference.
  get ariaLabel(): string | undefined {
    return this.opt('ariaLabel') || undefined;
  }

  // aria-labelledby only when the <h2> actually renders AND the consumer has
  // not overridden the name with @ariaLabel. Emitting both would be harmless
  // (aria-labelledby wins in the accname algorithm) but silently ignoring an
  // explicitly-passed @ariaLabel is worse than honoring it.
  get labelledById(): string | undefined {
    if (this.ariaLabel) {
      return undefined;
    }
    return this.opt('title') ? this.titleId : undefined;
  }

  get hasAccessibleName(): boolean {
    return Boolean(this.ariaLabel) || Boolean(this.opt('title'));
  }

  get closeButtonLabel(): string {
    return this.opt('closeButtonLabel') || 'Close Modal';
  }

  get closeOnEscape(): boolean {
    return this.opt('closeOnEscape') ?? true;
  }

  get closeOnCancel(): boolean {
    return this.opt('closeOnCancel') ?? true;
  }

  get closeOnConfirm(): boolean {
    return this.opt('closeOnConfirm') ?? true;
  }

  get closeOnOutsideClick(): boolean {
    return this.opt('closeOnOutsideClick') ?? true;
  }

  get disableForeground(): boolean {
    return this.opt('disableForeground') ?? false;
  }

  get disableNativeClose(): boolean {
    return this.opt('disableNativeClose') ?? this.disableForeground;
  }

  get disableAnimation(): boolean {
    return (
      (this.opt('disableAnimation') ?? false) || this.testingAnimationDisabled
    );
  }

  get animationState(): string {
    return this.disableAnimation ? 'disable-animation' : '';
  }

  get stateClass(): string {
    return `remodal-is-${this.state}`;
  }

  get isOpen(): boolean {
    // Deliberately includes 'closing' so lazily-rendered content survives the
    // closing animation instead of vanishing the instant close() is called.
    return this.state !== 'closed';
  }

  // --- element capture modifiers ---

  registerDialog = modifier((element: HTMLDialogElement) => {
    this.dialogElement = element;
    return () => {
      if (this.dialogElement === element) {
        this.dialogElement = null;
      }
      // This destructor is the last point at which the element is still in
      // hand: it runs one `actions`-queue hop before willDestroy. A modal
      // destroyed (or removed from the DOM) while open must not leave a
      // top-layer dialog behind.
      if (element.open) {
        element.close();
      }
    };
  });

  attachOpenButtonTarget = modifier((element: Element) => {
    if (this.openButtonTarget) {
      element.appendChild(this.openButtonTarget);
    }
    return () => {
      this.openButtonTarget?.remove();
    };
  });

  // --- state machine ---

  open = async (): Promise<this> => {
    if (this.isDestroying) {
      return this;
    }
    // A bare `state === 'opened'` check can disagree with the element: the
    // native `close` event is queued, so between an external close and its
    // event delivery state is still 'opened' while the dialog is shut. Only
    // short-circuit when state and element agree.
    if (this.state === 'opened' && this.dialogElement?.open) {
      return this;
    }
    // Join an open that is already in flight — either still waiting for its
    // <dialog> element (state has not left 'closed' yet) or animating (state
    // is 'opening'). Never join while 'closing': a deferred surviving there
    // belongs to an open a close has already superseded.
    if (this.openDeferred && this.state !== 'closing') {
      return this.openDeferred.promise;
    }
    if (this.opt('onBeforeOpen')?.() === false) {
      return this;
    }

    // Claim the transition BEFORE any await. waitForDialogElement below can
    // span many frames, and until the id and the deferred are claimed nothing
    // records that an open is pending — a close() landing in that window would
    // warn about closing an unopened modal and no-op while we opened anyway.
    const deferred = defer<this>();
    this.openDeferred = deferred;
    const runId = ++this.transitionId;
    this.hasOpened = true;
    this.pendingCloseReason = undefined;

    try {
      if (!this.dialogElement) {
        // e.g. service.open() during the initial render pass, before our
        // <dialog> has been inserted; give rendering a few frames to catch up.
        await waitForPromise(this.waitForDialogElement());
      }
      if (this.isDestroying || this.transitionId !== runId) {
        return this;
      }
      const dialog = this.dialogElement;
      if (!dialog) {
        // Rejecting is the only signal that survives a production build (a
        // `warn` is stripped), so a slow render can no longer silently drop
        // the open. Every internal call site catches.
        throw new Error(MISSING_DIALOG_MESSAGE);
      }

      if (this.state === 'closing') {
        // Interrupt the in-flight close: cancelling its animations wakes its
        // continuation, which sees the stale transitionId and settles itself
        // without closing the dialog.
        this.cancelAnimations(dialog);
      }
      if (!dialog.open) {
        try {
          dialog.showModal();
        } catch (error) {
          // showModal() throws InvalidStateError for a <dialog> that is not
          // connected to a document. Keep state coherent and let the caller
          // see the failure; the `finally` still settles every joined caller.
          this.setState('closed');
          throw error;
        }
      }
      this.setState('opening');

      await this.animationsSettled(dialog, runId);

      if (this.transitionId === runId && !this.isDestroying) {
        this.setState('opened');
        // After animationsSettled, so lazily-rendered block content
        // ({{#if m.isOpen}}) is in the DOM before we look for focusable
        // controls. Before @onOpen, so a throwing callback cannot hide it.
        this.auditAccessibility();
        this.opt('onOpen')?.();
      }
      return deferred.promise;
    } finally {
      if (this.openDeferred === deferred) {
        this.openDeferred = null;
      }
      // Settle unconditionally. A throwing consumer callback (or a failed
      // showModal) must never strand a caller that joined this transition:
      // openDeferred is already cleared above, so settlePendingTransitions()
      // can no longer rescue it.
      deferred.resolve(this);
    }
  };

  close = async (reason?: CloseReason): Promise<this> => {
    if (this.state === 'closed') {
      const pendingOpen = this.openDeferred;
      if (pendingOpen) {
        // An open() still waiting for its <dialog> element has not reached
        // 'opening' yet. Supersede it here — bumping the id makes its
        // continuation notice it lost — so this close actually wins instead of
        // the modal opening after we have returned.
        this.transitionId += 1;
        this.openDeferred = null;
        pendingOpen.resolve(this);
        return this;
      }
      warn(
        'ember-remodal: You called "close" on a modal that has not yet been opened. This is not a big deal, but I thought you should know. The returned promise will immediately resolve.',
        this.hasOpened,
        { id: 'ember-remodal.close-called-on-uninitialized-modal' },
      );
      return this;
    }
    if (this.state === 'closing' && this.closeDeferred) {
      return this.closeDeferred.promise;
    }
    const dialog = this.dialogElement;
    if (!dialog || this.isDestroying) {
      return this;
    }

    const deferred = defer<this>();
    this.closeDeferred = deferred;
    const runId = ++this.transitionId;
    this.pendingCloseReason = reason;

    try {
      if (this.state === 'opening') {
        // Interrupt the in-flight open; its continuation settles itself.
        this.cancelAnimations(dialog);
      }
      this.setState('closing');

      await this.animationsSettled(dialog, runId);

      if (this.transitionId === runId && !this.isDestroying) {
        this.finalizeClose(reason);
      }
      return deferred.promise;
    } finally {
      if (this.closeDeferred === deferred) {
        this.closeDeferred = null;
      }
      deferred.resolve(this);
    }
  };

  confirm = (): Promise<this> => {
    this.opt('onConfirm')?.();
    if (this.closeOnConfirm) {
      return this.close('confirmation');
    }
    return Promise.resolve(this);
  };

  cancel = (): Promise<this> => {
    this.opt('onCancel')?.();
    if (this.closeOnCancel) {
      return this.close('cancellation');
    }
    return Promise.resolve(this);
  };

  // Zero-arg wrappers safe to use as DOM event handlers (they swallow the
  // Event argument so it can never be mistaken for a close reason).
  //
  // They `.catch()` rather than `void`: `void` does not mark a rejection
  // handled, so a failed showModal() or a throwing consumer callback would
  // surface as a global unhandledrejection (a hard failure under Ember's test
  // error validation) with no caller able to intercept it.

  openAction = (): void => {
    this.open().catch(this.reportError);
  };

  closeAction = (): void => {
    this.close().catch(this.reportError);
  };

  confirmAction = (): void => {
    this.confirm().catch(this.reportError);
  };

  cancelAction = (): void => {
    this.cancel().catch(this.reportError);
  };

  handleOpenClick = (event?: Event): void => {
    // Open triggers may render as `<a href="#">`; never navigate.
    event?.preventDefault();
    this.open().catch(this.reportError);
  };

  handleWrapperMouseDown = (event: Event): void => {
    this.pressedOnBackdrop =
      event.target === this.dialogElement && !isScrollbarPress(event);
  };

  handleWrapperClick = (event: Event): void => {
    // `event.target === dialog` alone is also true when a press that started
    // inside the card is released over the backdrop (the click dispatches on
    // their common ancestor, the dialog) and when the user drags the dialog's
    // own scrollbar — both would discard the user's content. Require the press
    // to have landed on the backdrop too.
    const pressedOnBackdrop = this.pressedOnBackdrop;
    this.pressedOnBackdrop = false;
    if (
      pressedOnBackdrop &&
      event.target === this.dialogElement &&
      this.closeOnOutsideClick
    ) {
      this.close().catch(this.reportError);
    }
  };

  handleNativeCancel = (event: Event): void => {
    // We own the closing animation, so never let the browser close instantly.
    // (When the window has no history-action activation the `cancel` event is
    // dispatched non-cancelable and the dialog force-closes anyway; the queued
    // native `close` event then re-syncs state through handleDialogClose.)
    event.preventDefault();
    if (this.closeOnEscape || !this.hasKeyboardExit()) {
      // `@closeOnEscape={{false}}` is honored only while the user has some
      // other way out. Under the old jQuery implementation the modal was a
      // plain <div> a keyboard user could simply Tab out of; showModal() makes
      // focus containment real, so suppressing Escape in a modal with no
      // focusable control at all is an inescapable keyboard trap (WCAG 2.1.2,
      // Level A). Escape wins in exactly that configuration — a dev warning at
      // open time says so, and this behavior is NOT dev-only: dev and
      // production must not disagree about whether a modal can be escaped.
      this.close().catch(this.reportError);
    }
  };

  handleDialogClose = (): void => {
    if (this.isDestroying || this.state === 'closed') {
      return;
    }
    // The native `close` event is dispatched from a QUEUED task, so it can
    // arrive after a newer open() has already re-opened the dialog. If the
    // dialog is natively open again, this event is stale; a genuine external
    // close always leaves `dialog.open === false`.
    if (!this.dialogElement || this.dialogElement.open) {
      return;
    }
    // The dialog closed without going through close() — e.g. a
    // `<form method="dialog">` submission inside user content, or a browser
    // force-close that ignored our cancel preventDefault. Re-sync state.
    this.transitionId += 1;
    this.finalizeClose();
  };

  // --- internals ---

  // The `.remodal` card: everything the user can interact with lives inside it.
  private get cardElement(): Element | null {
    return this.dialogElement?.querySelector('.remodal') ?? null;
  }

  // Whether a keyboard user can leave the modal without Escape. Measured off
  // the live DOM rather than inferred from options, because the built-in close
  // button, the cancel/confirm buttons and anything in the consumer's block all
  // count, and only the DOM knows about the last one.
  private hasKeyboardExit(): boolean {
    return hasFocusableDescendant(this.cardElement);
  }

  // Dev-only accessibility audit, run once per open. Both `warn` calls are
  // stripped from production builds along with their condition arguments.
  private auditAccessibility(): void {
    warn(
      `ember-remodal: the modal "${this.name}" was opened with neither @title nor @ariaLabel, so its <dialog> has no accessible name — screen readers announce it only as "dialog" (WCAG 4.1.2). Pass @ariaLabel="…" when the modal has no visible title.`,
      this.hasAccessibleName,
      { id: 'ember-remodal.modal-without-accessible-name' },
    );
    warn(
      `ember-remodal: the modal "${this.name}" was opened with @closeOnEscape={{false}} and contains no focusable control, so a keyboard user would have no way out (WCAG 2.1.2). Escape will close it anyway. Render the built-in close button (drop @disableNativeClose / @disableForeground) or put a focusable control inside the modal.`,
      this.closeOnEscape || this.hasKeyboardExit(),
      { id: 'ember-remodal.no-keyboard-exit' },
    );
  }

  private reportError = (error: unknown): void => {
    // The DOM entry points above have nobody to hand a rejection to, and
    // swallowing it silently would hide a consumer callback that threw.
    console.error(error);
  };

  // The single funnel for state writes: acquires the scroll lock on the
  // closed → non-closed edge and releases it on the non-closed → closed edge,
  // so lock bookkeeping can never drift from the state machine.
  private setState(next: ModalState): void {
    const previous = this.state;
    if (next === previous) {
      return;
    }
    const wasClosed = previous === 'closed';
    const willBeClosed = next === 'closed';
    this.state = next;
    if (wasClosed && !willBeClosed) {
      acquireScrollLock(this);
    } else if (!wasClosed && willBeClosed) {
      releaseScrollLock(this);
    }
  }

  // Shared teardown for every way a modal ends up closed (close()'s success
  // path and an external/native dialog close). Sets state (which releases the
  // scroll lock) BEFORE closing the native dialog, so the queued native
  // `close` event hits handleDialogClose's state guard.
  private finalizeClose(reason?: CloseReason): void {
    // Whichever path finalizes reports the reason: a stale native `close`
    // event can beat an in-flight close('confirmation') to the finish line,
    // and it has no reason of its own to pass on.
    const effectiveReason = reason ?? this.pendingCloseReason;
    this.pendingCloseReason = undefined;
    this.setState('closed');
    if (this.dialogElement?.open) {
      this.dialogElement.close();
    }
    this.settlePendingTransitions();
    this.opt('onClose')?.(effectiveReason);
  }

  private async waitForDialogElement(): Promise<void> {
    for (let i = 0; i < 10 && !this.dialogElement && !this.isDestroying; i++) {
      await nextFrame();
    }
  }

  private settlePendingTransitions(): void {
    const { openDeferred, closeDeferred } = this;
    this.openDeferred = null;
    this.closeDeferred = null;
    openDeferred?.resolve(this);
    closeDeferred?.resolve(this);
  }

  private ownAnimations(dialog: HTMLDialogElement): Animation[] {
    // Only wait on our own CSS animations (the `remodal-` keyframes) targeting
    // the wrapper/backdrop or the card. User content — and even consumer
    // classes applied to the card via @modalClasses — may legitimately carry
    // infinite animations (e.g. spinners) whose `finished` promise never
    // settles; waiting on those would hang open()/close() forever.
    const card = dialog.querySelector('.remodal');
    return dialog.getAnimations({ subtree: true }).filter((animation) => {
      if (
        !(animation instanceof CSSAnimation) ||
        !animation.animationName.startsWith('remodal-')
      ) {
        return false;
      }
      const target =
        animation.effect instanceof KeyframeEffect
          ? animation.effect.target
          : null;
      return target === dialog || (card !== null && target === card);
    });
  }

  private cancelAnimations(dialog: HTMLDialogElement): void {
    for (const animation of this.ownAnimations(dialog)) {
      animation.cancel();
    }
  }

  private animationsSettled(
    dialog: HTMLDialogElement,
    runId: number,
  ): Promise<void> {
    // A backgrounded tab suspends requestAnimationFrame and stops advancing
    // CSS animations, so the frame preamble and `animation.finished` below both
    // hang for as long as the tab stays hidden — a session-timeout timer or a
    // websocket message calling close() would never reach finalizeClose. Skip
    // waiting entirely when already hidden, and race the visibility change so a
    // tab backgrounded mid-transition still settles.
    if (this.disableAnimation || documentIsHidden()) {
      return Promise.resolve();
    }
    const hidden = whenDocumentHidden();
    // The waiter keeps `settled()` (and `await click(…)`) reliable in tests.
    return waitForPromise(
      Promise.race([
        this.ownAnimationsSettled(dialog, runId),
        hidden.promise,
      ]).finally(hidden.dispose),
    );
  }

  private async ownAnimationsSettled(
    dialog: HTMLDialogElement,
    runId: number,
  ): Promise<void> {
    // Two frames so the state-class change has applied and CSS animations
    // have actually started before we collect them. Bail after each await
    // if a newer transition has taken over, so a superseded transition
    // never collects or waits on its successor's animations.
    await nextFrame();
    if (this.transitionId !== runId || this.isDestroying) {
      return;
    }
    await nextFrame();
    if (this.transitionId !== runId || this.isDestroying) {
      return;
    }
    const animations = this.ownAnimations(dialog);
    if (animations.length > 0) {
      // allSettled: cancelled animations reject their `finished` promise.
      await Promise.allSettled(animations.map((a) => a.finished));
    }
  }

  <template>
    <span
      class="remodal-component"
      data-test-id={{this.opt "dataTestId"}}
      ...attributes
    >
      {{#if (this.opt "linkButton")}}
        <a
          href="#"
          class="ember-remodal outer link text
            {{this.opt 'buttonClasses'}}
            {{this.opt 'outerButtonClasses'}}"
          data-test-id="linkButton"
          {{on "click" this.handleOpenClick}}
        >{{this.opt "linkButton"}}</a>
      {{else if (this.opt "openLink")}}
        <a
          href="#"
          class="ember-remodal outer link text
            {{this.opt 'buttonClasses'}}
            {{this.opt 'outerButtonClasses'}}
            {{this.opt 'openLinkClasses'}}"
          data-test-id="openLink"
          {{on "click" this.handleOpenClick}}
        >{{this.opt "openLink"}}</a>
      {{else if (this.opt "openButton")}}
        <button
          type="button"
          class="ember-remodal outer open button
            {{this.opt 'buttonClasses'}}
            {{this.opt 'outerButtonClasses'}}
            {{this.opt 'openButtonClasses'}}"
          data-test-id="openButton"
          {{on "click" this.handleOpenClick}}
        >{{this.opt "openButton"}}</button>
      {{/if}}

      <span
        class="ember-remodal-open-button-target-host"
        {{this.attachOpenButtonTarget}}
      ></span>

      {{! The wrapper click handler only detects clicks on the backdrop area
          (outside the card) to support closeOnOutsideClick; it is not a
          keyboard-reachable control (Escape is handled via the native cancel
          event), so no-invalid-interactive does not apply.

          The mousedown listener does not activate anything either — it only
          latches where the press started, so that dismissing on a backdrop
          click requires the press AND the release to land on the backdrop.
          Dismissal itself still happens on click. }}
      {{! template-lint-disable no-invalid-interactive no-pointer-down-event-binding }}
      <dialog
        class="remodal-wrapper
          {{this.stateClass}}
          {{this.modifier}}
          {{this.animationState}}"
        data-test-id="modalWrapper"
        aria-labelledby={{this.labelledById}}
        aria-label={{this.ariaLabel}}
        {{on "mousedown" this.handleWrapperMouseDown}}
        {{on "click" this.handleWrapperClick}}
        {{on "cancel" this.handleNativeCancel}}
        {{on "close" this.handleDialogClose}}
        {{this.registerDialog}}
      >
        <div
          class="remodal remodal-is-initialized
            {{this.stateClass}}
            ember-remodal
            {{this.name}}
            {{this.modifier}}
            {{this.animationState}}
            window
            {{if this.disableForeground 'invisible'}}
            {{this.opt 'modalClasses'}}"
          data-test-id="modalWindow"
        >
          {{#unless this.disableNativeClose}}
            {{! The visible glyph comes from `.remodal-close::before`, and
                pseudo-element content participates in name-from-contents,
                which OUTRANKS `title` in the accname algorithm — without an
                aria-label this button is announced as "times, button". }}
            <button
              type="button"
              aria-label={{this.closeButtonLabel}}
              title={{this.closeButtonLabel}}
              class="remodal-close ember-remodal inner native close"
              data-test-id="nativeClose"
              {{on "click" this.closeAction}}
            ></button>
          {{/unless}}

          {{#if (this.opt "title")}}
            <h2
              id={{this.titleId}}
              class="ember-remodal inner title text"
              data-test-id="title"
            >{{this.opt "title"}}</h2>
          {{/if}}

          {{#if (this.opt "text")}}
            <p
              class="ember-remodal inner paragraph text"
              data-test-id="text"
            >{{this.opt "text"}}</p>
          {{/if}}

          {{#if (has-block)}}
            <div
              class="ember-remodal inner yielded content"
              data-test-id="yielded"
            >
              {{yield
                (hash
                  open=(component
                    ErButton
                    destination=this.openButtonTarget
                    onClick=this.handleOpenClick
                  )
                  confirm=(component ErButton onClick=this.confirm)
                  cancel=(component ErButton onClick=this.cancel)
                  isOpen=this.isOpen
                  openAction=this.openAction
                  closeAction=this.closeAction
                  confirmAction=this.confirmAction
                  cancelAction=this.cancelAction
                )
              }}
            </div>
          {{/if}}

          {{#if (this.opt "cancelButton")}}
            <button
              type="button"
              class="remodal-cancel ember-remodal inner cancel button
                {{this.opt 'buttonClasses'}}
                {{this.opt 'innerButtonClasses'}}
                {{this.opt 'cancelButtonClasses'}}"
              data-test-id="cancelButton"
              {{on "click" this.cancelAction}}
            >{{this.opt "cancelButton"}}</button>
          {{/if}}

          {{#if (this.opt "confirmButton")}}
            <button
              type="button"
              class="remodal-confirm ember-remodal inner confirm button
                {{this.opt 'buttonClasses'}}
                {{this.opt 'innerButtonClasses'}}
                {{this.opt 'confirmButtonClasses'}}"
              data-test-id="confirmButton"
              {{on "click" this.confirmAction}}
            >{{this.opt "confirmButton"}}</button>
          {{/if}}
        </div>
      </dialog>
      {{! Re-arm both rules: an unterminated disable comment suppresses them
          all the way to the end of the template, which would have covered the
          whole card subtree and every yielded block inside it. }}
      {{! template-lint-enable no-invalid-interactive no-pointer-down-event-binding }}
    </span>
  </template>
}
