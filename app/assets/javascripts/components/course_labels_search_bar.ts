import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { Option } from "components/datalist_input";
import { ready } from "utilities";
import "components/datalist_input";
/**
 * This component represents a list of the selected course labels
 *
 * @element d-course-labels
 * @prop {string[]} Labels - the labels of a user in a certain course
 */
@customElement("d-course-labels")
export class CourseLabelTokens extends ShadowlessLitElement {
    @property({ type: Array })
    accessor labels: string[];

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
            <input type="hidden" name="course_membership[course_labels]" .value="${this.labels.join(",")}">
        `;
    }
}

/**
 * This component represents a search bar for course labels, also showing a list of already selected labels.
 * It allows for searching existing labels, or creating new ones, and adding them to the user of a certain course
 *
 * @element d-course-labels-search-bar
 *
 * @prop {{id: number, name: string}[]} Labels - all the labels already used in a course
 * @prop {string[]} SelectedLabels - the labels that have been added to the user
 */
@customElement("d-course-labels-search-bar")
export class CourseLabelsSearchBar extends ShadowlessLitElement {
    @property({ type: Array })
    accessor labels: {id: number, name: string}[];

    @property({ type: Array })
    accessor selected_labels: string[];

    @property({ state: true })
    accessor selected_label: string;

    @property({ state: true })
    accessor filter: string;

    get options(): Option[] {
        return this.labels.map(i => ({ label: i.name, value: i.id.toString() }));
    }

    constructor() {
        super();
        // Reload when I18n is available
        ready.then(() => this.requestUpdate());
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
                <d-course-labels
                    .labels=${this.selected_labels}
                ></d-course-labels>
                <div class="labels-searchbar-group input-group autocomplete">
                    <d-datalist-input
                        .filter="${this.filter}"
                        .options=${this.options}
                        @input=${e => this.handleInput(e)}
                        placeholder="${I18n.t("js.course_labels_search_bar.placeholder")}"
                    ></d-datalist-input>
                    <a type="button" class="btn btn-filled add-button" @click="${this.addLabel}">${I18n.t("js.course_labels_search_bar.add")}</a>
                </div>
                <span class="help-block">${I18n.t("js.course_labels_search_bar.edit_explanation")}</span>
            </div>
        `;
    }
}
