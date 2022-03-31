import { customElement, property } from "lit/decorators.js";
import { html, LitElement, TemplateResult } from "lit";
import { createDelayer } from "util.js";

@customElement("dodona-search-field")
export class SearchField extends LitElement {
    @property({ type: String })
        placeholder: string;
    @property({ type: Boolean })
        eager: boolean;

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
                id='filter-query'
                placeholder=${this.placeholder}
                name='filter'
                autocomplete="off"
                .value=${this.filter}
                @keyup=${e => this.keyup(e)}
            />
        `;
    }
}
