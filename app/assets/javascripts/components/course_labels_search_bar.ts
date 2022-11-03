import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { Option } from "components/datalist_input";
import { ready } from "util.js";
import "components/datalist_input";
/**
 * This component represents a list of d-label-token
 *
 * @element d-course-label-tokens
 *
 * @prop {string[]} Labels
 */
@customElement("d-course-label-tokens")
export class CourseLabelTokens extends ShadowlessLitElement {
    @property({ type: Array })
    labels: string[];

    processClick(e: Event, label: string): void {
        this.labels.splice(this.labels.indexOf(label), 1);
        this.requestUpdate();
    }

    render(): TemplateResult {
        if (!this.labels) {
            return html``;
        }

        // TODO: color hardcoded?
        // TODO: hidden input in datalist-input?
        return html`
            ${ this.labels.map( label => html`
                    <span class="labels">
                        <span class="token accent-orange">${label}
                            <a href="#" class="close" tabindex="-1"  @click=${e => this.processClick(e, label)}>×</a>
                        </span>
                        <input type="hidden" name="course_membership[course_labels]" .value=${this.labels.join(",")}>
                    </span>
            `)}
        `;
    }
}

/**
 * @element d-course-labels-search-bar
 *
 * @prop {{id: number, name: string}[]} Labels
 * @prop {string[]} SelectedLabels
 */
@customElement("d-course-labels-search-bar")
export class CourseLabelsSearchBar extends ShadowlessLitElement {
    @property({ type: Array })
    labels: {id: number, name: string}[];

    @property({ type: Array })
    selected_labels: string[];

    @property({ state: true })
    selected_label: string;

    @property({ state: true })
    filter: string;

    get options(): Option[] {
        return this.labels.map(i => ({ label: i.name, value: i.id.toString() }));
    }

    constructor() {
        super();
        // Reload when I18n is available
        // TODO: this gives a warning
        ready.then(() => this.requestUpdate());
    }

    handleClick(e: Event): void {
        e.preventDefault();
        const newSelectedLabels = this.selected_labels.slice();
        if (!this.selected_labels.includes(this.selected_label)) {
            newSelectedLabels.push(this.selected_label);
            this.selected_labels = newSelectedLabels;
        }
        this.filter = "";
        this.requestUpdate();
    }

    handleInput(e: CustomEvent): void {
        this.selected_label = e.detail.label;
        this.filter = e.detail.label;
    }

    // TODO: handling of enter?
    // TODO: "courselabel"
    // TODO: translation not found error/bug
    // TODO: clear text
    // TODO: style
    render(): TemplateResult {
        return html`
            <div>
                <d-course-label-tokens 
                    .labels=${this.selected_labels}
                ></d-course-label-tokens>
                <div class="input-group input-group-lg autocomplete">
                    <d-datalist-input
                        .filter=${this.filter}
                        .options=${this.options}
                        @input=${e => this.handleInput(e)}
                        placeholder="${I18n.t("js.course_labels_search_bar.course_label_search")}"
                    ></d-datalist-input>
                    <button type="button" class="btn btn-text" @click="${this.handleClick}">${I18n.t("js.course_labels_search_bar.add_course_label")}</button>
                </div>
            </div>
        `;
    }
}
