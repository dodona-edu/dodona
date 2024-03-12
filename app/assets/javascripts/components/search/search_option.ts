import { customElement, property } from "lit/decorators.js";
import { DodonaElement } from "components/meta/dodona_element";
import { searchQueryState } from "state/SearchQuery";
import { html, TemplateResult } from "lit";
import { i18n } from "i18n/i18n";

type option = {param: string, label: string};

/**
 * This component represents a boolean option for search using a checkbox
 * The checkbox tracks whether the search option is curently active
 *
 * @element d-search-option
 *
 * @prop {string} param - the name of the search parameter
 * @prop {string} label - the label to be displayed next to the checkbox
 */
@customElement("d-search-option")
export class SearchOptionElement extends DodonaElement {
    @property({ type: String })
    param = "";
    @property({ type: String })
    label = "";

    get active(): boolean {
        return searchQueryState.queryParams.get(this.param) !== undefined;
    }

    toggle(): void {
        if (this.active) {
            searchQueryState.queryParams.set(this.param, undefined);
        } else {
            searchQueryState.queryParams.set(this.param, "true");
        }
    }

    render(): TemplateResult {
        return html`
            <div class="form-check">
                <input
                    class="form-check-input"
                    type="checkbox"
                    .checked=${this.active}
                    @click="${() => this.toggle()}"
                    id="check-${this.param}"
                >
                <label class="form-check-label" for="check-${this.param}">
                    ${this.label}
                </label>
            </div>
        `;
    }
}

/**
 * This component represents a list op boolean options for search
 * The options are displayed in a dropdown
 * Unless there is only one option, in which case it is displayed as a single checkbox
 *
 * @element d-search-options
 *
 * @prop {option[]} options - the list of options to be displayed
 */
@customElement("d-search-options")
export class SearchOptions extends DodonaElement {
    @property({ type: Array })
    options: option[] = [];

    get activeOptions(): option[] {
        return this.options.filter(option => searchQueryState.queryParams.get(option.param) !== undefined);
    }

    render(): TemplateResult {
        if (this.options.length === 0) {
            return html``;
        } else if (this.options.length === 1) {
            return html`<d-search-option param="${this.options[0].param}" label="${this.options[0].label}"></d-search-option>`;
        }


        return html`
            <div class="dropdown dropdown-filter">
                <a class="btn btn-outline dropdown-toggle" href="#" role="button" id="dropdownMenuLink" data-bs-toggle="dropdown" aria-expanded="false">
                    ${this.activeOptions.map( () => html`<i class="mdi mdi-circle mdi-12 mdi-colored-accent accent-deep-purple left-icon"></i>`)}
                    ${i18n.t(`js.dropdown.multi.search_options`)}
                    <i class="mdi mdi-chevron-down mdi-18 right-icon"></i>
                </a>
                <ul class="dropdown-menu" aria-labelledby="dropdownMenuLink">
                    ${this.options.map(o => html`
                        <li><span class="dropdown-item-text ">
                            <d-search-option param="${o.param}" label="${o.label}"></d-search-option>
                        </span></li>
                    `)}
                </ul>
            </div>
        `;
    }
}
