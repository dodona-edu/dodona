declare interface Window {
    dodona: any;
    MathJax: MathJaxObject;
}

declare class MathJaxObject {
    typeset() :void;
}

console.log("-------------------------------------------------------------------------------------------------");
declare module I18n {
    export function l(key: string, data: any): string;
    export function t(key: string, options?: {}): string;
    export function toNumber(number: number, options?: {}): string;

    export var locale: string;
}

declare var dodona;
