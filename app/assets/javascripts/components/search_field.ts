import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { createDelayer } from "util.js";
import { unsafeHTML } from "lit/directives/unsafe-html.js";
import { ref } from "lit/directives/ref.js";
import { searchQuery } from "search";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { FilterCollectionElement, Label } from "components/filter_collection_element";

@customElement("dodona-search-field-suggestion")
export abstract class SearchFieldSuggestion extends FilterCollectionElement {
    @property()
    type: string;
    @property()
    filter: string;
    @property({ type: Number })
    index: number;

    getFilterRegExp(): RegExp {
        return new RegExp(this.filter, "gi");
    }

    getFilteredLabels(): Label[] {
        return this.labels
            .filter( l => !this.isSelected(l))
            .filter(l => l.name.match(this.getFilterRegExp()));
    }

    getHighlightedLabel(label: string): string {
        return label.replace(this.getFilterRegExp(), str => `<strong>${str}</strong>`);
    }

    render(): TemplateResult {
        return this.getFilteredLabels().length == 0 ? html`` : html`
            <li>
                <h6 class='dropdown-header'>${I18n.t(`js.${this.type}`)}</h6>
            </li>
            ${ this.getFilteredLabels().map( label => html`
                <li><a class="dropdown-item" href="#" @click=${() => this.select(label)}>
                    ${unsafeHTML(this.getHighlightedLabel(label.name))}
                </a></li>
            `)}
        `;
    }
}

@customElement("dodona-search-field")
export class SearchField extends ShadowlessLitElement {
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
            field.select(field.getFilteredLabels()[0]);
            this.filter = "";
        }
    }

    constructor() {
        super();
        searchQuery.queryParams.subscribeByKey("filter", (k, o, n) => this.filter = n || "");
        this.filter = searchQuery.queryParams.params.get("filter") || "";
        this.delay = createDelayer();
    }

    update(changedProperties: Map<string, unknown>): void {
        if (changedProperties.has("eager") && this.eager) {
            searchQuery.search();
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
        this.delay(() => searchQuery.queryParams.updateParam("filter", this.filter), 300);
    }

    updated(): void {
        this.setHasSuggestions();
    }

    setHasSuggestions(): void {
        this.hasSuggestions = this.suggestionFields.some(s => s.getFilteredLabels().length > 0);
    }

    suggestionFieldChanged(field?: SearchFieldSuggestion): void {
        if (field) {
            this.suggestionFields[field.index] = field;
            this.setHasSuggestions();
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
                ${Object.entries(this.filterCollections).map(([type, c], i) => html`
                    <dodona-search-field-suggestion
                        .labels=${c.data}
                        .type=${type}
                        .filter=${this.filter}
                        .paramVal=${c.paramVal}
                        .param=${c.param}
                        .multi=${c.multi}
                        .index=${i}
                        ${ref(this.suggestionFieldChanged)}
                    >
                    </dodona-search-field-suggestion>
                ` )}
            </ul>
        `;
    }
}
