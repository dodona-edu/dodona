import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { Option } from "components/datalist_input";
import { ready } from "utilities";
import "components/datalist_input";
import { DodonaElement } from "components/meta/dodona_element";
import { i18n } from "i18n/i18n";

/**
 * @element d-sign-in-search-bar
 *
 * @prop {{name: string, provider: string}[]} Institutions
 * @prop {Record<string, {name: string, link: string}>} Providers
 */
@customElement("d-sign-in-search-bar")
export class SignInSearchBar extends DodonaElement {
    @property({ type: Array })
    institutions: {name: string, provider: string}[];
    @property({ type: Object })
    providers: Record<string, {name: string, link: string}>;

    @property({ state: true })
    selected_provider: string;
    @property({ state: true })
    filter: string;

    get link(): string {
        return this.providers[this.selected_provider]?.link || "";
    }

    get options(): Option[] {
        return this.institutions.map(i => ({ label: i.name, value: i.provider, extra: this.providers[i.provider].name }));
    }

    constructor() {
        super();
        // Reload when i18n is available
        ready.then(() => this.requestUpdate());

        const localStorageInstitution = localStorage.getItem("institution");
        if (localStorageInstitution !== null) {
            const institution = JSON.parse(localStorageInstitution);
            this.filter = institution.name;
        }
    }

    handleInput(e: CustomEvent): void {
        this.selected_provider = e.detail.value;
        this.filter = e.detail.label;
        if (e.detail.value) {
            localStorage.setItem("institution", JSON.stringify({ name: e.detail.label }));
        } else {
            localStorage.removeItem("institution");
        }
    }

    render(): TemplateResult {
        return html`
            <div class="input-group input-group-lg autocomplete">
                <d-datalist-input
                    filter="${this.filter}"
                    .options=${this.options}
                    @input=${e => this.handleInput(e)}
                    placeholder="${i18n.t("js.sign_in_search_bar.institution_search")}"
                ></d-datalist-input>
                <a class="btn btn-filled btn-lg login-button ${this.selected_provider == "" ? "disabled": ""}"
                   href=${this.link}>
                    ${i18n.t("js.sign_in_search_bar.log_in")}
                </a>
            </div>

        `;
    }
}
