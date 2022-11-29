import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { FilterCollectionElement, Label } from "components/filter_collection_element";
import { watchMixin } from "components/watch_mixin";

/**
 * This component inherits from FilterCollectionElement.
 * It represent a lists tabs, where each tab shows a filtered set of the search results
 *
 * @element d-filter-tabs
 *
 * @prop {[Label]} labels - all labels that could potentially be selected
 */
@customElement("d-filter-tabs")
export class FilterTabs extends watchMixin(FilterCollectionElement) {
    @property()
    multi = false;
    @property()
    param = "tab";
    @property()
    paramVal = (label: Label): string => label.id.toString();
    @property({ type: String, attribute: "default-tab" })
    defaultTab: string;

    processClick(e: Event, label: Label): void {
        if (!this.isSelected(label)) {
            this.select(label);
        }
        e.preventDefault();
    }

    watch = {
        labels: () => {
            if (this.getSelectedLabels().length == 0) {
                this.select(this.labels.find(l => l.id == this.defaultTab));
            }
        }
    };

    render(): TemplateResult {
        return html`
            <div class="card-tab">
                <ul class="nav nav-tabs" role="tablist">
                    ${ this.labels.map( label => html`
                        <li role="presentation">
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
