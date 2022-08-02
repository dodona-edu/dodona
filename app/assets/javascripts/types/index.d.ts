declare interface Window {
    dodona: any;
    bootstrap: { Alert: any, Button: any, Collapse: any, Dropdown: any, Modal: any, Popover: any, Tab: any, Tooltip: any };
    MathJax: MathJaxObject;
}

declare class MathJaxObject {
    typeset() :void;
}

declare module I18n {
    export function l(key: string, data: any): string;
    export function t(key: string, options?: {}): string;
    export function numberToDelimited(number: number, options?: {}): string;

    export var locale: string;
}

declare var dodona;

declare var bootstrap: { Alert: any, Button: any, Collapse: any, Dropdown: any, Modal: any, Popover: any, Tab: any, Tooltip: any };
