declare interface Window {
    dodona: any;
}

declare module I18n {
    export function t(key: string): string;

    export var locale: string;
}

declare var dodona;