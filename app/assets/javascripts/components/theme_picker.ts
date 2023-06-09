import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { html, TemplateResult } from "lit";
import { customElement } from "lit/decorators.js";
import { THEME_OPTIONS, ThemeOption, themeState } from "state/Theme";
import { fetch } from "util.js";

/**
 */
@customElement("d-theme-picker")
export class ThemePicker extends ShadowlessLitElement {
    static THEME_ICON_MAP: Record<ThemeOption, string> = {
        "light": "mdi-light-mode",
        "dark": "mdi-dark-mode",
        "auto": "mdi-tonality",
    };

    selectTheme(theme: ThemeOption): void {
        themeState.selectedTheme = theme;
        fetch("/theme", {
            method: "POST",
            body: JSON.stringify({ theme }),
            headers: { "Content-type": "application/json" },
        });
    }

    protected render(): TemplateResult {
        return html`
            <li class="dropdown">
                <a href="#" class="dropdown-toggle" data-bs-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">
                        <i class="mdi ${ThemePicker.THEME_ICON_MAP[themeState.selectedTheme]}"></i>
                    <span class="caret"></span></a>
                <ul class="dropdown-menu dropdown-menu-end">
                    ${ THEME_OPTIONS.map(theme => html`
                        <li><a class="dropdown-item" @click=${() => this.selectTheme(theme)}>
                            <i class="mdi ${ThemePicker.THEME_ICON_MAP[theme]}"></i>
                            ${I18n.t(`js.theme.${theme}`)}
                        </a></li>
                    `)}
                </ul>
            </li>`;
    }
}
