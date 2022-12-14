import { customElement, property } from "lit/decorators.js";
import { FilterCollectionElement, Label } from "components/filter_collection_element";
import { html, TemplateResult } from "lit";
import { watchMixin } from "components/watch_mixin";

/**
 * This component inherits from FilterCollectionElement.
 * It represents a dropdown which allows to select one label, with the currently selected label shown as a button
 *
 * @element d-standalone-dropdown-filter
 *
 * @prop {string} param - the searchQuery param to be used for this filter
 * @prop {string} default - the default value for the filter
 * @prop {[Label]} labels - all labels that could potentially be selected
 */
@customElement("d-standalone-dropdown-filter")
export class StandaloneDropdownFilter extends watchMixin(FilterCollectionElement) {
    @property()
    multi = false;
    @property()
    paramVal = (label: Label): string => label.id.toString();
    @property({ type: String })
    default;

    watch = {
        default: () => {
            if (this.getSelectedLabels().length == 0) {
                this.select(this.labels.find(label => label.id == this.default));
            }
        }
    };

    render(): TemplateResult {
        if (this.labels.length === 0) {
            return html``;
        }

        return html`
            <div class="dropdown">
                <a class="btn btn-text dropdown-toggle" href="#" role="button" id="dropdownMenuLink" data-bs-toggle="dropdown" aria-expanded="false">
                    ${this.getSelectedLabels()[0].name}
                    <i class="mdi mdi-chevron-down mdi-18 right-icon"></i>
                </a>

                <ul class="dropdown-menu" aria-labelledby="dropdownMenuLink">
                    ${this.labels.map(s => html`
                            <li><a class="dropdown-item ${this.isSelected(s) ? "active" : ""}" @click="${() => this.select(s)}">${s.name}</a> </li>
                    `)}
                </ul>
            </div>
        `;
    }
}
