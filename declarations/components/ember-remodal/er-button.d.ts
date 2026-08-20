import Component from '@glimmer/component';
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
export declare function hasFocusableDescendant(root: Element | null): boolean;
export default class ErButton extends Component<ErButtonSignature> {
    handleClick: (event: Event) => void;
    auditFocusableContent: import("ember-modifier").FunctionBasedModifier<{
        Args: {
            Positional: unknown[];
            Named: import("ember-modifier/-private/signature").EmptyObject;
        };
        Element: Element;
    }>;
}
//# sourceMappingURL=er-button.d.ts.map