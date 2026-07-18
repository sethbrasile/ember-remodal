import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { warn } from '@ember/debug';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
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
}

export interface EmberRemodalArgs extends EmberRemodalOptions {
  options?: EmberRemodalOptions;
  onBeforeOpen?: () => unknown;
  onOpen?: () => void;
  onClose?: (reason?: CloseReason) => void;
  onConfirm?: () => void;
  onCancel?: () => void;
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
    this.setState('closed');
    if (this.dialogElement?.open) {
      this.dialogElement.close();
    }
    this.settlePendingTransitions();
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
    if (this.isDestroying || this.state === 'opened') {
      return this;
    }
    if (this.state === 'opening' && this.openDeferred) {
      return this.openDeferred.promise;
    }
    if (this.args.onBeforeOpen?.() === false) {
      return this;
    }
    if (!this.dialogElement) {
      // e.g. service.open() during the initial render pass, before our
      // <dialog> has been inserted; give rendering a few frames to catch up.
      await waitForPromise(this.waitForDialogElement());
    }
    if (this.isDestroying) {
      return this;
    }
    const dialog = this.dialogElement;
    if (!dialog) {
      warn(
        'ember-remodal: "open" was called, but the modal\'s <dialog> element never rendered, so there is nothing to open. The returned promise will immediately resolve.',
        false,
        { id: 'ember-remodal.missing-dialog-element' },
      );
      return this;
    }

    const deferred = defer<this>();
    this.openDeferred = deferred;
    const runId = ++this.transitionId;
    this.hasOpened = true;

    if (this.state === 'closing') {
      // Interrupt the in-flight close: cancelling its animations wakes its
      // continuation, which sees the stale transitionId and settles itself
      // without closing the dialog.
      this.cancelAnimations(dialog);
    }
    if (!dialog.open) {
      dialog.showModal();
    }
    this.setState('opening');

    await this.animationsSettled(dialog, runId);

    if (this.openDeferred === deferred) {
      this.openDeferred = null;
    }
    if (this.transitionId === runId && !this.isDestroying) {
      this.setState('opened');
      this.args.onOpen?.();
    }
    deferred.resolve(this);
    return deferred.promise;
  };

  close = async (reason?: CloseReason): Promise<this> => {
    if (this.state === 'closed') {
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

    if (this.state === 'opening') {
      // Interrupt the in-flight open; its continuation settles itself.
      this.cancelAnimations(dialog);
    }
    this.setState('closing');

    await this.animationsSettled(dialog, runId);

    if (this.closeDeferred === deferred) {
      this.closeDeferred = null;
    }
    if (this.transitionId === runId && !this.isDestroying) {
      this.finalizeClose(reason);
    }
    deferred.resolve(this);
    return deferred.promise;
  };

  confirm = (): Promise<this> => {
    this.args.onConfirm?.();
    if (this.closeOnConfirm) {
      return this.close('confirmation');
    }
    return Promise.resolve(this);
  };

  cancel = (): Promise<this> => {
    this.args.onCancel?.();
    if (this.closeOnCancel) {
      return this.close('cancellation');
    }
    return Promise.resolve(this);
  };

  // Zero-arg wrappers safe to use as DOM event handlers (they swallow the
  // Event argument so it can never be mistaken for a close reason).

  openAction = (): void => {
    void this.open();
  };

  closeAction = (): void => {
    void this.close();
  };

  confirmAction = (): void => {
    void this.confirm();
  };

  cancelAction = (): void => {
    void this.cancel();
  };

  handleOpenClick = (event?: Event): void => {
    // Open triggers may render as `<a href="#">`; never navigate.
    event?.preventDefault();
    void this.open();
  };

  handleWrapperClick = (event: Event): void => {
    if (event.target === this.dialogElement && this.closeOnOutsideClick) {
      void this.close();
    }
  };

  handleNativeCancel = (event: Event): void => {
    // We own the closing animation, so never let the browser close instantly.
    event.preventDefault();
    if (this.closeOnEscape) {
      void this.close();
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
    this.setState('closed');
    if (this.dialogElement?.open) {
      this.dialogElement.close();
    }
    this.settlePendingTransitions();
    this.args.onClose?.(reason);
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
    if (this.disableAnimation) {
      return Promise.resolve();
    }
    // The waiter keeps `settled()` (and `await click(…)`) reliable in tests.
    return waitForPromise(
      (async () => {
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
      })(),
    );
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
          event), so no-invalid-interactive does not apply. }}
      {{! template-lint-disable no-invalid-interactive }}
      <dialog
        class="remodal-wrapper
          {{this.stateClass}}
          {{this.modifier}}
          {{this.animationState}}"
        data-test-id="modalWrapper"
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
            <button
              type="button"
              title="Close Modal"
              class="remodal-close ember-remodal inner native close"
              data-test-id="nativeClose"
              {{on "click" this.closeAction}}
            ></button>
          {{/unless}}

          {{#if (this.opt "title")}}
            <h2
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
    </span>
  </template>
}
