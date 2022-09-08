declare interface Window {
    dodona: any;
    bootstrap: typeof bootstrap;
    MathJax: MathJaxObject;
}

declare class MathJaxObject {
    typeset() :void;
}

declare module I18n {
    export function t(key: string, options?: {}): string;
    export function formatNumber(number: number, options?: Record<string, unknown>): string;

    export function locale(locale?: string): string;
}

declare var dodona;
