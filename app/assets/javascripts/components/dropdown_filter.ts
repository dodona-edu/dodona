import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { FilterCollection, Label, FilterCollectionElement } from "components/filter_collection_element";
import { ShadowlessLitElement } from "components/shadowless_lit_element";

@customElement("dodona-dropdown-filter")
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
                <a class="btn btn-secondary dropdown-toggle" href="#" role="button" id="dropdownMenuLink" data-bs-toggle="dropdown" aria-expanded="false">
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

@customElement("dodona-dropdown-filters")
export class DropdownFilters extends ShadowlessLitElement {
    @property( { type: Array })
    filterCollections: [string, FilterCollection][];

    render(): TemplateResult {
        if (!this.filterCollections) {
            return html``;
        }

        return html`
            ${this.filterCollections.map(([type, c]) => html`
                <dodona-dropdown-filter
                    .labels=${c.data}
                    .color=${c.color}
                    .paramVal=${c.paramVal}
                    .param=${c.param}
                    .multi=${c.multi}
                    .type=${type}
                >
                </dodona-dropdown-filter>
            `)}
        `;
    }
}
