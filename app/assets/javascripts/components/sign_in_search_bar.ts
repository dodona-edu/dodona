import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { Option } from "components/datalist_input";
import { ready } from "util.js";
import "components/datalist_input";

/**
 * @element d-sign-in-search-bar
 *
 * @prop {{name: string, provider: string}[]} Institutions
 * @prop {Record<string, {name: string, link: string}>} Providers
 */
@customElement("d-sign-in-search-bar")
export class SignInSearchBar extends ShadowlessLitElement {
    @property({ type: Array })
    institutions: {name: string, provider: string}[];
    @property({ type: Object })
    providers: Record<string, {name: string, link: string}>;

    @property({ state: true })
    selected_provider: string;

    get link(): string {
        return this.selected_provider !== undefined ? this.providers[this.selected_provider].link : "";
    }

    get options(): Option[] {
        return this.institutions.map(i => ({ label: i.name, value: i.provider, extra: this.providers[i.provider].name }));
    }

    get storedInstitution(): string {
        const localStorageInstitution = localStorage.getItem("institution");
        if (localStorageInstitution !== null) {
            const institution = JSON.parse(localStorageInstitution);
            return institution.name;
        } else {
            return undefined;
        }
    }

    constructor() {
        super();
        // Reload when I18n is available
        ready.then(() => this.requestUpdate());
    }

    handleInput(e: CustomEvent): void {
        this.selected_provider = e.detail.value;
        if (e.detail.value) {
            localStorage.setItem("institution", JSON.stringify({ name: e.detail.label, type: e.detail.value }));
        } else {
            localStorage.removeItem("institution");
        }
    }

    render(): TemplateResult {
        return html`
            <div class="input-group input-group-lg autocomplete">
                    <d-datalist-input
                        filter="${this.storedInstitution}"
                        .options=${this.options}
                        @input=${e => this.handleInput(e)}
                        placeholder="${I18n.t("js.sign_in_search_bar.institution_search")}"
                    ></d-datalist-input>
                <a class="btn btn-primary btn-lg login-button"
                   href=${this.link}
                   disabled=${this.selected_provider !== undefined}>
                    ${I18n.t("js.sign_in_search_bar.log_in")}
                </a>
            </div>

        `;
    }
}
