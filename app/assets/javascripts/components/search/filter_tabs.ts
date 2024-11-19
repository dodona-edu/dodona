import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { FilterElement, Label } from "components/search/filter_element";
import { watchMixin } from "components/meta/watch_mixin";

type TabInfo = {id: string, name: string, title?: string, count?: number};

/**
 * This component inherits from FilterCollectionElement.
 * It represent a list of tabs, where each tab shows a filtered set of the search results
 *
 * @element d-filter-tabs
 *
 * @prop {{id: string, name: string, title: string}[]} labels - all labels that could potentially be selected
 */
@customElement("d-filter-tabs")
export class FilterTabs extends watchMixin(FilterElement) {
    @property()
    multi = false;
    @property()
    param = "tab";
    @property({ type: Array })
    labels: TabInfo[];

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
                        <li role="presentation" data-bs-toggle="tooltip" title="${label.title ? label.title : ""}" data-bs-trigger="hover">
                            <a href="#" @click=${e => this.processClick(e, label)} class="${this.isSelected(label) ? "active" : ""}">
                                ${label.name}
                                ${label.count ? html`<span class="badge rounded-pill colored-secondary" id="${label.id}-count">${label.count}</span>` : ""}
                            </a>
                        </li>
                    `)}
                </ul>
            </div>
        `;
    }
}
