import { stateProperty } from "state/state_system/StateProperty";
import { State } from "state/state_system/State";
import { getURLParameter, updateURLParameter } from "util.js";

export type ThemeOption = "light" | "dark" | "auto";
export type Theme = "light" | "dark";
export const THEME_OPTIONS: ThemeOption[] = ["light", "dark", "auto"];

class ThemeState extends State {
    @stateProperty _selectedTheme: ThemeOption = "auto";
    @stateProperty _theme: Theme = "light";

    get selectedTheme(): ThemeOption {
        return this._selectedTheme;
    }

    set selectedTheme(theme: ThemeOption) {
        this._selectedTheme = theme;
        this.theme = theme === "auto" ? this.preferredTheme : theme;
    }

    get preferredTheme(): Theme {
        return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
    }

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
    }

    constructor() {
        super();

        window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => {
            if (this.selectedTheme === "auto") {
                this.theme = this.preferredTheme;
            }
        });
    }
}

export const themeState = new ThemeState();