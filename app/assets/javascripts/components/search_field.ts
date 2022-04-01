import { customElement, property } from "lit/decorators.js";
import { html, LitElement, TemplateResult } from "lit";
import { createDelayer } from "util.js";
import { unsafeHTML } from "lit/directives/unsafe-html.js";
import { ref } from "lit/directives/ref.js";

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
    @property({ type: Number })
        index: number;

    abstract select(label: string): void;
    abstract isSelected(label: string): boolean;
    abstract subscribeToQueryParams(): void;

    // don't use shadow dom
    createRenderRoot(): Element {
        return this;
    }

    update(changedProperties: Map<string, unknown>): void {
        if (changedProperties.has("param") && this.param) {
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
        dodona.search_query.query_params.updateParam("filter", undefined);
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
        dodona.search_query.query_params.updateParam("filter", undefined);
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
    @property({ state: true })
        suggestionFields: SearchFieldSuggestion[] = [];
    @property({ state: true })
        hasSuggestions: boolean;

    delay: (f: () => void, s: number) => void;

    tabComplete(): void {
        if (this.hasSuggestions) {
            const field = this.suggestionFields.find(s => s.getFilteredLabels().length > 0);
            field.select(field.paramVal(field.getFilteredLabels()[0]));
            this.filter = "";
        }
    }

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

    keydown(e: KeyboardEvent): void {
        if (e.key === "Tab") {
            e.preventDefault();
        }
    }

    keyup(e: KeyboardEvent): void {
        this.filter = (e.target as HTMLInputElement).value;
        if (e.key === "Tab") {
            this.tabComplete();
        }
        this.delay(() => dodona.search_query.query_params.updateParam("filter", this.filter), 300);
    }

    suggestionFieldChanged(field?: SearchFieldSuggestion): void {
        if (field) {
            this.suggestionFields[field.index] = field;
            this.hasSuggestions = this.suggestionFields.some(s => s.getFilteredLabels().length > 0);
        }
    }

    render(): TemplateResult {
        if (!this.filterCollections) {
            return html``;
        }

        return html`
            <input
                type='text'
                class='search-filter'
                placeholder=${this.placeholder}
                name='filter'
                autocomplete="off"
                .value=${this.filter}
                @keyup=${e => this.keyup(e)}
                @keydown=${e => this.keydown(e)}
            />
            <ul class="dropdown-menu ${this.filter && this.hasSuggestions ? "show-search-dropdown" : ""}">
                ${Object.entries(this.filterCollections).map(([type, c], i) => c.multi ? html`
                    <dodona-multi-search-field-suggestion
                        .labels=${c.data}
                        .type=${type}
                        .filter=${this.filter}
                        .paramVal=${c.paramVal}
                        .param=${c.param}
                        .index=${i}
                        ${ref(this.suggestionFieldChanged)}
                    >
                    </dodona-multi-search-field-suggestion>
                ` : html`
                    <dodona-single-search-field-suggestion
                        .labels=${c.data}
                        .type=${type}
                        .filter=${this.filter}
                        .paramVal=${c.paramVal}
                        .param=${c.param}
                        .index=${i}
                        ${ref(this.suggestionFieldChanged)}
                    >
                    </dodona-single-search-field-suggestion>
                `)}
            </ul>
        `;
    }
}
