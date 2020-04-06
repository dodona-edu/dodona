declare interface Window {
    dodona: any;
}

declare module I18n {
    export function l(key: string, data: any): string;
    export function t(key: string, options?: {}): string;

    export var locale: string;
}

declare var dodona;
