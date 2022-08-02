declare interface Window {
    dodona: any;
    bootstrap: { Alert: bootstrap.Alert, Button: bootstrap.Button, Collapse: bootstrap.Collapse, Dropdown: bootstrap.Dropdown, Modal: bootstrap.Modal, Popover: bootstrap.Popover, Tab: bootstrap.Tab, Tooltip: bootstrap.Tooltip };
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