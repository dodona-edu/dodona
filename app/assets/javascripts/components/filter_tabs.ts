import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { FilterCollectionElement, Label } from "components/filter_collection_element";
import { watchMixin } from "components/watch_mixin";

/**
 * This component inherits from FilterCollectionElement.
 * It represent a list of tabs, where each tab shows a filtered set of the search results
 *
 * @element d-filter-tabs
 *
 * @prop {{id: string, name: string, title: string}[]} labels - all labels that could potentially be selected
 */
@customElement("d-filter-tabs")
export class FilterTabs extends watchMixin(FilterCollectionElement) {
    @property()
    multi = false;
    @property()
    param = "tab";
    @property()
    paramVal = (label: Label): string => label.id.toString();
    @property({ type: Array })
    labels: {id: string, name: string, title: string}[];

    processClick(e: Event, label: Label): void {
        if (!this.isSelected(label)) {
            this.select(label);
        }
        e.preventDefault();
    }

    watch = {
        labels: () => {
            if (this.getSelectedLabels().length == 0) {
                this.select(this.labels[0]);
            }
        }
    };

    render(): TemplateResult {
        return html`
            <div class="card-tab">
                <ul class="nav nav-tabs" role="tablist">
                    ${this.labels.map(label => html`
                        <li role="presentation" data-bs-toggle="tooltip" data-bs-title="${label.title ? label.title : ""}" data-bs-trigger="hover">
                            <a href="#" @click=${e => this.processClick(e, label)} class="${this.isSelected(label) ? "active" : ""}">
                                ${label.name}
                            </a>
                        </li>
                    `)}
                </ul>
            </div>
        `;
    }
}
