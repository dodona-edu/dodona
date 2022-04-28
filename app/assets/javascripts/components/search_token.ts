import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { searchQuery } from "search";
import { ShadowlessLitElement } from "components/shadowless_lit_element";

type Label = {id: string, name: string};
export abstract class SearchToken extends ShadowlessLitElement {
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

    update(changedProperties: Map<string, unknown>): void {
        if (changedProperties.has("param") && this.param) {
            this.subscribeToQueryParams();
        }
        super.update(changedProperties);
    }

    getSelectedLabels(): Label[] {
        return this.labels.filter( l => this.isSelected(this.paramVal(l).toString()));
    }

    render(): TemplateResult {
        return html`
            ${ this.getSelectedLabels().map( label => html`
                <div class="token accent-${this.color(label)}">
                    <span class="token-label">${label.name}</span>
                    <a href="#" class="close" tabindex="-1"  @click=${() => this.unSelect(this.paramVal(label).toString())}>×</a>
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
        searchQuery.queryParams.updateParam(this.param, undefined);
    }

    isSelected(label: string): boolean {
        return this.selected === label;
    }

    subscribeToQueryParams(): void {
        this.selected = searchQuery.queryParams.params.get(this.param);
        searchQuery.queryParams.subscribeByKey(this.param, (k, o, n) => this.selected = n || "");
    }
}

@customElement("dodona-multi-search-token")
export class MultiSearchToken extends SearchToken {
    @property({ state: true })
        selected: string[] = [];

    unSelect(label: string): void {
        searchQuery.arrayQueryParams.updateParam(this.param, this.selected.filter(s => s !== label));
    }

    isSelected(label: string): boolean {
        return this.selected.includes(label);
    }

    subscribeToQueryParams(): void {
        this.selected = searchQuery.arrayQueryParams.params.get(this.param) || [];
        searchQuery.arrayQueryParams.subscribeByKey(this.param, (k, o, n) => {
            this.selected = n || [];
        });
    }
}

type filterCollection = {
    data: Label[],
    multi: boolean,
    color: (l: Label) => string,
    paramVal: (l: Label) => string,
    param: string
};

@customElement("dodona-search-tokens")
export class SearchTokens extends ShadowlessLitElement {
    @property( { type: Array })
        filterCollections: Record<string, filterCollection>;

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

