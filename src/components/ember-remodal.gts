import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { getOwner } from '@ember/owner';
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
// only lock/unlock the document once.
let openModalCount = 0;
let savedBodyPaddingRight: string | null = null;

function acquireScrollLock(): void {
  openModalCount += 1;
  if (openModalCount === 1) {
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

function releaseScrollLock(): void {
  openModalCount = Math.max(0, openModalCount - 1);
  if (openModalCount === 0) {
    document.documentElement.classList.remove('remodal-is-locked');
    document.body.style.paddingRight = savedBodyPaddingRight ?? '';
    savedBodyPaddingRight = null;
  }
}

export default class EmberRemodal extends Component<EmberRemodalSignature> {
  @service declare remodal: RemodalService;

  @tracked state: ModalState = 'closed';
  @tracked serviceOverrides: EmberRemodalOptions | null = null;
  @tracked openButtonTarget: Element | null = null;

  dialogElement: HTMLDialogElement | null = null;

  private openDeferred: Deferred<this> | null = null;
  private closeDeferred: Deferred<this> | null = null;
  // Bumped whenever a new transition (open/close/forced close/destroy) takes
  // over; stale in-flight transitions notice and settle without side effects.
  private transitionId = 0;
  private holdsScrollLock = false;

  constructor(owner: Owner, args: EmberRemodalArgs) {
    super(owner, args);
    if (this.forService) {
      this.remodal.register(this.name, this);
    }
  }

  override willDestroy(): void {
    super.willDestroy();
    this.transitionId += 1;
    if (this.forService) {
      this.remodal.unregister(this.name, this);
    }
    if (this.dialogElement?.open) {
      this.dialogElement.close();
    }
    this.releaseLock();
    this.settlePendingTransitions();
  }

  // --- option resolution: serviceOverrides → args → @options → default ---

  private option<K extends keyof EmberRemodalOptions>(
    key: K,
  ): EmberRemodalOptions[K] {
    return (
      this.serviceOverrides?.[key] ?? this.args[key] ?? this.args.options?.[key]
    );
  }

  get name(): string {
    return this.option('name') ?? 'ember-remodal';
  }

  get title() {
    return this.option('title');
  }

  get text() {
    return this.option('text');
  }

  get confirmButton() {
    return this.option('confirmButton');
  }

  get cancelButton() {
    return this.option('cancelButton');
  }

  get openButton() {
    return this.option('openButton');
  }

  get openLink() {
    return this.option('openLink');
  }

  get linkButton() {
    return this.option('linkButton');
  }

  get forService(): boolean {
    return this.option('forService') ?? false;
  }

  get dataTestId() {
    return this.option('dataTestId');
  }

  get modifier(): string {
    return this.option('modifier') ?? '';
  }

  get modalClasses() {
    return this.option('modalClasses');
  }

  get buttonClasses() {
    return this.option('buttonClasses');
  }

  get outerButtonClasses() {
    return this.option('outerButtonClasses');
  }

  get innerButtonClasses() {
    return this.option('innerButtonClasses');
  }

  get openButtonClasses() {
    return this.option('openButtonClasses');
  }

  get openLinkClasses() {
    return this.option('openLinkClasses');
  }

  get cancelButtonClasses() {
    return this.option('cancelButtonClasses');
  }

  get confirmButtonClasses() {
    return this.option('confirmButtonClasses');
  }

  get closeOnEscape(): boolean {
    return this.option('closeOnEscape') ?? true;
  }

  get closeOnCancel(): boolean {
    return this.option('closeOnCancel') ?? true;
  }

  get closeOnConfirm(): boolean {
    return this.option('closeOnConfirm') ?? true;
  }

  get closeOnOutsideClick(): boolean {
    return this.option('closeOnOutsideClick') ?? true;
  }

  get disableForeground(): boolean {
    return this.option('disableForeground') ?? false;
  }

  get disableNativeClose(): boolean {
    return this.option('disableNativeClose') ?? this.disableForeground;
  }

  get disableAnimation(): boolean {
    if (this.option('disableAnimation')) {
      return true;
    }
    try {
      const owner = getOwner(this) as unknown as
        { resolveRegistration?: (name: string) => unknown } | undefined;
      const config = owner?.resolveRegistration?.('config:environment') as
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

  get animationState(): string {
    return this.disableAnimation ? 'disable-animation' : '';
  }

  get stateClass(): string {
    return `remodal-is-${this.state}`;
  }

  get isOpen(): boolean {
    return this.state === 'opening' || this.state === 'opened';
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

  captureOpenButtonTarget = modifier((element: Element) => {
    // Deferred to a microtask: the tracked target may already have been
    // consumed by yielded `m.open` buttons during this same render pass, and
    // writing it synchronously would trigger the backtracking-rerender
    // assertion. The waiter keeps `settled()` reliable in tests.
    void waitForPromise(
      Promise.resolve().then(() => {
        if (!this.isDestroying) {
          this.openButtonTarget = element;
        }
      }),
    );
    return () => {
      if (this.openButtonTarget === element) {
        this.openButtonTarget = null;
      }
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
    const dialog = this.dialogElement;
    if (!dialog) {
      return this;
    }

    const deferred = defer<this>();
    this.openDeferred = deferred;
    const runId = ++this.transitionId;

    if (this.state === 'closing') {
      // Interrupt the in-flight close: cancelling its animations wakes its
      // continuation, which sees the stale transitionId and settles itself
      // without closing the dialog.
      this.cancelAnimations(dialog);
    }
    if (!dialog.open) {
      dialog.showModal();
    }
    this.acquireLock();
    this.state = 'opening';

    await this.waitForTransition(dialog);

    if (this.openDeferred === deferred) {
      this.openDeferred = null;
    }
    if (this.transitionId === runId && !this.isDestroying) {
      this.state = 'opened';
      this.args.onOpen?.();
    }
    deferred.resolve(this);
    return deferred.promise;
  };

  close = async (reason?: CloseReason): Promise<this> => {
    if (this.state === 'closed') {
      console.warn(
        'ember-remodal: You called "close" on a modal that has not yet been opened. This is not a big deal, but I thought you should know. The returned promise will immediately resolve.',
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
    this.state = 'closing';

    await this.waitForTransition(dialog);

    if (this.closeDeferred === deferred) {
      this.closeDeferred = null;
    }
    if (this.transitionId === runId && !this.isDestroying) {
      this.state = 'closed';
      dialog.close();
      this.releaseLock();
      this.args.onClose?.(reason);
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

  handleOpenClick = (event: Event): void => {
    // Open triggers may render as `<a href="#">`; never navigate.
    event.preventDefault();
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
    // The dialog closed without going through close() — e.g. a
    // `<form method="dialog">` submission inside user content, or a browser
    // force-close that ignored our cancel preventDefault. Re-sync state.
    this.transitionId += 1;
    this.state = 'closed';
    this.releaseLock();
    this.settlePendingTransitions();
    this.args.onClose?.();
  };

  // --- internals ---

  private acquireLock(): void {
    if (!this.holdsScrollLock) {
      this.holdsScrollLock = true;
      acquireScrollLock();
    }
  }

  private releaseLock(): void {
    if (this.holdsScrollLock) {
      this.holdsScrollLock = false;
      releaseScrollLock();
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
    // Only wait on the wrapper/backdrop and card animations; user content may
    // legitimately contain infinite animations (e.g. spinners) whose
    // `finished` promise never settles.
    const card = dialog.querySelector('.remodal');
    return dialog.getAnimations({ subtree: true }).filter((animation) => {
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

  private async waitForTransition(dialog: HTMLDialogElement): Promise<void> {
    await waitForPromise(this.animationsSettled(dialog));
  }

  private async animationsSettled(dialog: HTMLDialogElement): Promise<void> {
    // Two frames so the state-class change has applied and CSS animations
    // have actually started before we collect them.
    await nextFrame();
    await nextFrame();
    const animations = this.ownAnimations(dialog);
    if (animations.length > 0) {
      // allSettled: cancelled animations reject their `finished` promise.
      await Promise.allSettled(animations.map((a) => a.finished));
    }
  }

  <template>
    <span
      class="remodal-component"
      data-test-id={{this.dataTestId}}
      ...attributes
    >
      {{#if this.linkButton}}
        <a
          href="#"
          class="ember-remodal outer link text
            {{this.buttonClasses}}
            {{this.outerButtonClasses}}"
          data-test-id="linkButton"
          {{on "click" this.handleOpenClick}}
        >{{this.linkButton}}</a>
      {{else if this.openLink}}
        <a
          href="#"
          class="ember-remodal outer link text
            {{this.buttonClasses}}
            {{this.outerButtonClasses}}
            {{this.openLinkClasses}}"
          data-test-id="openLink"
          {{on "click" this.handleOpenClick}}
        >{{this.openLink}}</a>
      {{else if this.openButton}}
        <button
          type="button"
          class="ember-remodal outer open button
            {{this.buttonClasses}}
            {{this.outerButtonClasses}}
            {{this.openButtonClasses}}"
          data-test-id="openButton"
          {{on "click" this.handleOpenClick}}
        >{{this.openButton}}</button>
      {{/if}}

      <span
        class="ember-remodal-open-button-target"
        {{this.captureOpenButtonTarget}}
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
          {{if this.disableAnimation 'disable-animation'}}"
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
            {{this.modalClasses}}"
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

          {{#if this.title}}
            <h2
              class="ember-remodal inner title text"
              data-test-id="title"
            >{{this.title}}</h2>
          {{/if}}

          {{#if this.text}}
            <p
              class="ember-remodal inner paragraph text"
              data-test-id="text"
            >{{this.text}}</p>
          {{/if}}

          {{#if (has-block)}}
            <div
              class="ember-remodal inner yielded content"
              data-test-id="yielded"
            >
              {{yield
                (hash
                  open=(component
                    ErButton destination=this.openButtonTarget onClick=this.open
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

          {{#if this.cancelButton}}
            <button
              type="button"
              class="remodal-cancel ember-remodal inner cancel button
                {{this.buttonClasses}}
                {{this.innerButtonClasses}}
                {{this.cancelButtonClasses}}"
              data-test-id="cancelButton"
              {{on "click" this.cancelAction}}
            >{{this.cancelButton}}</button>
          {{/if}}

          {{#if this.confirmButton}}
            <button
              type="button"
              class="remodal-confirm ember-remodal inner confirm button
                {{this.buttonClasses}}
                {{this.innerButtonClasses}}
                {{this.confirmButtonClasses}}"
              data-test-id="confirmButton"
              {{on "click" this.confirmAction}}
            >{{this.confirmButton}}</button>
          {{/if}}
        </div>
      </dialog>
    </span>
  </template>
}
