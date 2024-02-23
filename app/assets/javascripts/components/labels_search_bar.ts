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
 * @prop {string[]} Labels - the labels of a user in a certain course
 * @prop {string} Name - the name of the input field (used in form submit)
 */
@customElement("d-labels")
export class LabelTokens extends DodonaElement {
    @property({ type: Array })
    labels: string[];
    @property({ type: String })
    name: string;

    processClick(e: Event, label: string): void {
        this.labels.splice(this.labels.indexOf(label), 1);
        this.requestUpdate();
    }

    render(): TemplateResult {
        if (!this.labels) {
            return html``;
        }

        return html`
            ${ this.labels.map( label => html`
                    <span class="labels">
                        <span class="token accent-orange">${label}
                            <a href="#" class="close" tabindex="-1"  @click=${e => this.processClick(e, label)}>×</a>
                        </span>
                    </span>
            `)}
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
 * @prop {{id: number, name: string}[]} Labels - all the labels already used in a course
 * @prop {string[]} SelectedLabels - the labels that have been added to the user
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
        return this.labels.map(i => ({ label: i.name, value: i.id.toString() }));
    }

    addLabel(): void {
        const selectedLabel = this.selected_label.trim();
        if (selectedLabel.length > 0) {
            const newSelectedLabels = this.selected_labels.slice();
            if (!this.selected_labels.includes(selectedLabel)) {
                newSelectedLabels.push(selectedLabel);
                this.selected_labels = newSelectedLabels;
            }
            this.filter = "";
        }
    }

    handleInput(e: CustomEvent): void {
        this.selected_label = e.detail.label;
        this.filter = e.detail.label;
        if (e.detail.value) {
            this.addLabel();
        }
    }

    render(): TemplateResult {
        return html`
            <div>
                <d-labels
                    .labels=${this.selected_labels}
                    .name=${this.name}
                ></d-labels>
                <div class="labels-searchbar-group input-group autocomplete">
                    <d-datalist-input
                        .filter="${this.filter}"
                        .options=${this.options}
                        @input=${e => this.handleInput(e)}
                        placeholder="${i18n.t("js.labels_search_bar.placeholder")}"
                    ></d-datalist-input>
                    <a type="button" class="btn btn-filled add-button" @click="${this.addLabel}">${i18n.t("js.labels_search_bar.add")}</a>
                </div>
                <span class="help-block">${i18n.t("js.labels_search_bar.edit_explanation")}</span>
            </div>
        `;
    }
}
