import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import {
    Label,
    FilterElement,
    AccentColor
} from "components/search/filter_element";
import { i18n } from "i18n/i18n";
import { FilterCollection } from "components/search/filter_collection";

/**
 * This component inherits from FilterCollectionElement.
 * It represents a dropdown which allows to select one or multiple labels
 *
 * @element d-dropdown-filter
 *
 * @prop {AccentColor} color - the color associated with the filter
 * @prop {string} type - The type of the filter collection, used to determine the dropdown button text
 * @prop {string} param - the searchQuery param to be used for this filter
 * @prop {boolean} multi - whether one or more labels can be selected at the same time
 * @prop {[Label]} labels - all labels that could potentially be selected
 */
@customElement("d-dropdown-filter")
export class DropdownFilter extends FilterElement {
    @property({ type: String })
    color: AccentColor;

    @property({ state: true })
    filter = "";

    get showFilter(): boolean {
        return this.labels.length > 15;
    }

    get filteredLabels(): Label[] {
        return this.showFilter ? this.labels.filter(s => s.name.toLowerCase().includes(this.filter.toLowerCase())) : this.labels;
    }

    get disabled(): boolean {
        return this.labels.length === 0 || (!this.multi && this.labels.length === 1);
    }

    render(): TemplateResult {
        return html`
            <div class="dropdown dropdown-filter">
                <a class="token token-bordered ${this.disabled ? "disabled" : ""}" href="#" role="button" id="dropdownMenuLink" data-bs-toggle="dropdown" aria-expanded="false">
                    ${this.getSelectedLabels().map( () => html`<i class="mdi mdi-circle mdi-12 mdi-colored-accent accent-${this.color} left-icon"></i>`)}
                    ${i18n.t(`js.search.filter.${this.param}`)}
                    <i class="mdi mdi-chevron-down mdi-18 right-icon"></i>
                </a>

                <ul class="dropdown-menu" aria-labelledby="dropdownMenuLink">
                    ${this.showFilter ? html`
                        <li><span class="dropdown-item-text ">
                            <input type="text" class="form-control " @input=${e => this.filter = e.target.value} placeholder="${i18n.t("js.dropdown.search")}">
                        </span></li>
                    ` : ""}
                    ${this.filteredLabels.sort((a, b) => b.count - a.count).map(s => html`
                            <li><span class="dropdown-item-text ">
                                <div class="form-check">
                                    <input class="form-check-input" type="${this.multi?"checkbox":"radio"}" .checked=${this.isSelected(s)} @click="${() => this.toggle(s)}" id="check-${this.param}-${s.id}">
                                    <label class="form-check-label" for="check-${this.param}-${s.id}" style="min-width: max-content">
                                        ${s.name}
                                        ${s.count ? html`<span class="badge colored-secondary rounded-pill float-end ms-1">${s.count}</span>` : ""}
                                    </label>
                                </div>
                            </span></li>
                    `)}
                </ul>
            </div>
        `;
    }
}

/**
 * This component represents a list of d-dropdown-filter
 *
 * @element d-dropdown-filters
 *
 * @prop {FilterOptions[]} filters - the list of filterOptions for which a dropdown should be displayed
 * @prop {string[]} hide - the list of filter params that should be hidden
 */
@customElement("d-dropdown-filters")
export class DropdownFilters extends FilterCollection {
    render(): TemplateResult {
        if (!this.visibleFilters) {
            return html``;
        }

        return html`
            ${this.visibleFilters.map(c => html`
                <d-dropdown-filter
                    .labels=${c.data}
                    .color=${c.color}
                    .param=${c.param}
                    .multi=${c.multi}
                >
                </d-dropdown-filter>
            `)}
        `;
    }
}
