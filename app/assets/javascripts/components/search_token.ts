import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { searchQuery } from "search";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { queryParamSelectionMixin } from "mixins/query_param_selection_mixin";

type Label = {id: string, name: string};
@customElement("dodona-search-token")
export abstract class SearchToken extends queryParamSelectionMixin(ShadowlessLitElement) {
    @property()
        labels: Label[] = [];
    @property()
        color: (l: Label) => string;
    @property()
        paramVal: (l: Label) => string;

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
            ${Object.values(this.filterCollections).map(c => html`
                <dodona-search-token
                    .labels=${c.data}
                    .color=${c.color}
                    .paramVal=${c.paramVal}
                    .param=${c.param}
                    .multi=${c.multi}
                >
                </dodona-search-token>
            `)}
        `;
    }
}

