declare interface Window {
    dodona: any;
    bootstrap: typeof bootstrap;
    MathJax: MathJaxObject;
}

declare class MathJaxObject {
    typeset?(args?: string[]) :void;

    tex: {
        inlineMath: string[][];
        displayMath: string[][];
        autoload: {
            color: string[];
            colorV2: string[];
        };
        packages: {
            "[+]": string[];
        };
    }
    options: {
        ignoreHtmlClass: string,
        processHtmlClass: string
    }
    loader: {
        load: string[]
    }
}

declare module I18n {
    export function l(key: string, data: any): string;
    export function t(key: string, options?: {}): string;
    export function numberToDelimited(number: number, options?: {}): string;

    export var locale: string;
}

// add parentIFrame from iFrame Resizer to the window to make typescript happy
declare interface Window {
    parentIFrame: any;
}

// ace editor is globally available
declare var ace;

declare var dodona;
