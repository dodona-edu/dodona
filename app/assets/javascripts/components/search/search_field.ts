import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { createDelayer } from "utilities";
import { unsafeHTML } from "lit/directives/unsafe-html.js";
import { ref } from "lit/directives/ref.js";
import { FilterElement, Label } from "components/search/filter_element";
import { searchQueryState } from "state/SearchQuery";
import { search } from "search";
import { i18n } from "i18n/i18n";
import { FilterCollection } from "components/search/filter_collection";
/**
 * This component inherits from FilterCollectionElement.
 * It represents a list of filters to be used in a dropdown as typeahead suggestions
 *
 * @element d-search-field-suggestion
 *
 * @prop {string} filter - The string for which typeahead suggestions should be provided
 * @prop {number} index - bookkeeping param to remember the order across multiple elements
 * @prop {string} param - the searchQuery param to be used for this filter
 * @prop {boolean} multi - whether one or more labels can be selected at the same time
 * @prop {(l: Label) => string} paramVal - a function that extracts the value that should be used in a searchQuery for a selected label
 * @prop {[Label]} labels - all labels that could potentially be selected
 */
@customElement("d-search-field-suggestion")
export class SearchFieldSuggestion extends FilterElement {
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

    handleClick(e: Event, label: Label): void {
        e.preventDefault();
        this.select(label);
        searchQueryState.queryParams.set("filter", undefined);
    }

    render(): TemplateResult {
        return this.getFilteredLabels().length == 0 ? html`` : html`
            <li>
                <h6 class='dropdown-header'>${i18n.t(`js.search.filter.${this.param}`)}</h6>
            </li>
            ${ this.getFilteredLabels().map( label => html`
                <li><a class="dropdown-item" href="#" @click=${e => this.handleClick(e, label)}>
                    ${unsafeHTML(this.getHighlightedLabel(label.name))}
                    ${label.count ? html`<span class="text-muted float-end ms-4">${label.count}</span>` : ""}
                </a></li>
            `)}
        `;
    }
}

/**
 * This component represents a searchfield with typeahead suggestion
 * It interacts with SearchQuery to set and get the currently active filters
 *
 * @element d-search-field
 *
 * @prop {string} placeholder - The placeholder text for an empty searchfield
 * @prop {boolean} eager - if true a search will be run before user input happens
 * @prop {FilterOptions[]} filters - The list of filter lists to be used as search suggestions
 * @prop {string[]} hide - The list of filter lists to be ignored as search suggestions
 *  - The list of filter lists to be used as search suggestions
 */
@customElement("d-search-field")
export class SearchField extends FilterCollection {
    @property({ type: String })
    placeholder: string;

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
        this.delay = createDelayer();
    }

    firstUpdated(): void {
        const setFilter = (): string => this.filter = searchQueryState.queryParams.get("filter") || "";
        searchQueryState.queryParams.subscribe(setFilter, "filter");
        setFilter();
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
        this.delay(() => searchQueryState.queryParams.set("filter", this.filter), 300);
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
        if (!this.visibleFilters) {
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
                ${this.visibleFilters.map((c, i) => html`
                    <d-search-field-suggestion
                        .labels=${c.data}
                        .filter=${this.filter}
                        .param=${c.param}
                        .multi=${c.multi}
                        .index=${i}
                        ${ref(this.suggestionFieldChanged)}
                    >
                    </d-search-field-suggestion>
                ` )}
            </ul>
        `;
    }
}
