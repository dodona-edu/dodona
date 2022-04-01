import { customElement, property } from "lit/decorators.js";
import { html, LitElement, TemplateResult } from "lit";
import { createDelayer } from "util.js";
import { unsafeHTML } from "lit/directives/unsafe-html.js";

type Label = {id: string, name: string};
export abstract class SearchFieldSuggestion extends LitElement {
    @property()
        labels: Label[] = [];
    @property()
        type: string;
    @property()
        filter: string;
    @property()
        paramVal: (l: Label) => string;
    @property()
        param: string;

    abstract select(label: string): void;
    abstract isSelected(label: string): boolean;
    abstract subscribeToQueryParams(): void;

    // don't use shadow dom
    createRenderRoot(): Element {
        return this;
    }

    update(changedProperties: Map<string, unknown>): void {
        if (changedProperties.has("type") && this.type) {
            this.subscribeToQueryParams();
        }
        super.update(changedProperties);
    }

    getFilterRegExp(): RegExp {
        return new RegExp(this.filter, "gi");
    }

    getFilteredLabels(): Label[] {
        return this.labels
            .filter( l => !this.isSelected(this.paramVal(l)))
            .filter(l => l.name.match(this.getFilterRegExp()));
    }

    getHighlightedLabel(label: string): string {
        return label.replace(this.getFilterRegExp(), str => `<strong>${str}</strong>`);
    }

    render(): TemplateResult {
        return this.getFilteredLabels().length == 0 ? html`` : html`
            <li><h6 class='dropdown-header'>${I18n.t(`js.${this.type}`)}</h6></li>
            ${ this.getFilteredLabels().map( label => html`
                <li><a class="dropdown-item" href="#" @click=${() => this.select(this.paramVal(label))}>
                    ${unsafeHTML(this.getHighlightedLabel(label.name))}
                </a></li>
            `)}
        `;
    }
}

@customElement("dodona-single-search-field-suggestion")
export class SingleSearchFieldSuggestion extends SearchFieldSuggestion {
    @property({ state: true })
        selected = "";

    select(label: string): void {
        dodona.search_query.query_params.updateParam(this.param, label);
    }

    isSelected(label: string): boolean {
        return this.selected === label;
    }

    subscribeToQueryParams(): void {
        this.selected = dodona.search_query.query_params.params.get(this.param);
        dodona.search_query.query_params.subscribeByKey(this.param, (k, o, n) => this.selected = n || "");
    }
}

@customElement("dodona-multi-search-field-suggestion")
export class MultiSearchFieldSuggestion extends SearchFieldSuggestion {
    @property({ state: true })
        selected: string[] = [];

    select(label: string): void {
        dodona.search_query.array_query_params.updateParam(this.param, [...this.selected, label]);
    }

    isSelected(label: string): boolean {
        return this.selected.includes(label);
    }

    subscribeToQueryParams(): void {
        this.selected = dodona.search_query.array_query_params.params.get(this.param) || [];
        dodona.search_query.array_query_params.subscribeByKey(this.param, (k, o, n) => {
            this.selected = n || [];
        });
    }
}


@customElement("dodona-search-field")
export class SearchField extends LitElement {
    @property({ type: String })
        placeholder: string;
    @property({ type: Boolean })
        eager: boolean;
    @property( { type: Array })
        filterCollections: Record<string, { data: Label[], multi: boolean, paramVal: (l: Label) => string, param: string }>;

    @property({ state: true })
        filter?: string = "";
    delay: (f: () => void, s: number) => void;

    // don't use shadow dom
    createRenderRoot(): Element {
        return this;
    }

    constructor() {
        super();
        dodona.search_query.query_params.subscribeByKey("filter", (k, o, n) => this.filter = n || "");
        this.filter = dodona.search_query.query_params.params.get("filter") || "";
        this.delay = createDelayer();
    }

    update(changedProperties: Map<string, unknown>): void {
        if (changedProperties.has("eager") && this.eager) {
            dodona.search_query.search();
        }
        super.update(changedProperties);
    }

    keyup(e: KeyboardEvent): void {
        this.filter = (e.target as HTMLInputElement).value;
        this.delay(() => dodona.search_query.query_params.updateParam("filter", this.filter), 300);
    }

    render(): TemplateResult {
        return html`
            <input
                type='text'
                class='search-filter'
                placeholder=${this.placeholder}
                name='filter'
                autocomplete="off"
                .value=${this.filter}
                @keyup=${e => this.keyup(e)}
            />
            <ul class="dropdown-menu ${this.filter ? "show-search-dropdown" : ""}">
                ${Object.entries(this.filterCollections).map(([type, c]) => c.multi ? html`
                    <dodona-multi-search-field-suggestion
                        .labels=${c.data}
                        .type=${type}
                        .filter=${this.filter}
                        .paramVal=${c.paramVal}
                        .param=${c.param}
                    >
                    </dodona-multi-search-field-suggestion>
                ` : html`
                    <dodona-single-search-field-suggestion
                        .labels=${c.data}
                        .type=${type}
                        .filter=${this.filter}
                        .paramVal=${c.paramVal}
                        .param=${c.param}
                    >
                    </dodona-single-search-field-suggestion>
                `)}
            </ul>
        `;
    }
}
