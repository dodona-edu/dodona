import mermaid from "mermaid";
import { Theme, themeState } from "state/Theme";

const THEME_MAP: Record<Theme, string> = {
    dark: "dark",
    light: "neutral",
};


export function initMermaid(): void {
    mermaid.initialize({
        theme: THEME_MAP[themeState.theme],
    });
}
