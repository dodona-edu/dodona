import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { Option } from "components/datalist_input";
import { ready } from "util.js";
import "components/datalist_input";

/**
 * @element d-labels-search-bar
 *
 * @prop {{id: number, name: string}[]} Labels
 */
@customElement("d-labels-search-bar")
export class LabelsSearchBar extends ShadowlessLitElement {
    @property({ type: Array })
    labels: {id: number, name: string}[];

    @property({ state: true })
    selected_label: string;
    @property({ state: true })
    filter: string;

    get options(): Option[] {
        return this.labels.map(i => ({ label: i.id.toString(), value: i.name }));
    }

    constructor() {
        super();
        // Reload when I18n is available
        ready.then(() => this.requestUpdate());
        console.log(this.labels);

        const localStorageLabel = localStorage.getItem("label");
        if (localStorageLabel !== null) {
            const label = JSON.parse(localStorageLabel);
            this.filter = label.name;
        }
    }

    handleInput(e: CustomEvent): void {
        this.selected_label = e.detail.value;
        this.filter = e.detail.label;
        if (e.detail.value) {
            localStorage.setItem("label", JSON.stringify({ name: e.detail.label }));
        } else {
            localStorage.removeItem("label");
        }
    }

    // TODO: see placeholder
    render(): TemplateResult {
        return html`
            <div class="input-group input-group-lg autocomplete">
                <d-datalist-input
                    filter="${this.filter}"
                    .options=${this.options}
                    @input=${e => this.handleInput(e)}
                    placeholder="TODO: I18n"
                ></d-datalist-input>
            </div>

        `;
    }
}
