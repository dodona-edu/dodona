import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { html, TemplateResult } from "lit";
import { customElement } from "lit/decorators.js";
import { Theme, THEME_OPTIONS, ThemeOption, themeState } from "state/Theme";
import { fetch } from "util.js";
import { userState } from "state/Users";

/**
 */
@customElement("d-theme-picker")
export class ThemePicker extends ShadowlessLitElement {
    static THEME_ICON_MAP: Record<ThemeOption, string> = {
        "light": "white-balance-sunny",
        "dark": "weather-night",
        "auto": "theme-light-dark"
    };

    selectTheme(theme: ThemeOption): void {
        themeState.selectedTheme = theme;
        userState.update({ theme });
    }

    protected render(): TemplateResult {
        return html`
            <li >
                <a href="#" class="dropdown-item">
                    <i class="mdi mdi-${ThemePicker.THEME_ICON_MAP[themeState.selectedTheme]}"></i>
                    ${I18n.t(`js.theme.${themeState.selectedTheme}`)}
                    <i class="mdi mdi-menu-right float-end"></i>
                </a>
                <ul class="dropdown-menu dropdown-submenu dropdown-submenu-left">
                    ${ THEME_OPTIONS.map(theme => html`
                        <li><a class="dropdown-item ${themeState.selectedTheme == theme ? "active" : "" }" @click=${() => this.selectTheme(theme)}>
                            <i class="mdi mdi-${ThemePicker.THEME_ICON_MAP[theme]}"></i>
                            ${I18n.t(`js.theme.${theme}`)}
                        </a></li>
                    `)}
                </ul>
            </li>`;
    }
}
