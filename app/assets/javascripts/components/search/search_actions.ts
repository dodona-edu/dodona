import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { Toast } from "toast";
import { fetch, ready } from "util.js";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { searchQueryState } from "state/SearchQuery";

export type SearchOption = {search: Record<string, string>, type?: string, text: string};
export type SearchAction = {
    url?: string,
    type?: string,
    text: string,
    action?: string,
    js?: string,
    confirm?: string,
    icon: string
};

const isSearchOption = (opt): opt is SearchOption => (opt as SearchOption).search !== undefined;
const isSearchAction = (act): act is SearchAction => (act as SearchAction).js !== undefined || (act as SearchAction).action !== undefined || (act as SearchAction).url !== undefined;

/**
 * This component represents a SearchOption using a checkbox to be used in a dropdown list
 * The checkbox tracks whether the searchoption is curently active
 *
 * @element d-search-option
 *
 * @prop {SearchOption} searchOption - the search option which can be activated or disabled
 * @prop {number} key - unique identifier used to differentiate from other search options
 */
@customElement("d-search-option")
export class SearchOptionElement extends ShadowlessLitElement {
    @property({ type: Object })
    searchOption: SearchOption;
    @property( { type: Number })
    key: number;

    get active(): boolean {
        return Object.entries(this.searchOption.search).every(([key, value]) => {
            return searchQueryState.queryParams.get(key) == value.toString();
        });
    }

    performSearch(): void {
        if (!this.active) {
            Object.entries(this.searchOption.search).forEach(([key, value]) => {
                searchQueryState.queryParams.set(key, value.toString());
            });
        } else {
            Object.keys(this.searchOption.search).forEach(key => {
                searchQueryState.queryParams.set(key, undefined);
            });
        }
    }

    render(): TemplateResult {
        return html`
                    <li><span class="dropdown-item-text ">
                        <div class="form-check">
                            <input
                                class="form-check-input"
                                type="checkbox"
                                .checked=${this.active}
                                @click="${() => this.performSearch()}"
                                id="check-${this.searchOption.type}-${this.key}"
                            >
                            <label class="form-check-label" for="check-${this.searchOption.type}-${this.key}">
                                ${this.searchOption.text}
                            </label>
                        </div>
                    </span></li>
        `;
    }
}

/**
 * This component represents a dropdown containing a combination of SearchOptions and SearchActions
 *
 * @element d-search-actions
 *
 * @prop {(SearchOption|SearchAction)[]} actions - the array of SearchOptions/Actions to be displayed in the dropdown
 */
@customElement("d-search-actions")
export class SearchActions extends ShadowlessLitElement {
    @property({ type: Array })
    actions: (SearchOption|SearchAction)[] = [];

    getSearchOptions(): Array<SearchOption> {
        return this.actions.filter(isSearchOption);
    }

    getSearchActions(): Array<SearchAction> {
        return this.actions.filter(isSearchAction);
    }

    async performAction(action: SearchAction): Promise<boolean> {
        if (!action.action && !action.js) {
            return true;
        }

        if (!action.action) {
            eval(action.js);
            return false;
        }

        if (action.confirm === undefined || window.confirm(action.confirm)) {
            const url: string = searchQueryState.addParametersToUrl(action.action);

            const response = await fetch(url, {
                method: "POST",
                headers: { "Content-Type": "application/json" }
            });
            const data = await response.json();
            new Toast(data.message);
            if (data.js) {
                eval(data.js);
            } else {
                searchQueryState.arrayQueryParams.clear();
                searchQueryState.queryParams.clear();
            }
        }

        return false;
    }

    constructor() {
        super();

        // Reload when I18n is loaded
        ready.then(() => this.requestUpdate());
    }


    render(): TemplateResult {
        return html`
            <div class="dropdown actions" id="kebab-menu">
                <a class="btn btn-icon dropdown-toggle" data-bs-toggle="dropdown">
                    <i class="mdi mdi-dots-vertical"></i>
                </a>
                <ul class="dropdown-menu dropdown-menu-end">
                    ${this.getSearchOptions().length > 0 ? html`
                        <li><h6 class='dropdown-header'>${I18n.t("js.options")}</h6></li>
                    ` : html``}
                    ${this.getSearchOptions().map((opt, id) => html`
                        <d-search-option .searchOption=${opt}
                                         .key=${id}>
                        </d-search-option>
                    `)}

                    ${this.getSearchActions().length > 0 ? html`
                        <li><h6 class='dropdown-header'>${I18n.t("js.actions")}</h6></li>
                    ` : html``}
                    ${this.getSearchActions().map(action => html`
                        <li>
                            <a class="action dropdown-item"
                               href='${action.url ? action.url : "#"}'
                               data-type="${action.type}"
                               @click=${() => this.performAction(action)}
                            >
                                <i class='mdi mdi-${action.icon} mdi-18'></i>
                                ${action.text}
                            </a>
                        </li>
                    `)}
                </ul>
            </div>
        `;
    }
}
