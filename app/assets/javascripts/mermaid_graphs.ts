import { Theme, themeState } from "state/Theme";

const THEME_MAP: Record<Theme, string> = {
    dark: "dark",
    light: "neutral",
};


export async function initMermaid(): Promise<void> {
    if (!document.querySelector(".mermaid")) {
        return;
    }

    const mermaid = await import("mermaid");
    mermaid.default.initialize({
        theme: THEME_MAP[themeState.theme],
    });
}
