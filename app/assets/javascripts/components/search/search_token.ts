import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import {
    AccentColor,
    FilterElement,
    Label
} from "components/search/filter_element";
import { FilterCollection } from "components/search/filter_collection";
import { searchQueryState } from "state/SearchQuery";
import { i18n } from "i18n/i18n";

/**
 * This component inherits from FilterCollectionElement.
 * It represent a lists of dismissible tokens, one for each active label
 *
 * @element d-search-token
 *
 * @prop {AccentColor} color - the color associated with the filter
 * @prop {string} param - the searchQuery param to be used for this filter
 * @prop {boolean} multi - whether one or more labels can be selected at the same time
 * @prop {(l: Label) => string} paramVal - a function that extracts the value that should be used in a searchQuery for a selected label
 * @prop {[Label]} labels - all labels that could potentially be selected
 */
@customElement("d-search-token")
export class SearchToken extends FilterElement {
    @property({ type: String })
    color: AccentColor;

    processClick(e: Event, label: Label): void {
        this.unSelect(label);
        e.preventDefault();
    }

    render(): TemplateResult {
        return html`
            ${ this.getSelectedLabels().map( label => html`
                <div class="token accent-${this.color}">
                    <span class="token-label">${label.name}</span>
                    <a href="#" class="close" tabindex="-1"  @click=${e => this.processClick(e, label)}>
                        <i class="mdi mdi-close mdi-18"></i>
                    </a>
                </div>
            `)}
        `;
    }
}

/**
 * This component represents a list of d-search-token
 *
 * @element d-search-tokens
 *
 * @prop {FilterOptions[]} filters - the list of filterOptions for which tokens could be created
 * @prop {string[]} hide - the list of filter params that should never be shown
 */
@customElement("d-search-tokens")
export class SearchTokens extends FilterCollection {
    get activeFilters(): number {
        let count = 0;
        this.visibleFilters.forEach(f => {
            if (f.multi) {
                count += searchQueryState.arrayQueryParams.get(f.param)?.length || 0;
            } else {
                count += searchQueryState.queryParams.get(f.param) ? 1 : 0;
            }
        });
        return count;
    }

    clearAll(): void {
        this.visibleFilters.forEach(f => {
            if (f.multi) {
                searchQueryState.arrayQueryParams.set(f.param, []);
            } else {
                searchQueryState.queryParams.set(f.param, undefined);
            }
        });
    }

    render(): TemplateResult {
        if (!this.visibleFilters) {
            return html``;
        }

        return html`
            ${this.visibleFilters.map(c => html`
                <d-search-token
                    .labels=${c.data}
                    .color=${c.color}
                    .param=${c.param}
                    .multi=${c.multi}
                >
                </d-search-token>
            `)}
            ${this.activeFilters > 0 ? html`
                <div class="help-block ms-1">
                    ${i18n.t("js.search.tokens.active_filters", { smart_count: this.activeFilters })}
                    <a href="#" @click=${() => this.clearAll()}>
                        ${i18n.t("js.search.tokens.clear")}
                    </a>
                </div>
            ` : html``}
        `;
    }
}

