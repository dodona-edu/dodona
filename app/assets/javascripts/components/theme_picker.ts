import { html, TemplateResult } from "lit";
import { customElement } from "lit/decorators.js";
import { THEME_OPTIONS, ThemeOption, themeState } from "state/Theme";
import { userState } from "state/Users";
import { DodonaElement } from "components/meta/dodona_element";
import { i18n } from "i18n/i18n";

/**
 * @element d-theme-picker
 *
 * this is a simple menu element
 * It shows the current theme and allows the user to select a new theme
 */
@customElement("d-theme-picker")
export class ThemePicker extends DodonaElement {
    static THEME_ICON_MAP: Record<ThemeOption, string> = {
        "light": "white-balance-sunny",
        "dark": "weather-night",
        "system": "theme-light-dark"
    };

    selectTheme(theme: ThemeOption): void {
        themeState.selectedTheme = theme;
        userState.update({ theme });
    }

    protected render(): TemplateResult {
        return html`
            <li >
                <a href="#" class="dropdown-item">
                    <i class="mdi mdi-theme-light-dark"></i>
                    ${i18n.t(`js.theme.theme`)}
                    <i class="mdi mdi-menu-right float-end"></i>
                </a>
                <ul class="dropdown-menu dropdown-submenu dropdown-submenu-left">
                    ${ THEME_OPTIONS.map(theme => html`
                        <li><a class="dropdown-item ${themeState.selectedTheme == theme ? "active" : "" }" @click=${() => this.selectTheme(theme)}>
                            <i class="mdi mdi-${ThemePicker.THEME_ICON_MAP[theme]}"></i>
                            ${i18n.t(`js.theme.${theme}`)}
                        </a></li>
                    `)}
                </ul>
            </li>`;
    }
}
