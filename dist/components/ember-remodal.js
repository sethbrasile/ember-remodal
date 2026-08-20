import "./../styles/ember-remodal.css"
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { warn } from '@ember/debug';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';
import { service } from '@ember/service';
import { waitForPromise } from '@ember/test-waiters';
import { modifier } from 'ember-modifier';
import ErButton from './ember-remodal/er-button.js';
import { precompileTemplate } from '@ember/template-compilation';
import { setComponentTemplate } from '@ember/component';
import { g, i } from 'decorator-transforms/runtime-esm';

;

function defer() {
  let resolve;
  const promise = new Promise(res => {
    resolve = res;
  });
  return {
    promise,
    resolve
  };
}
function nextFrame() {
  return new Promise(resolve => requestAnimationFrame(() => resolve()));
}
// What a backgrounded tab has instead of a frame. Rendering is not frame-driven
// — a hidden tab keeps rendering, it just stops painting — so a wait for the
// render to catch up still has something to wait FOR while hidden; it simply
// cannot be measured in frames.
function nextTick() {
  return new Promise(resolve => setTimeout(resolve, 0));
}
// Brand attached by `EmberRemodal#domHandler`, the factory every DOM-bound
// handler is produced by. Registered with `Symbol.for` rather than kept
// module-local so a test can enumerate the template's bindings and assert each
// one carries it, without the component exporting a testing seam that the
// package's `"./*"` entry would make semver-visible.
const DOM_HANDLER = Symbol.for('ember-remodal:dom-handler');
function documentIsHidden() {
  return typeof document !== 'undefined' && document.hidden;
}
// Resolves the first time the document becomes hidden, and hands back a
// disposer for the listener. requestAnimationFrame is suspended and CSS
// animations stop advancing while a tab is backgrounded, so anything waiting on
// either (our frame preamble, `animation.finished`) can hang indefinitely —
// racing this lets the transition finalize immediately instead.
function whenDocumentHidden() {
  if (typeof document === 'undefined') {
    return {
      promise: new Promise(() => {}),
      dispose: () => {}
    };
  }
  let dispose = () => {};
  const promise = new Promise(resolve => {
    const onVisibilityChange = () => {
      if (document.hidden) {
        resolve();
      }
    };
    document.addEventListener('visibilitychange', onVisibilityChange);
    dispose = () => {
      document.removeEventListener('visibilitychange', onVisibilityChange);
    };
  });
  return {
    promise,
    dispose
  };
}
// The wrapper <dialog> is `overflow: auto`, so a press on its own scrollbar
// targets the dialog element itself just like a press on the backdrop does.
// The scrollbar gutter is the only region of the element outside its client
// box, and `offsetX/offsetY` are measured from the padding edge.
function isScrollbarPress(event) {
  if (!(event instanceof MouseEvent) || !(event.target instanceof Element)) {
    return false;
  }
  const {
    clientWidth,
    clientHeight
  } = event.target;
  return event.offsetX > clientWidth || event.offsetY > clientHeight;
}
const MISSING_DIALOG_MESSAGE = 'ember-remodal: "open" was called, but the modal\'s <dialog> element never rendered, so there is nothing to open.';
// Shared scroll-lock bookkeeping so multiple simultaneously-open modals
// only lock/unlock the document once. The set tracks which modal instances
// currently hold the lock; the document locks on 0 → 1 and unlocks on 1 → 0.
const lockHolders = new Set();
let savedBodyPaddingRight = null;
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
function setAnimationDisabledForTesting(disabled) {
  testSupportAnimationDisabled = disabled;
}
function scrollLockStateForTesting() {
  return {
    holders: lockHolders.size,
    locked: typeof document !== 'undefined' && document.documentElement.classList.contains('remodal-is-locked'),
    bodyPaddingRight: typeof document === 'undefined' ? '' : document.body.style.paddingRight
  };
}
function resetScrollLockForTesting() {
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
function acquireScrollLock(holder) {
  const wasEmpty = lockHolders.size === 0;
  lockHolders.add(holder);
  if (wasEmpty) {
    // Measure before locking: overflow-hidden removes the scrollbar.
    const scrollbarWidth = window.innerWidth - document.documentElement.clientWidth;
    savedBodyPaddingRight = document.body.style.paddingRight;
    if (scrollbarWidth > 0) {
      document.body.style.paddingRight = `${scrollbarWidth}px`;
    }
    document.documentElement.classList.add('remodal-is-locked');
  }
}
function releaseScrollLock(holder) {
  const removed = lockHolders.delete(holder);
  if (removed && lockHolders.size === 0) {
    document.documentElement.classList.remove('remodal-is-locked');
    document.body.style.paddingRight = savedBodyPaddingRight ?? '';
    savedBodyPaddingRight = null;
  }
}
// The accname algorithm trims and collapses whitespace, so " " names nothing:
// it produces an <h2> with no perceivable text, an aria-labelledby pointing at
// it, and a guard cheerfully reporting the dialog as named.
//
// Every consumer-supplied string that decides whether an element renders,
// supplies an accessible name, or is counted as a control goes through here, so
// "present" means the same thing at every one of them — and each of those
// decisions reads the SAME getter, so a render condition and the logic that
// counts the element can never disagree about whether it exists. The exceptions
// are deliberate and enumerated in the blank-string-arguments test: the class
// tokens (@modifier, @*Classes), @dataTestId and @name gate no render and name
// no element, and a blank class token is collapsed by the HTML parser anyway.
//
// The class is a real one: it surfaced on @title, then on @cancelButton /
// @confirmButton, then on the open triggers, once per review round.
function presentString(value) {
  return value !== undefined && value.trim() !== '' ? value : undefined;
}
// One way a modal can be dismissed. `keyboard` is what the WCAG 2.1.2 gate
// asks about: a pointer-only exit is not a way out of a keyboard trap.

function createOpenButtonTarget() {
  if (typeof document === 'undefined') {
    return null;
  }
  const span = document.createElement('span');
  span.className = 'ember-remodal-open-button-target';
  return span;
}
class EmberRemodal extends Component {
  static {
    g(this.prototype, "remodal", [service]);
  }
  #remodal = (i(this, "remodal"), void 0);
  static {
    g(this.prototype, "state", [tracked], function () {
      return 'closed';
    });
  }
  #state = (i(this, "state"), void 0);
  static {
    g(this.prototype, "serviceOverrides", [tracked], function () {
      return null;
    });
  }
  #serviceOverrides = (i(this, "serviceOverrides"), void 0);
  dialogElement = null;
  // Created eagerly (not tracked) so yielded `m.open` buttons have a stable
  // portal destination from the very first render; the element is attached to
  // the DOM by `attachOpenButtonTarget`. Only null in SSR, where ErButton
  // falls back to rendering inline.
  openButtonTarget = createOpenButtonTarget();
  openDeferred = null;
  closeDeferred = null;
  // Bumped whenever a new transition (open/close/forced close/destroy) takes
  // over; stale in-flight transitions notice and settle without side effects.
  transitionId = 0;
  // The name this instance was registered under; name changes after
  // registration do not re-key the registry.
  registeredName = null;
  // Whether open() has ever actually started a transition; used to scope the
  // "close before open" warning.
  hasOpened = false;
  // The reason of the close currently in flight. Stashed on the instance so a
  // stale native `close` event that finalizes the close on our behalf still
  // reports the reason to @onClose instead of dropping it.
  pendingCloseReason = undefined;
  // Latched on mousedown so backdrop dismissal requires the press AND the
  // release to land on the dialog itself.
  pressedOnBackdrop = false;
  testingAnimationDisabled;
  constructor(owner, args) {
    super(owner, args);
    this.testingAnimationDisabled = this.resolveTestingAnimationDisabled(owner);
    if (this.forService) {
      this.registeredName = this.name;
      this.remodal.register(this.registeredName, this);
    }
  }
  willDestroy() {
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
  resolveTestingAnimationDisabled(owner) {
    try {
      const resolverOwner = owner;
      const config = resolverOwner?.resolveRegistration?.('config:environment');
      return config?.environment === 'test' && Boolean(config?.['ember-remodal']?.disableAnimationWhileTesting);
    } catch {
      return false;
    }
  }
  // --- option resolution: serviceOverrides → @options → args → default ---
  // (matches 2.x, where service opts and the options hash overwrote direct
  // attrs via setProperties)
  opt = key => {
    return this.serviceOverrides?.[key] ?? this.args.options?.[key] ?? this.args[key];
  };
  get name() {
    return this.opt('name') ?? 'ember-remodal';
  }
  get forService() {
    return this.opt('forService') ?? false;
  }
  get modifier() {
    return this.opt('modifier') ?? '';
  }
  // --- accessible naming ---
  // Stable per-instance id for the rendered <h2>, so the <dialog> can point
  // aria-labelledby at it. Multiple modals on a page each get their own.
  get titleId() {
    return `${guidFor(this)}-title`;
  }
  // Blank strings are treated as absent: `aria-label=" "` names nothing, and a
  // blank @title renders no <h2> worth pointing aria-labelledby at.
  get title() {
    return presentString(this.opt('title'));
  }
  get ariaLabel() {
    return presentString(this.opt('ariaLabel'));
  }
  get ariaLabelledBy() {
    return presentString(this.opt('ariaLabelledBy'));
  }
  // Exactly one naming attribute is ever emitted, in the accname algorithm's
  // own order: aria-labelledby, then aria-label, then the generated <h2> id.
  // Emitting two would be harmless to a screen reader but would leave the DOM
  // claiming a name that is not the one in effect — and silently ignoring an
  // explicitly-passed @ariaLabel is worse than honoring it.
  get labelledById() {
    if (this.ariaLabelledBy) {
      return this.ariaLabelledBy;
    }
    if (this.ariaLabel) {
      return undefined;
    }
    return this.title ? this.titleId : undefined;
  }
  get labelAttribute() {
    return this.ariaLabelledBy ? undefined : this.ariaLabel;
  }
  // Whether the dialog actually resolves to a name — not whether a naming
  // attribute is present. A consumer-supplied @ariaLabelledBy can point at an
  // id that does not exist (a typo, a heading behind an {{#if}} that did not
  // render), which names nothing at all; trusting the attribute would be the
  // same "the platform handles it" assumption this guard exists to catch.
  // Read only from auditAccessibility, i.e. with the dialog open and its
  // subtree in the document.
  get hasAccessibleName() {
    if (this.ariaLabelledBy) {
      return this.labelledByResolves;
    }
    return Boolean(this.ariaLabel) || Boolean(this.title);
  }
  get labelledByResolves() {
    const idref = this.ariaLabelledBy;
    if (!idref || typeof document === 'undefined') {
      return false;
    }
    return idref.split(/\s+/).filter(Boolean).some(id => {
      const target = document.getElementById(id);
      return (target?.textContent ?? '').trim() !== '';
    });
  }
  get closeButtonLabel() {
    // `||` already caught `''`, but not `'  '` — which would have put a
    // whitespace-only aria-label on the close button, i.e. the one control on a
    // @disableForeground modal, named nothing at all.
    return presentString(this.opt('closeButtonLabel')) ?? 'Close Modal';
  }
  // Renders a <p>. A blank string is not text, and an empty paragraph in the
  // card is a rendered element nobody asked for.
  get text() {
    return presentString(this.opt('text'));
  }
  // The three open triggers. A blank label renders a trigger with no accessible
  // name (WCAG 4.1.2) — a button announced as "button", a link as "link". They
  // are an if/else-if chain in the template, and each `{{#if}}` reads the same
  // getter its content does, so a blank one falls through to the next candidate
  // instead of winning the chain and rendering nothing perceivable.
  get linkButton() {
    return presentString(this.opt('linkButton'));
  }
  get openLink() {
    return presentString(this.opt('openLink'));
  }
  get openButton() {
    return presentString(this.opt('openButton'));
  }
  // NB-31's defect on the opposite element. `@cancelButton=" "` passes a truthy
  // test, so the old `{{#if (this.opt "cancelButton")}}` rendered a button with
  // no perceivable label and no accessible name — and the exit enumeration
  // below counted that button as the keyboard way out, re-opening the WCAG
  // 2.1.2 trap the enumeration exists to close. One getter feeds BOTH the
  // enumeration and the render condition, so the two cannot disagree about
  // whether the button exists.
  get cancelButton() {
    return presentString(this.opt('cancelButton'));
  }
  get confirmButton() {
    return presentString(this.opt('confirmButton'));
  }
  get closeOnEscape() {
    return this.opt('closeOnEscape') ?? true;
  }
  get closeOnCancel() {
    return this.opt('closeOnCancel') ?? true;
  }
  get closeOnConfirm() {
    return this.opt('closeOnConfirm') ?? true;
  }
  get closeOnOutsideClick() {
    return this.opt('closeOnOutsideClick') ?? true;
  }
  get disableForeground() {
    return this.opt('disableForeground') ?? false;
  }
  get disableNativeClose() {
    return this.opt('disableNativeClose') ?? this.disableForeground;
  }
  get hasCustomKeyboardExit() {
    return this.opt('hasCustomKeyboardExit') ?? false;
  }
  get legacyClassNames() {
    return this.opt('legacyClassNames') ?? false;
  }
  get disableAnimation() {
    return (this.opt('disableAnimation') ?? false) || this.testingAnimationDisabled || testSupportAnimationDisabled;
  }
  get animationState() {
    return this.disableAnimation ? 'disable-animation' : '';
  }
  get stateClass() {
    return `remodal-is-${this.state}`;
  }
  get isOpen() {
    // Deliberately includes 'closing' so lazily-rendered content survives the
    // closing animation instead of vanishing the instant close() is called.
    return this.state !== 'closed';
  }
  // --- element capture modifiers ---
  registerDialog = modifier(element => {
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
  attachOpenButtonTarget = modifier(element => {
    if (this.openButtonTarget) {
      element.appendChild(this.openButtonTarget);
    }
    return () => {
      this.openButtonTarget?.remove();
    };
  });
  // --- state machine ---
  open = async () => {
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
    const deferred = defer();
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
  close = async reason => {
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
      warn('ember-remodal: You called "close" on a modal that has not yet been opened. This is not a big deal, but I thought you should know. The returned promise will immediately resolve.', this.hasOpened, {
        id: 'ember-remodal.close-called-on-uninitialized-modal'
      });
      return this;
    }
    if (this.state === 'closing' && this.closeDeferred) {
      return this.closeDeferred.promise;
    }
    const dialog = this.dialogElement;
    if (!dialog || this.isDestroying) {
      return this;
    }
    const deferred = defer();
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
  confirm = async () => {
    this.observeCallback(this.opt('onConfirm')?.());
    if (this.closeOnConfirm) {
      return this.close('confirmation');
    }
    return this;
  };
  cancel = async () => {
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
  openAction = this.domHandler(() => this.open());
  closeAction = this.domHandler(() => this.close());
  confirmAction = this.domHandler(() => this.confirm());
  cancelAction = this.domHandler(() => this.cancel());
  handleOpenClick = this.domHandler(event => {
    // Open triggers may render as `<a href="#">`; never navigate.
    event?.preventDefault();
    return this.open();
  });
  handleWrapperMouseDown = this.domHandler(event => {
    this.pressedOnBackdrop = event.target === this.dialogElement && !isScrollbarPress(event);
  });
  handleWrapperClick = this.domHandler(event => {
    // `event.target === dialog` alone is also true when a press that started
    // inside the card is released over the backdrop (the click dispatches on
    // their common ancestor, the dialog) and when the user drags the dialog's
    // own scrollbar — both would discard the user's content. Require the press
    // to have landed on the backdrop too.
    const pressedOnBackdrop = this.pressedOnBackdrop;
    this.pressedOnBackdrop = false;
    if (pressedOnBackdrop && event.target === this.dialogElement && this.closeOnOutsideClick) {
      return this.close();
    }
    return undefined;
  });
  handleNativeCancel = this.domHandler(event => {
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
  handleDialogClose = this.domHandler(() => {
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
  domHandler(run) {
    const handler = (...args) => {
      try {
        // Promise.resolve() makes a non-promise return a no-op, so the funnel
        // does not care whether the body it wraps is async.
        void Promise.resolve(run(...args)).catch(this.reportError);
      } catch (error) {
        this.reportError(error);
      }
    };
    Object.defineProperty(handler, DOM_HANDLER, {
      value: true
    });
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
  observeCallback(result) {
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
  get exits() {
    const exits = [];
    if (!this.disableNativeClose) {
      exits.push({
        id: 'native-close-button',
        keyboard: true
      });
    }
    if (this.cancelButton && this.closeOnCancel) {
      exits.push({
        id: 'cancel-button',
        keyboard: true
      });
    }
    if (this.confirmButton && this.closeOnConfirm) {
      exits.push({
        id: 'confirm-button',
        keyboard: true
      });
    }
    if (this.hasCustomKeyboardExit) {
      exits.push({
        id: 'custom-keyboard-exit',
        keyboard: true
      });
    }
    // A backdrop click is a real exit, and enumerated as one, but it is not a
    // keyboard exit — WCAG 2.1.2 is about the keyboard interface, and the
    // backdrop is not focusable or activatable from it. It also defaults to
    // true, so counting it would suppress Escape on very nearly every modal.
    if (this.closeOnOutsideClick) {
      exits.push({
        id: 'backdrop-click',
        keyboard: false
      });
    }
    return exits;
  }
  // Whether a keyboard user can leave the modal without pressing Escape.
  hasKeyboardExit() {
    return this.exits.some(exit => exit.keyboard);
  }
  // Dev-only accessibility audit, run once per open. Both `warn` calls are
  // stripped from production builds along with their condition arguments.
  auditAccessibility() {
    warn(`ember-remodal: the modal "${this.name}" was opened without a resolvable accessible name, so its <dialog> is announced only as "dialog" (WCAG 4.1.2). Pass @title, @ariaLabel="…", or @ariaLabelledBy pointing at an element that exists and has text.`, this.hasAccessibleName, {
      id: 'ember-remodal.modal-without-accessible-name'
    });
    warn(`ember-remodal: the modal "${this.name}" was opened with @closeOnEscape={{false}} and renders no control that closes it, so a keyboard user would have no way out (WCAG 2.1.2). Escape will close it anyway. Render the built-in close button (drop @disableNativeClose / @disableForeground), add a @cancelButton or @confirmButton that closes, or — if your own block content provides the way out — declare it with @hasCustomKeyboardExit={{true}}.`, this.closeOnEscape || this.hasKeyboardExit(), {
      id: 'ember-remodal.no-keyboard-exit'
    });
  }
  reportError = error => {
    // The DOM entry points above have nobody to hand a rejection to, and
    // swallowing it silently would hide a consumer callback that threw.
    console.error(error);
  };
  // The single funnel for state writes: acquires the scroll lock on the
  // closed → non-closed edge and releases it on the non-closed → closed edge,
  // so lock bookkeeping can never drift from the state machine.
  setState(next) {
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
  finalizeClose(reason) {
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
  async waitForDialogElement() {
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
      for (let i = 0; i < 10 && !this.dialogElement && !this.isDestroying; i++) {
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
  settlePendingTransitions() {
    const {
      openDeferred,
      closeDeferred
    } = this;
    this.openDeferred = null;
    this.closeDeferred = null;
    openDeferred?.resolve(this);
    closeDeferred?.resolve(this);
  }
  ownAnimations(dialog) {
    // Only wait on our own CSS animations (the `remodal-` keyframes) targeting
    // the wrapper/backdrop or the card. User content — and even consumer
    // classes applied to the card via @modalClasses — may legitimately carry
    // infinite animations (e.g. spinners) whose `finished` promise never
    // settles; waiting on those would hang open()/close() forever.
    const card = dialog.querySelector('.remodal');
    return dialog.getAnimations({
      subtree: true
    }).filter(animation => {
      if (!(animation instanceof CSSAnimation) || !animation.animationName.startsWith('remodal-')) {
        return false;
      }
      const target = animation.effect instanceof KeyframeEffect ? animation.effect.target : null;
      return target === dialog || card !== null && target === card;
    });
  }
  cancelAnimations(dialog) {
    for (const animation of this.ownAnimations(dialog)) {
      animation.cancel();
    }
  }
  animationsSettled(dialog, runId) {
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
    return waitForPromise(Promise.race([this.ownAnimationsSettled(dialog, runId), hidden.promise]).finally(hidden.dispose));
  }
  async ownAnimationsSettled(dialog, runId) {
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
      await Promise.allSettled(animations.map(a => a.finished));
    }
  }
  static {
    setComponentTemplate(precompileTemplate("{{!-- ...attributes stays on this outer span, and Element stays\n    HTMLSpanElement. Splatting onto the <dialog> instead was considered as\n    a way to let a consumer set aria-labelledby themselves: rejected,\n    because every attribute on that element is addon-owned and\n    load-bearing \u2014 the state classes, the naming attributes chosen by\n    labelledById/labelAttribute, data-test-id, and five event modifiers \u2014\n    and splattribute merging would let a consumer silently replace any of\n    them. @ariaLabelledBy is the supported way to name the dialog from\n    consumer markup. --}}\n<span class=\"remodal-component\" data-test-id={{this.opt \"dataTestId\"}} ...attributes>\n  {{!-- Every class token the addon emits is namespaced: remodal-* or\n      ember-remodal-*. 1.x/2.x also emitted bare single-word tokens beside\n      them \u2014 outer, link, text, open, button, window, close, \u2026 \u2014 which CSS\n      frameworks own (Bootstrap's .close, Bulma's .button) and which the\n      addon cannot outrank from a stylesheet whose bundle position it does\n      not control. They are retired; the @legacyClassNames argument emits\n      them alongside the namespaced ones. --}}\n  {{#if this.linkButton}}\n    <a href=\"#\" class=\"ember-remodal ember-remodal-outer ember-remodal-link ember-remodal-text\n        {{if this.legacyClassNames \"outer link text\"}}\n        {{this.opt \"buttonClasses\"}}\n        {{this.opt \"outerButtonClasses\"}}\" data-test-id=\"linkButton\" {{on \"click\" this.handleOpenClick}}>{{this.linkButton}}</a>\n  {{else if this.openLink}}\n    <a href=\"#\" class=\"ember-remodal ember-remodal-outer ember-remodal-link ember-remodal-text\n        {{if this.legacyClassNames \"outer link text\"}}\n        {{this.opt \"buttonClasses\"}}\n        {{this.opt \"outerButtonClasses\"}}\n        {{this.opt \"openLinkClasses\"}}\" data-test-id=\"openLink\" {{on \"click\" this.handleOpenClick}}>{{this.openLink}}</a>\n  {{else if this.openButton}}\n    <button type=\"button\" class=\"ember-remodal ember-remodal-outer ember-remodal-open ember-remodal-button\n        {{if this.legacyClassNames \"outer open button\"}}\n        {{this.opt \"buttonClasses\"}}\n        {{this.opt \"outerButtonClasses\"}}\n        {{this.opt \"openButtonClasses\"}}\" data-test-id=\"openButton\" {{on \"click\" this.handleOpenClick}}>{{this.openButton}}</button>\n  {{/if}}\n\n  <span class=\"ember-remodal-open-button-target-host\" {{this.attachOpenButtonTarget}}></span>\n\n  {{!-- The wrapper click handler only detects clicks on the backdrop area\n      (outside the card) to support closeOnOutsideClick; it is not a\n      keyboard-reachable control (Escape is handled via the native cancel\n      event), so no-invalid-interactive does not apply.\n\n      The mousedown listener does not activate anything either \u2014 it only\n      latches where the press started, so that dismissing on a backdrop\n      click requires the press AND the release to land on the backdrop.\n      Dismissal itself still happens on click. --}}\n  {{!-- template-lint-disable no-invalid-interactive no-pointer-down-event-binding --}}\n  <dialog class=\"remodal-wrapper\n      {{this.stateClass}}\n      {{this.modifier}}\n      {{this.animationState}}\" data-test-id=\"modalWrapper\" aria-labelledby={{this.labelledById}} aria-label={{this.labelAttribute}} {{on \"mousedown\" this.handleWrapperMouseDown}} {{on \"click\" this.handleWrapperClick}} {{on \"cancel\" this.handleNativeCancel}} {{on \"close\" this.handleDialogClose}} {{this.registerDialog}}>\n    {{!-- `remodal-is-initialized` has no rule behind it: upstream used it to\n        unwind a display:none anti-FOUC rule, which the dialog element makes\n        unnecessary. It is still emitted because 1.x/2.x consumer CSS and\n        test selectors may key off it.\n\n        The bare \"invisible\" token is the sharpest case for retiring the\n        aliases: Bootstrap 3/4/5 own it as visibility:hidden !important,\n        which rendered a fully hidden modal that still held the top layer\n        and trapped focus. The addon's @disableForeground styling hangs off\n        the namespaced ember-remodal-invisible; the bare name comes back\n        only under @legacyClassNames. --}}\n    <div class=\"remodal remodal-is-initialized\n        {{this.stateClass}}\n        ember-remodal\n        {{this.name}}\n        {{this.modifier}}\n        {{this.animationState}}\n        ember-remodal-window\n        {{if this.legacyClassNames \"window\"}}\n        {{if this.disableForeground (if this.legacyClassNames \"ember-remodal-invisible invisible\" \"ember-remodal-invisible\")}}\n        {{this.opt \"modalClasses\"}}\" data-test-id=\"modalWindow\">\n      {{#unless this.disableNativeClose}}\n        {{!-- The visible glyph comes from `.remodal-close::before`, and\n            pseudo-element content participates in name-from-contents,\n            which OUTRANKS `title` in the accname algorithm \u2014 without an\n            aria-label this button is announced as \"times, button\". --}}\n        <button type=\"button\" aria-label={{this.closeButtonLabel}} title={{this.closeButtonLabel}} class=\"remodal-close ember-remodal ember-remodal-inner ember-remodal-native ember-remodal-close\n            {{if this.legacyClassNames \"inner native close\"}}\" data-test-id=\"nativeClose\" {{on \"click\" this.closeAction}}></button>\n      {{/unless}}\n\n      {{#if this.title}}\n        <h2 id={{this.titleId}} class=\"ember-remodal ember-remodal-inner ember-remodal-title ember-remodal-text\n            {{if this.legacyClassNames \"inner title text\"}}\" data-test-id=\"title\">{{this.title}}</h2>\n      {{/if}}\n\n      {{#if this.text}}\n        <p class=\"ember-remodal ember-remodal-inner ember-remodal-paragraph ember-remodal-text\n            {{if this.legacyClassNames \"inner paragraph text\"}}\" data-test-id=\"text\">{{this.text}}</p>\n      {{/if}}\n\n      {{#if (has-block)}}\n        <div class=\"ember-remodal ember-remodal-inner ember-remodal-yielded ember-remodal-content\n            {{if this.legacyClassNames \"inner yielded content\"}}\" data-test-id=\"yielded\">\n          {{yield (hash open=(component ErButton destination=this.openButtonTarget onClick=this.handleOpenClick) confirm=(component ErButton onClick=this.confirmAction) cancel=(component ErButton onClick=this.cancelAction) isOpen=this.isOpen openAction=this.openAction closeAction=this.closeAction confirmAction=this.confirmAction cancelAction=this.cancelAction)}}\n        </div>\n      {{/if}}\n\n      {{#if this.cancelButton}}\n        <button type=\"button\" class=\"remodal-cancel ember-remodal ember-remodal-inner ember-remodal-cancel ember-remodal-button\n            {{if this.legacyClassNames \"inner cancel button\"}}\n            {{this.opt \"buttonClasses\"}}\n            {{this.opt \"innerButtonClasses\"}}\n            {{this.opt \"cancelButtonClasses\"}}\" data-test-id=\"cancelButton\" {{on \"click\" this.cancelAction}}>{{this.cancelButton}}</button>\n      {{/if}}\n\n      {{#if this.confirmButton}}\n        <button type=\"button\" class=\"remodal-confirm ember-remodal ember-remodal-inner ember-remodal-confirm ember-remodal-button\n            {{if this.legacyClassNames \"inner confirm button\"}}\n            {{this.opt \"buttonClasses\"}}\n            {{this.opt \"innerButtonClasses\"}}\n            {{this.opt \"confirmButtonClasses\"}}\" data-test-id=\"confirmButton\" {{on \"click\" this.confirmAction}}>{{this.confirmButton}}</button>\n      {{/if}}\n    </div>\n  </dialog>\n  {{!-- Re-arm both rules: an unterminated disable comment suppresses them\n      all the way to the end of the template, which would have covered the\n      whole card subtree and every yielded block inside it. --}}\n  {{!-- template-lint-enable no-invalid-interactive no-pointer-down-event-binding --}}\n</span>", {
      strictMode: true,
      scope: () => ({
        on,
        hash,
        ErButton
      })
    }), this);
  }
}

export { EmberRemodal as default, resetScrollLockForTesting, scrollLockStateForTesting, setAnimationDisabledForTesting };
//# sourceMappingURL=ember-remodal.js.map
