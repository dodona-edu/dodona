import { html, LitElement, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";

type Label = {id: string, name: string};
export abstract class SearchToken extends LitElement {
    @property()
        labels: Label[] = [];
    @property()
        color: (l: Label) => string;
    @property()
        paramVal: (l: Label) => string;
    @property()
        param: string;

    abstract unSelect(label: string): void;
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

    getSelectedLabels(): Label[] {
        return this.labels.filter( l => this.isSelected(this.paramVal(l)));
    }

    render(): TemplateResult {
        return html`
            ${ this.getSelectedLabels().map( label => html`
                <div class="token accent-${this.color(label)}">
                    <span class="token-label">${label.name}</span>
                    <a href="#" class="close" tabindex="-1"  @click=${() => this.unSelect(this.paramVal(label))}>×</a>
                </div>
            `)}
        `;
    }
}

@customElement("dodona-single-search-token")
export class SingleSearchToken extends SearchToken {
    @property({ state: true })
        selected = "";

    unSelect(): void {
        dodona.search_query.query_params.updateParam(this.param, undefined);
    }

    isSelected(label: string): boolean {
        return this.selected === label;
    }

    subscribeToQueryParams(): void {
        this.selected = dodona.search_query.query_params.params.get(this.param);
        dodona.search_query.query_params.subscribeByKey(this.param, (k, o, n) => this.selected = n || "");
    }
}

@customElement("dodona-multi-search-token")
export class MultiSearchToken extends SearchToken {
    @property({ state: true })
        selected: string[] = [];

    unSelect(label: string): void {
        dodona.search_query.array_query_params.updateParam(this.param, this.selected.filter(s => s !== label));
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

@customElement("dodona-search-tokens")
export class SearchTokens extends LitElement {
    @property( { type: Array })
        filterCollections: Record<string, { data: Label[], multi: boolean, color: (l: Label) => string, paramVal: (l: Label) => string, param: string }>;

    // don't use shadow dom
    createRenderRoot(): Element {
        return this;
    }

    render(): TemplateResult {
        if (!this.filterCollections) {
            return html``;
        }

        return html`
            ${Object.values(this.filterCollections).map(c => c.multi ? html`
                <dodona-multi-search-token
                    .labels=${c.data}
                    .color=${c.color}
                    .paramVal=${c.paramVal}
                    .param=${c.param}
                >
                </dodona-multi-search-token>
            ` : html`
                <dodona-single-search-token
                    .labels=${c.data}
                    .color=${c.color}
                    .paramVal=${c.paramVal}
                    .param=${c.param}
                >
                </dodona-single-search-token>
            `)}
        `;
    }
}

