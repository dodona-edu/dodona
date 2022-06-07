import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { FilterCollection, Label, FilterCollectionElement } from "components/filter_collection_element";
import { ShadowlessLitElement } from "components/shadowless_lit_element";

/**
 * This component inherits from FilterCollectionElement.
 * It represents a dropdown which allows to select one or multiple labels
 *
 * @element d-dropdown-filter
 *
 * @prop {(s: Label) => string} color - a function that fetches the color associated with each label
 * @prop {string} type - The type of the filter collection, used to determine the dropdown button text
 * @prop {string} param - the searchQuery param to be used for this filter
 * @prop {boolean} multi - whether one or more labels can be selected at the same time
 * @prop {(l: Label) => string} paramVal - a function that extracts the value that should be used in a searchQuery for a selected label
 * @prop {[Label]} labels - all labels that could potentially be selected
 */
@customElement("d-dropdown-filter")
export class DropdownFilter extends FilterCollectionElement {
    @property()
    color: (s: Label) => string;
    @property()
    type: string;

    render(): TemplateResult {
        if (this.labels.length === 0) {
            return html``;
        }

        return html`
            <div class="dropdown dropdown-filter">
                <a class="btn btn-outline dropdown-toggle" href="#" role="button" id="dropdownMenuLink" data-bs-toggle="dropdown" aria-expanded="false">
                    ${this.getSelectedLabels().map( s => html`<i class="mdi mdi-circle mdi-12 mdi-colored-accent accent-${this.color(s)} left-icon"></i>`)}
                    ${I18n.t(`js.dropdown.${this.multi?"multi":"single"}.${this.type}`)}
                    <i class="mdi mdi-chevron-down mdi-18 right-icon"></i>
                </a>

                <ul class="dropdown-menu" aria-labelledby="dropdownMenuLink">
                    ${this.labels.map(s => html`
                            <li><span class="dropdown-item-text ">
                                <div class="form-check">
                                    <input class="form-check-input" type="${this.multi?"checkbox":"radio"}" .checked=${this.isSelected(s)} @click="${() => this.toggle(s)}" id="check-${this.param}-${s.id}">
                                    <label class="form-check-label" for="check-${this.param}-${s.id}">
                                        ${s.name}
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
 * @prop {[string, FilterCollection][]} filterCollections - the list of filterCollections for which a dropdown should be displayed
 */
@customElement("d-dropdown-filters")
export class DropdownFilters extends ShadowlessLitElement {
    @property( { type: Array })
    filterCollections: [string, FilterCollection][];

    render(): TemplateResult {
        if (!this.filterCollections) {
            return html``;
        }

        return html`
            ${this.filterCollections.map(([type, c]) => html`
                <d-dropdown-filter
                    .labels=${c.data}
                    .color=${c.color}
                    .paramVal=${c.paramVal}
                    .param=${c.param}
                    .multi=${c.multi}
                    .type=${type}
                >
                </d-dropdown-filter>
            `)}
        `;
    }
}
