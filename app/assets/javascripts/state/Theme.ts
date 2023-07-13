import { stateProperty } from "state/state_system/StateProperty";
import { State } from "state/state_system/State";
import { getURLParameter, updateURLParameter } from "util.js";

// The actual theme applied to the page
export type Theme = "light" | "dark";
// Options a user can select
export type ThemeOption = Theme | "system";
export const THEME_OPTIONS: ThemeOption[] = ["light", "dark", "system"];

class ThemeState extends State {
    @stateProperty _selectedTheme: ThemeOption = "system";
    @stateProperty _theme: Theme = "light";
    @stateProperty computedStyle: CSSStyleDeclaration = getComputedStyle(document.documentElement);

    // the theme option selected by the user
    get selectedTheme(): ThemeOption {
        return this._selectedTheme;
    }

    set selectedTheme(theme: ThemeOption) {
        this._selectedTheme = theme;
        this.theme = theme === "system" ? this.systemTheme : theme;
    }

    // Get the theme that the system is currently using
    private get systemTheme(): Theme {
        return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
    }

    // The theme that is currently applied to the page
    get theme(): Theme {
        return this._theme;
    }

    set theme(theme: Theme) {
        // update the page theme
        document.documentElement.setAttribute("data-bs-theme", theme);
        // update the theme of all elements that have a data-bs-theme attribute with the current theme
        document.querySelectorAll(`[data-bs-theme="${this._theme}"]`).forEach(element => {
            element.setAttribute("data-bs-theme", theme);
        });
        // update the theme of all iframes that have a theme parameter with the current theme
        Array.from(document.getElementsByTagName("iframe")).forEach(iframe => {
            if (getURLParameter("theme", iframe.src) === this._theme) {
                iframe.src = updateURLParameter(iframe.src, "theme", theme);
            }
        });
        this._theme = theme;
        this.computedStyle = getComputedStyle(document.documentElement);
    }

    getCSSVariable(name: string): string {
        return this.computedStyle.getPropertyValue(name);
    }

    constructor() {
        super();

        window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => {
            if (this.selectedTheme === "system") {
                this.theme = this.systemTheme;
            }
        });
    }
}

export const themeState = new ThemeState();
