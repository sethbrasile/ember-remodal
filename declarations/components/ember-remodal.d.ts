import Component from '@glimmer/component';
import type Owner from '@ember/owner';
import type { WithBoundArgs } from '@glint/template';
import type RemodalService from '../services/remodal.js';
import ErButton from './ember-remodal/er-button.js';
import '../styles/ember-remodal.css';
export type ModalState = 'closed' | 'opening' | 'opened' | 'closing';
export type CloseReason = 'confirmation' | 'cancellation';
export interface EmberRemodalOptions {
    title?: string;
    text?: string;
    ariaLabel?: string;
    ariaLabelledBy?: string;
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
    hasCustomKeyboardExit?: boolean;
    closeOnCancel?: boolean;
    closeOnConfirm?: boolean;
    closeOnOutsideClick?: boolean;
    disableForeground?: boolean;
    disableNativeClose?: boolean;
    disableAnimation?: boolean;
    legacyClassNames?: boolean;
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
/**
 * Not part of the supported API: the seam `ember-remodal/test-support` uses.
 * Everything below mutates or reads module-level state that lives outside any
 * component instance (and outside `#ember-testing`), which is precisely why a
 * test suite needs a way to read and reset it.
 */
export declare function setAnimationDisabledForTesting(disabled: boolean): void;
export interface ScrollLockState {
    /** How many modal instances currently believe they hold the lock. */
    holders: number;
    /** Whether the document element is actually carrying the lock class. */
    locked: boolean;
    bodyPaddingRight: string;
}
export declare function scrollLockStateForTesting(): ScrollLockState;
export declare function resetScrollLockForTesting(): void;
export default class EmberRemodal extends Component<EmberRemodalSignature> {
    remodal: RemodalService;
    state: ModalState;
    serviceOverrides: EmberRemodalOptions | null;
    dialogElement: HTMLDialogElement | null;
    openButtonTarget: HTMLSpanElement | null;
    private openDeferred;
    private closeDeferred;
    private transitionId;
    private registeredName;
    private hasOpened;
    private pendingCloseReason;
    private pressedOnBackdrop;
    private readonly testingAnimationDisabled;
    constructor(owner: Owner, args: EmberRemodalArgs);
    willDestroy(): void;
    private resolveTestingAnimationDisabled;
    opt: <K extends keyof EmberRemodalOptions>(key: K) => EmberRemodalOptions[K];
    get name(): string;
    get forService(): boolean;
    get modifier(): string;
    get titleId(): string;
    get title(): string | undefined;
    get ariaLabel(): string | undefined;
    get ariaLabelledBy(): string | undefined;
    get labelledById(): string | undefined;
    get labelAttribute(): string | undefined;
    get hasAccessibleName(): boolean;
    private get labelledByResolves();
    get closeButtonLabel(): string;
    get text(): string | undefined;
    get linkButton(): string | undefined;
    get openLink(): string | undefined;
    get openButton(): string | undefined;
    get cancelButton(): string | undefined;
    get confirmButton(): string | undefined;
    get closeOnEscape(): boolean;
    get closeOnCancel(): boolean;
    get closeOnConfirm(): boolean;
    get closeOnOutsideClick(): boolean;
    get disableForeground(): boolean;
    get disableNativeClose(): boolean;
    get hasCustomKeyboardExit(): boolean;
    get legacyClassNames(): boolean;
    get disableAnimation(): boolean;
    get animationState(): string;
    get stateClass(): string;
    get isOpen(): boolean;
    registerDialog: import("ember-modifier").FunctionBasedModifier<{
        Args: {
            Positional: unknown[];
            Named: import("ember-modifier/-private/signature").EmptyObject;
        };
        Element: HTMLDialogElement;
    }>;
    attachOpenButtonTarget: import("ember-modifier").FunctionBasedModifier<{
        Args: {
            Positional: unknown[];
            Named: import("ember-modifier/-private/signature").EmptyObject;
        };
        Element: Element;
    }>;
    open: () => Promise<this>;
    close: (reason?: CloseReason) => Promise<this>;
    confirm: () => Promise<this>;
    cancel: () => Promise<this>;
    openAction: () => void;
    closeAction: () => void;
    confirmAction: () => void;
    cancelAction: () => void;
    handleOpenClick: (event?: Event | undefined) => void;
    handleWrapperMouseDown: (event: Event) => void;
    handleWrapperClick: (event: Event) => void;
    handleNativeCancel: (event: Event) => void;
    handleDialogClose: () => void;
    private domHandler;
    private observeCallback;
    private get exits();
    private hasKeyboardExit;
    private auditAccessibility;
    private reportError;
    private setState;
    private finalizeClose;
    private waitForDialogElement;
    private settlePendingTransitions;
    private ownAnimations;
    private cancelAnimations;
    private animationsSettled;
    private ownAnimationsSettled;
}
//# sourceMappingURL=ember-remodal.d.ts.map