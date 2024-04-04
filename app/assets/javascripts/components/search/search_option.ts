import { customElement, property } from "lit/decorators.js";
import { DodonaElement } from "components/meta/dodona_element";
import { searchQueryState } from "state/SearchQuery";
import { html, TemplateResult } from "lit";

export type Option = {param: string, label: string};

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
export class SearchOption extends DodonaElement {
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
 *
 * @element d-search-options
 *
 * @prop {Option[]} options - the list of options to be displayed
 */
@customElement("d-search-options")
export class SearchOptions extends DodonaElement {
    @property({ type: Array })
    options: Option[] = [];

    render(): TemplateResult {
        if (this.options.length === 0) {
            return html``;
        }

        return html`
            <div class="dropdown">
                <a class="btn btn-icon dropdown-toggle" data-bs-toggle="dropdown">
                    <i class="mdi mdi-dots-vertical"></i>
                </a>
                <ul class="dropdown-menu dropdown-menu-end">
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
