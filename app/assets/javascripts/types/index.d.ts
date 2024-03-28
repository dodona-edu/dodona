declare interface Window {
    dodona: any;
    bootstrap: typeof bootstrap;
    MathJax: MathJaxObject;
}

declare class MathJaxObject {
    typeset?(args?: string[] | Node[]) :void;

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

// add parentIFrame and iFrameResize from iFrame Resizer to the window to make typescript happy
declare interface Window {
    parentIFrame: any;
    iFrameResize: any;
}

declare var dodona;
