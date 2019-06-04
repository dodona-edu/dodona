declare interface Window {
    requestAnimFrame: (fun: Function) => void;
    mozRequestAnimationFrame: (fun: Function) => void;
    dodona: any;
}

declare module I18n {
    export function t(key: string): string;

    export var locale: string;
}

declare var dodona;

declare function requestAnimFrame(fun: Function): void;
