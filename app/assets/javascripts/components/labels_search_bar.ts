import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { Option } from "components/datalist_input";
import "components/datalist_input";
import { i18n } from "i18n/i18n";
import { DodonaElement } from "components/meta/dodona_element";
/**
 * This component represents a list of the selected labels
 *
 * @element d-course-labels
 * @prop {string[]} labels - the labels of a user in a certain course
 * @prop {string} name - the name of the input field (used in form submit)
 */
@customElement("d-labels")
export class LabelTokens extends DodonaElement {
    @property({ type: Array })
    labels: string[];
    @property({ type: String })
    name: string;

    removeLabel(label: string): void {
        this.dispatchEvent(new CustomEvent("remove-label", {
            detail: {
                value: label,
            },
        }));
    }

    render(): TemplateResult {
        if (!this.labels) {
            return html``;
        }

        return html`
            ${ this.labels.length > 0 ? html`
                <div class="labels">
                    ${ this.labels.map( label => html`
                        <span class="token accent-orange">${label}
                            <a href="#" class="close" tabindex="-1"  @click=${() => this.removeLabel(label)}>×</a>
                        </span>
                    `)}
                </div>
            ` : html`` }
            <input type="hidden" name="${this.name}" .value="${this.labels.join(",")}">
        `;
    }
}

/**
 * This component represents a search bar for labels, also showing a list of already selected labels.
 * It allows for searching existing labels, or creating new ones, and adding them to the user of a certain course
 *
 * @element d-labels-search-bar
 *
 * @prop {{id: number, name: string}[]} labels - all the labels already used in a course
 * @prop {string[]} selected_labels - the labels that have been added to the user
 * @prop {string} Name - the name of the input field (used in form submit)
 */
@customElement("d-labels-search-bar")
export class LabelsSearchBar extends DodonaElement {
    @property({ type: Array })
    labels: {id: number, name: string}[];
    @property({ type: Array })
    selected_labels: string[];
    @property({ type: String })
    name: string;

    @property({ state: true })
    selected_label: string;
    @property({ state: true })
    filter: string;

    get options(): Option[] {
        return this.labels
            .filter(i => !this.selected_labels.includes(i.name))
            .map(i => ({ label: i.name, value: i.id.toString() }));
    }

    addLabel(): void {
        const selectedLabel = this.selected_label.trim();
        if (selectedLabel.length > 0 && !this.selected_labels.includes(selectedLabel)) {
            this.selected_labels = [...this.selected_labels, selectedLabel];
            this.filter = "";
        }
    }

    handleInput(e: CustomEvent): void {
        this.selected_label = e.detail.label;
        this.filter = e.detail.label;
    }

    handleKeyDown(e: KeyboardEvent): void {
        if (e.key === "Enter" || e.key === "Tab") {
            this.addLabel();
        }
    }

    removeLabel(label: string): void {
        this.selected_labels = this.selected_labels.filter(i => i !== label);
    }

    render(): TemplateResult {
        return html`
            <div>
                <d-labels
                    .labels=${this.selected_labels}
                    .name=${this.name}
                    @remove-label=${(e: CustomEvent) => this.removeLabel(e.detail.value)}
                ></d-labels>
                <div class="labels-searchbar-group input-group autocomplete">
                    <d-datalist-input
                        .filter="${this.filter}"
                        .options=${this.options}
                        @input=${e => this.handleInput(e)}
                        @keydown=${e => this.handleKeyDown(e)}
                        placeholder="${i18n.t("js.labels_search_bar.placeholder")}"
                    ></d-datalist-input>
                    <a type="button" class="btn btn-filled add-button" @click="${this.addLabel}">${i18n.t("js.labels_search_bar.add")}</a>
                </div>
                <span class="help-block">${i18n.t("js.labels_search_bar.edit_explanation")}</span>
            </div>
        `;
    }
}
