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
import ErButton from './ember-remodal/er-button.gts';
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
  // Id (or space-separated ids) of consumer-authored markup that names the
  // dialog — a heading inside the block, typically. Without it a block-only
  // modal can only be named by duplicating its own heading text into
  // `ariaLabel`. Outranks `ariaLabel` and `title`, matching the accname
  // algorithm's own precedence.
  ariaLabelledBy?: string;
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
  // Declares that the block content provides a keyboard-operable way out (a
  // button wired to `m.closeAction`, a `<form method="dialog">` submit, …).
  // The addon enumerates the exits IT renders; it cannot tell a real exit from
  // an `<input type="hidden">` by looking at the consumer's DOM, so a
  // block-provided exit has to be declared. Only consulted alongside
  // `closeOnEscape: false`; absent, Escape is never suppressed.
  hasCustomKeyboardExit?: boolean;
  closeOnCancel?: boolean;
  closeOnConfirm?: boolean;
  closeOnOutsideClick?: boolean;
  disableForeground?: boolean;
  disableNativeClose?: boolean;
  disableAnimation?: boolean;
  // Opt back in to the bare single-word class tokens 1.x/2.x emitted
  // (`window`, `close`, `button`, `title`, `text`, `content`, `open`, `link`,
  // `native`, `inner`, `outer`, `confirm`, `cancel`, `paragraph`, `yielded`,
  // `invisible`). They are off by default in 3.0 because CSS frameworks own
  // those names — Bootstrap's `.close` and `.invisible`, Bulma/Foundation's
  // `.button` — and a bare token is a collision the addon cannot win from a
  // stylesheet whose bundle position it does not control. See MIGRATION.md.
  legacyClassNames?: boolean;
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

// What a backgrounded tab has instead of a frame. Rendering is not frame-driven
// — a hidden tab keeps rendering, it just stops painting — so a wait for the
// render to catch up still has something to wait FOR while hidden; it simply
// cannot be measured in frames.
function nextTick(): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, 0));
}

// Brand attached by `EmberRemodal#domHandler`, the factory every DOM-bound
// handler is produced by. Registered with `Symbol.for` rather than kept
// module-local so a test can enumerate the template's bindings and assert each
// one carries it, without the component exporting a testing seam that the
// package's `"./*"` entry would make semver-visible.
const DOM_HANDLER = Symbol.for('ember-remodal:dom-handler');

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

// Flipped by `setupRemodal` from `ember-remodal/test-support`. A module-level
// flag is the only mechanism that works in a strict-resolver v2 app, where
// `config:environment` is not a resolvable registration at all (see
// resolveTestingAnimationDisabled, which remains the classic-resolver path).
let testSupportAnimationDisabled = false;

/**
 * Not part of the supported API: the seam `ember-remodal/test-support` uses.
 * Everything below mutates or reads module-level state that lives outside any
 * component instance (and outside `#ember-testing`), which is precisely why a
 * test suite needs a way to read and reset it.
 */
export function setAnimationDisabledForTesting(disabled: boolean): void {
  testSupportAnimationDisabled = disabled;
}

export interface ScrollLockState {
  /** How many modal instances currently believe they hold the lock. */
  holders: number;
  /** Whether the document element is actually carrying the lock class. */
  locked: boolean;
  bodyPaddingRight: string;
}

export function scrollLockStateForTesting(): ScrollLockState {
  return {
    holders: lockHolders.size,
    locked:
      typeof document !== 'undefined' &&
      document.documentElement.classList.contains('remodal-is-locked'),
    bodyPaddingRight:
      typeof document === 'undefined' ? '' : document.body.style.paddingRight,
  };
}

export function resetScrollLockForTesting(): void {
  const wasHeld = lockHolders.size > 0;
  lockHolders.clear();
  if (typeof document === 'undefined') {
    savedBodyPaddingRight = null;
    return;
  }
  document.documentElement.classList.remove('remodal-is-locked');
  // Only touch the inline style when this module is the reason it is set:
  // `savedBodyPaddingRight` is non-null exactly while a lock is (or was
  // wrongly left) held, and holds whatever the page had before we locked.
  if (wasHeld || savedBodyPaddingRight !== null) {
    document.body.style.paddingRight = savedBodyPaddingRight ?? '';
  }
  savedBodyPaddingRight = null;
}

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

// The accname algorithm trims and collapses whitespace, so " " names nothing:
// it produces an <h2> with no perceivable text, an aria-labelledby pointing at
// it, and a guard cheerfully reporting the dialog as named. Every string that
// can become a name goes through here, so "present" means the same thing at
// every one of them.
function presentString(value: string | undefined): string | undefined {
  return value !== undefined && value.trim() !== '' ? value : undefined;
}

// One way a modal can be dismissed. `keyboard` is what the WCAG 2.1.2 gate
// asks about: a pointer-only exit is not a way out of a keyboard trap.
interface ModalExit {
  id: string;
  keyboard: boolean;
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
        this.observeCallback(this.opt('onClose')?.(reason));
      } catch (error) {
        this.reportError(error);
      }
    }
  }

  // `config/environment`'s `ENV['ember-remodal'].disableAnimationWhileTesting`,
  // kept for classic (`ember-resolver`) apps upgrading from 2.x — that is the
  // only kind of app in which `config:environment` resolves. A strict-resolver
  // v2 app registers no such module, so this returns false there and
  // `setupRemodal({ disableAnimation: true })` from `ember-remodal/test-support`
  // is the supported switch. Both paths are covered by tests; neither is
  // allowed to be the only one.
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

  // Blank strings are treated as absent: `aria-label=" "` names nothing, and a
  // blank @title renders no <h2> worth pointing aria-labelledby at.
  get title(): string | undefined {
    return presentString(this.opt('title'));
  }

  get ariaLabel(): string | undefined {
    return presentString(this.opt('ariaLabel'));
  }

  get ariaLabelledBy(): string | undefined {
    return presentString(this.opt('ariaLabelledBy'));
  }

  // Exactly one naming attribute is ever emitted, in the accname algorithm's
  // own order: aria-labelledby, then aria-label, then the generated <h2> id.
  // Emitting two would be harmless to a screen reader but would leave the DOM
  // claiming a name that is not the one in effect — and silently ignoring an
  // explicitly-passed @ariaLabel is worse than honoring it.
  get labelledById(): string | undefined {
    if (this.ariaLabelledBy) {
      return this.ariaLabelledBy;
    }
    if (this.ariaLabel) {
      return undefined;
    }
    return this.title ? this.titleId : undefined;
  }

  get labelAttribute(): string | undefined {
    return this.ariaLabelledBy ? undefined : this.ariaLabel;
  }

  // Whether the dialog actually resolves to a name — not whether a naming
  // attribute is present. A consumer-supplied @ariaLabelledBy can point at an
  // id that does not exist (a typo, a heading behind an {{#if}} that did not
  // render), which names nothing at all; trusting the attribute would be the
  // same "the platform handles it" assumption this guard exists to catch.
  // Read only from auditAccessibility, i.e. with the dialog open and its
  // subtree in the document.
  get hasAccessibleName(): boolean {
    if (this.ariaLabelledBy) {
      return this.labelledByResolves;
    }
    return Boolean(this.ariaLabel) || Boolean(this.title);
  }

  private get labelledByResolves(): boolean {
    const idref = this.ariaLabelledBy;
    if (!idref || typeof document === 'undefined') {
      return false;
    }
    return idref
      .split(/\s+/)
      .filter(Boolean)
      .some((id) => {
        const target = document.getElementById(id);
        return (target?.textContent ?? '').trim() !== '';
      });
  }

  get closeButtonLabel(): string {
    return this.opt('closeButtonLabel') || 'Close Modal';
  }

  // NB-31's defect on the opposite element. `@cancelButton=" "` passes a truthy
  // test, so the old `{{#if (this.opt "cancelButton")}}` rendered a button with
  // no perceivable label and no accessible name — and the exit enumeration
  // below counted that button as the keyboard way out, re-opening the WCAG
  // 2.1.2 trap the enumeration exists to close. One getter feeds BOTH the
  // enumeration and the render condition, so the two cannot disagree about
  // whether the button exists.
  get cancelButton(): string | undefined {
    return presentString(this.opt('cancelButton'));
  }

  get confirmButton(): string | undefined {
    return presentString(this.opt('confirmButton'));
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

  get hasCustomKeyboardExit(): boolean {
    return this.opt('hasCustomKeyboardExit') ?? false;
  }

  get legacyClassNames(): boolean {
    return this.opt('legacyClassNames') ?? false;
  }

  get disableAnimation(): boolean {
    return (
      (this.opt('disableAnimation') ?? false) ||
      this.testingAnimationDisabled ||
      testSupportAnimationDisabled
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
    if (this.observeCallback(this.opt('onBeforeOpen')?.()) === false) {
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
        this.observeCallback(this.opt('onOpen')?.());
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

  // `async` so that this — like every other public method — hands the caller a
  // promise for BOTH outcomes. As a plain arrow it called `onConfirm`
  // synchronously, so a throwing callback escaped past the returned promise
  // entirely and past `confirmAction`'s catch with it.
  confirm = async (): Promise<this> => {
    this.observeCallback(this.opt('onConfirm')?.());
    if (this.closeOnConfirm) {
      return this.close('confirmation');
    }
    return this;
  };

  cancel = async (): Promise<this> => {
    this.observeCallback(this.opt('onCancel')?.());
    if (this.closeOnCancel) {
      return this.close('cancellation');
    }
    return this;
  };

  // --- DOM-bound handlers ---------------------------------------------------
  //
  // Every one of these is produced by `domHandler`, and the template binds
  // nothing else: no `{{on}}` modifier and no yielded `onClick` may reference a
  // public method directly. That is the whole rule, and it is the reason the
  // rule holds — a handler added later cannot skip the funnel without also
  // dropping the brand `domHandler` attaches, which the error-funnel test
  // enumerates the template for.
  //
  // The handlers also swallow their Event argument where the underlying method
  // takes one (close's `reason`), so a DOM event can never be mistaken for it.

  openAction = this.domHandler((): unknown => this.open());

  closeAction = this.domHandler((): unknown => this.close());

  confirmAction = this.domHandler((): unknown => this.confirm());

  cancelAction = this.domHandler((): unknown => this.cancel());

  handleOpenClick = this.domHandler((event?: Event): unknown => {
    // Open triggers may render as `<a href="#">`; never navigate.
    event?.preventDefault();
    return this.open();
  });

  handleWrapperMouseDown = this.domHandler((event: Event): void => {
    this.pressedOnBackdrop =
      event.target === this.dialogElement && !isScrollbarPress(event);
  });

  handleWrapperClick = this.domHandler((event: Event): unknown => {
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
      return this.close();
    }
    return undefined;
  });

  handleNativeCancel = this.domHandler((event: Event): unknown => {
    // We own the closing animation, so never let the browser close instantly.
    // (When the window has no history-action activation the `cancel` event is
    // dispatched non-cancelable and the dialog force-closes anyway; the queued
    // native `close` event then re-syncs state through handleDialogClose.)
    event.preventDefault();
    if (this.closeOnEscape || !this.hasKeyboardExit()) {
      // `@closeOnEscape={{false}}` is honored only while `exits` contains some
      // other keyboard-operable way out. Under the old jQuery implementation
      // the modal was a plain <div> a keyboard user could simply Tab out of;
      // showModal() makes focus containment real, so suppressing Escape in a
      // modal nothing else can close is an inescapable keyboard trap (WCAG
      // 2.1.2, Level A). Escape wins in exactly that configuration — a dev
      // warning at open time says so, and this behavior is NOT dev-only: dev
      // and production must not disagree about whether a modal can be escaped.
      // The gate is deliberately fail-safe: an exit the addon does not render
      // has to be declared with @hasCustomKeyboardExit, because the cost of
      // guessing wrong here is a user who cannot leave.
      return this.close();
    }
    return undefined;
  });

  handleDialogClose = this.domHandler((): void => {
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
    // finalizeClose calls @onClose with nobody to hand a rejection to — this
    // is the one @onClose call site with no promise behind it — which is
    // exactly what the funnel around this handler is for.
    this.transitionId += 1;
    this.finalizeClose();
  });

  // --- internals ---

  // The factory. Wraps a body in the error funnel and brands the result, so
  // "is this handler safe to hand to the DOM?" is answerable by inspection
  // rather than by reading the body. Both escape routes end in `reportError`:
  // a synchronous throw (which would otherwise reach window.onerror from an
  // event listener) and a rejected promise (which `void` does NOT mark as
  // handled, so it would otherwise surface as a global unhandledrejection —
  // a hard failure under Ember's test error validation, and attributable to
  // nothing in production).
  private domHandler<A extends unknown[]>(
    run: (...args: A) => unknown,
  ): (...args: A) => void {
    const handler = (...args: A): void => {
      try {
        // Promise.resolve() makes a non-promise return a no-op, so the funnel
        // does not care whether the body it wraps is async.
        void Promise.resolve(run(...args)).catch(this.reportError);
      } catch (error) {
        this.reportError(error);
      }
    };
    Object.defineProperty(handler, DOM_HANDLER, { value: true });
    return handler;
  }

  // Consumer callbacks are typed `() => void`, but nothing stops an `async`
  // one, and `this.opt('onOpen')?.()` does not await what it gets back: an
  // async callback that throws hands an already-rejected promise to a call site
  // that never references it. That is a different escape route from the
  // synchronous throw the surrounding funnel catches, so every callback
  // invocation is passed through here.
  //
  // A SYNCHRONOUS throw is deliberately left to propagate: the caller of
  // open()/close()/confirm()/cancel() is entitled to it as a rejection, and
  // that contract is pinned by tests. An asynchronous one cannot be routed
  // there without awaiting consumer callbacks inside the transition, which
  // would let a slow callback stall the animation; it is reported instead.
  private observeCallback(result: unknown): unknown {
    void Promise.resolve(result).catch(this.reportError);
    return result;
  }

  // Every way out of this modal OTHER than Escape, enumerated from the
  // configuration that produces it. Escape itself is deliberately absent: this
  // list exists to adjudicate whether suppressing Escape leaves the user
  // stranded, so including it would answer its own question.
  //
  // This is an enumeration and not a DOM query on purpose. The obvious
  // implementation — "does the card contain something focusable?" — was the
  // round-1 shape, and it is wrong in both directions. It says yes to an
  // `<input type="hidden">`, a `<button disabled>` and a `[tabindex="-1"]`
  // container (none of which a keyboard user can operate, let alone leave
  // through), and it says yes to a cancel button under
  // `@closeOnCancel={{false}}` (operable, but it does not close anything).
  // "Contains something focusable" is simply a different question from
  // "contains a way out"; only the component knows the second one, because only
  // the component knows what each control it renders is wired to.
  private get exits(): readonly ModalExit[] {
    const exits: ModalExit[] = [];
    if (!this.disableNativeClose) {
      exits.push({ id: 'native-close-button', keyboard: true });
    }
    if (this.cancelButton && this.closeOnCancel) {
      exits.push({ id: 'cancel-button', keyboard: true });
    }
    if (this.confirmButton && this.closeOnConfirm) {
      exits.push({ id: 'confirm-button', keyboard: true });
    }
    if (this.hasCustomKeyboardExit) {
      exits.push({ id: 'custom-keyboard-exit', keyboard: true });
    }
    // A backdrop click is a real exit, and enumerated as one, but it is not a
    // keyboard exit — WCAG 2.1.2 is about the keyboard interface, and the
    // backdrop is not focusable or activatable from it. It also defaults to
    // true, so counting it would suppress Escape on very nearly every modal.
    if (this.closeOnOutsideClick) {
      exits.push({ id: 'backdrop-click', keyboard: false });
    }
    return exits;
  }

  // Whether a keyboard user can leave the modal without pressing Escape.
  private hasKeyboardExit(): boolean {
    return this.exits.some((exit) => exit.keyboard);
  }

  // Dev-only accessibility audit, run once per open. Both `warn` calls are
  // stripped from production builds along with their condition arguments.
  private auditAccessibility(): void {
    warn(
      `ember-remodal: the modal "${this.name}" was opened without a resolvable accessible name, so its <dialog> is announced only as "dialog" (WCAG 4.1.2). Pass @title, @ariaLabel="…", or @ariaLabelledBy pointing at an element that exists and has text.`,
      this.hasAccessibleName,
      { id: 'ember-remodal.modal-without-accessible-name' },
    );
    warn(
      `ember-remodal: the modal "${this.name}" was opened with @closeOnEscape={{false}} and renders no control that closes it, so a keyboard user would have no way out (WCAG 2.1.2). Escape will close it anyway. Render the built-in close button (drop @disableNativeClose / @disableForeground), add a @cancelButton or @confirmButton that closes, or — if your own block content provides the way out — declare it with @hasCustomKeyboardExit={{true}}.`,
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
    // Unguarded on purpose. Both callers are inside the funnel: close() turns a
    // throw into its own rejection (a contract its tests pin), and
    // handleDialogClose — the native `close` listener, which is the one caller
    // with no promise behind it — is produced by domHandler.
    this.observeCallback(this.opt('onClose')?.(effectiveReason));
  }

  private async waitForDialogElement(): Promise<void> {
    // The same hidden-tab hazard animationsSettled guards against, in the other
    // frame-waiting loop: requestAnimationFrame does not advance in a
    // backgrounded tab, so a bare rAF loop never finished there — open() never
    // settled and the waitForPromise waiter around this call leaked for the
    // rest of the session (in a test suite, that hangs every later settled()).
    // Ticks rather than frames while hidden, because rendering keeps going in a
    // hidden tab even though painting does not: there is still something to
    // wait for, it just cannot be counted in frames.
    const hidden = whenDocumentHidden();
    try {
      for (
        let i = 0;
        i < 10 && !this.dialogElement && !this.isDestroying;
        i++
      ) {
        if (documentIsHidden()) {
          await nextTick();
        } else {
          // Racing the visibility change so a tab backgrounded mid-wait
          // switches to ticks on the next pass instead of stalling on a frame
          // that will never arrive.
          await Promise.race([nextFrame(), hidden.promise]);
        }
      }
    } finally {
      hidden.dispose();
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
    {{! ...attributes stays on this outer span, and Element stays
        HTMLSpanElement. Splatting onto the <dialog> instead was considered as
        a way to let a consumer set aria-labelledby themselves: rejected,
        because every attribute on that element is addon-owned and
        load-bearing — the state classes, the naming attributes chosen by
        labelledById/labelAttribute, data-test-id, and five event modifiers —
        and splattribute merging would let a consumer silently replace any of
        them. @ariaLabelledBy is the supported way to name the dialog from
        consumer markup. }}
    <span
      class="remodal-component"
      data-test-id={{this.opt "dataTestId"}}
      ...attributes
    >
      {{! Every class token the addon emits is namespaced: remodal-* or
          ember-remodal-*. 1.x/2.x also emitted bare single-word tokens beside
          them — outer, link, text, open, button, window, close, … — which CSS
          frameworks own (Bootstrap's .close, Bulma's .button) and which the
          addon cannot outrank from a stylesheet whose bundle position it does
          not control. They are retired; the @legacyClassNames argument emits
          them alongside the namespaced ones. }}
      {{#if (this.opt "linkButton")}}
        <a
          href="#"
          class="ember-remodal ember-remodal-outer ember-remodal-link ember-remodal-text
            {{if this.legacyClassNames 'outer link text'}}
            {{this.opt 'buttonClasses'}}
            {{this.opt 'outerButtonClasses'}}"
          data-test-id="linkButton"
          {{on "click" this.handleOpenClick}}
        >{{this.opt "linkButton"}}</a>
      {{else if (this.opt "openLink")}}
        <a
          href="#"
          class="ember-remodal ember-remodal-outer ember-remodal-link ember-remodal-text
            {{if this.legacyClassNames 'outer link text'}}
            {{this.opt 'buttonClasses'}}
            {{this.opt 'outerButtonClasses'}}
            {{this.opt 'openLinkClasses'}}"
          data-test-id="openLink"
          {{on "click" this.handleOpenClick}}
        >{{this.opt "openLink"}}</a>
      {{else if (this.opt "openButton")}}
        <button
          type="button"
          class="ember-remodal ember-remodal-outer ember-remodal-open ember-remodal-button
            {{if this.legacyClassNames 'outer open button'}}
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
        aria-label={{this.labelAttribute}}
        {{on "mousedown" this.handleWrapperMouseDown}}
        {{on "click" this.handleWrapperClick}}
        {{on "cancel" this.handleNativeCancel}}
        {{on "close" this.handleDialogClose}}
        {{this.registerDialog}}
      >
        {{! `remodal-is-initialized` has no rule behind it: upstream used it to
            unwind a display:none anti-FOUC rule, which the dialog element makes
            unnecessary. It is still emitted because 1.x/2.x consumer CSS and
            test selectors may key off it.

            The bare "invisible" token is the sharpest case for retiring the
            aliases: Bootstrap 3/4/5 own it as visibility:hidden !important,
            which rendered a fully hidden modal that still held the top layer
            and trapped focus. The addon's @disableForeground styling hangs off
            the namespaced ember-remodal-invisible; the bare name comes back
            only under @legacyClassNames. }}
        <div
          class="remodal remodal-is-initialized
            {{this.stateClass}}
            ember-remodal
            {{this.name}}
            {{this.modifier}}
            {{this.animationState}}
            ember-remodal-window
            {{if this.legacyClassNames 'window'}}
            {{if
              this.disableForeground
              (if
                this.legacyClassNames
                'ember-remodal-invisible invisible'
                'ember-remodal-invisible'
              )
            }}
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
              class="remodal-close ember-remodal ember-remodal-inner ember-remodal-native ember-remodal-close
                {{if this.legacyClassNames 'inner native close'}}"
              data-test-id="nativeClose"
              {{on "click" this.closeAction}}
            ></button>
          {{/unless}}

          {{#if this.title}}
            <h2
              id={{this.titleId}}
              class="ember-remodal ember-remodal-inner ember-remodal-title ember-remodal-text
                {{if this.legacyClassNames 'inner title text'}}"
              data-test-id="title"
            >{{this.title}}</h2>
          {{/if}}

          {{#if (this.opt "text")}}
            <p
              class="ember-remodal ember-remodal-inner ember-remodal-paragraph ember-remodal-text
                {{if this.legacyClassNames 'inner paragraph text'}}"
              data-test-id="text"
            >{{this.opt "text"}}</p>
          {{/if}}

          {{#if (has-block)}}
            <div
              class="ember-remodal ember-remodal-inner ember-remodal-yielded ember-remodal-content
                {{if this.legacyClassNames 'inner yielded content'}}"
              data-test-id="yielded"
            >
              {{yield
                (hash
                  open=(component
                    ErButton
                    destination=this.openButtonTarget
                    onClick=this.handleOpenClick
                  )
                  confirm=(component ErButton onClick=this.confirmAction)
                  cancel=(component ErButton onClick=this.cancelAction)
                  isOpen=this.isOpen
                  openAction=this.openAction
                  closeAction=this.closeAction
                  confirmAction=this.confirmAction
                  cancelAction=this.cancelAction
                )
              }}
            </div>
          {{/if}}

          {{#if this.cancelButton}}
            <button
              type="button"
              class="remodal-cancel ember-remodal ember-remodal-inner ember-remodal-cancel ember-remodal-button
                {{if this.legacyClassNames 'inner cancel button'}}
                {{this.opt 'buttonClasses'}}
                {{this.opt 'innerButtonClasses'}}
                {{this.opt 'cancelButtonClasses'}}"
              data-test-id="cancelButton"
              {{on "click" this.cancelAction}}
            >{{this.cancelButton}}</button>
          {{/if}}

          {{#if this.confirmButton}}
            <button
              type="button"
              class="remodal-confirm ember-remodal ember-remodal-inner ember-remodal-confirm ember-remodal-button
                {{if this.legacyClassNames 'inner confirm button'}}
                {{this.opt 'buttonClasses'}}
                {{this.opt 'innerButtonClasses'}}
                {{this.opt 'confirmButtonClasses'}}"
              data-test-id="confirmButton"
              {{on "click" this.confirmAction}}
            >{{this.confirmButton}}</button>
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
