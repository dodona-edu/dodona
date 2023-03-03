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
    export function t(key: string, options?: {}): string;
    export function t_a(key: string): string[];
    export function formatNumber(number: number, options?: Record<string, unknown>): string;
    export function formatDate(date: string | number | Date | import("dayjs").Dayjs, format: string): string;

    export var locale: string;
}

// add parentIFrame from iFrame Resizer to the window to make typescript happy
declare interface Window {
    parentIFrame: any;
}

declare var dodona;

declare module "util.js" {
    export function createDelayer(): (func: () => void, delay: number) => void;
    export function delay(func: () => void, delay: number): void;
    export function fetch(url: string, options?: RequestInit): Promise<Response>;
    export function updateURLParameter(uri: string, key: string, value: string): string;
    export function updateArrayURLParameter(uri: string, key: string, value: string[]): string;
    export function getURLParameter(uri: string, key: string): string | null;
    export function getArrayURLParameter(uri: string, key: string): string[] | null;
    export function checkTimeZone(): void;
    export function checkIframe(): void;
    export function initCSRF(): void;
    export function tooltip(selector: string, placement?: string, trigger?: string): void;
    export function initTooltips(root: HTMLElement): void;
    export function makeInvisible(selector: string): void;
    export function makeVisible(selector: string): void;
    export function setDocumentTitle(title: string): void;
    export function initDatePicker(selector: string, options?: Record<string, unknown>): void;
    export const ready: Promise<void>;
    export function htmlEncode(value: string): string;
    export function getParentByClassName(element: HTMLElement, className: string): HTMLElement | null;

}
