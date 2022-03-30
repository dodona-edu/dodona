import { html, LitElement, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { Toast } from "toast";
import { fetch } from "util.js";

type SearchOption = {search: Record<string, string>, type: string, text: string};
type SearchAction = {
    url: string,
    type: string,
    text: string,
    action: string,
    js: string,
    confirm: string,
    icon: string
};

@customElement("dodona-search-option")
export class SearchOptionElement extends LitElement {
    @property()
    searchOption: SearchOption;
    @property()
    key: number;
    @state()
    private _active = false;

    // don't use shadow dom
    createRenderRoot(): Element {
        return this;
    }

    constructor() {
        super();
        Object.keys(this.searchOption.search).forEach(k => {
            dodona.search_query.query_params.subscribeByKey(k, () => this.setActive());
        });
    }

    setActive(): void {
        this._active = Object.entries(this.searchOption.search).every(([key, value]) => {
            return dodona.search_query.query_params.params.get(key) == value;
        });
    }

    performSearch(): void {
        Object.entries(this.searchOption.search).forEach(([key, value]) => {
            dodona.search_query.query_params.updateParam(key, value);
        });
    }

    render(): TemplateResult {
        return html`
                    <li><span class="dropdown-item-text ">
                        <div class="form-check">
                            <input
                                class="form-check-input"
                                type="checkbox"
                                .checked=${this._active}
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

@customElement("dodona-search-actions")
export class SearchActions extends LitElement {
    @property()
        searchOptions: Array<SearchOption>;
    @property()
        searchActions: Array<SearchAction>;

    // don't use shadow dom
    createRenderRoot(): Element {
        return this;
    }

    performAction(action: SearchAction): boolean {
        if (!action.action && !action.js) {
            return true;
        }

        if (!action.action) {
            eval(action.js);
            return false;
        }

        if (action.confirm === undefined || window.confirm(action.confirm)) {
            const url: string = dodona.search_query.addParametersToUrl(action.action);

            fetch(url, {
                method: "POST",
                headers: { "Content-Type": "application/json" }
            }).then( data => {
                new Toast(data.message);
                if (data.js) {
                    eval(data.js);
                } else {
                    dodona.search_query.resetAllQueryParams();
                }
            });
        }

        return false;
    }


    render(): TemplateResult {
        return html`
            <div class="btn-group hidden actions" id="kebab-menu">
                <a class="btn btn-icon dropdown-toggle" data-bs-toggle="dropdown">
                    <i class="mdi mdi-dots-vertical"></i>
                </a>
                <ul class="dropdown-menu dropdown-menu-end">
                    ${this.searchOptions.length > 0 ? html`
                        <li><h6 class='dropdown-header'>${I18n.t("js.options")}</h6></li>
                    ` : html``}
                    ${this.searchOptions.map((opt, id) => html`
                        <dodona-search-option .searchoption=${opt} .key=${id}>
                        </dodona-search-option>
                    `)}

                    ${this.searchActions.length > 0 ? html`
                        <li><h6 class='dropdown-header'>${I18n.t("js.actions")}</h6></li>
                    ` : html``}
                    ${this.searchActions.map(action => html`
                        <li>
                            <a class="action dropdown-item"
                               href='${action.url ? action.url : "#"}'
                               ${action.type ? "data-type=" + action.type : ""}
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


