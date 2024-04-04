import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import {
    AccentColor,
    FilterCollection,
    FilterCollectionElement,
    Label
} from "components/search/filter_collection_element";
import { DodonaElement } from "components/meta/dodona_element";

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
export class SearchToken extends FilterCollectionElement {
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
 * @prop {Record<string, FilterCollection>} filterCollections - the filter collections for which tokens should be shown
 */
@customElement("d-search-tokens")
export class SearchTokens extends DodonaElement {
    @property( { type: Array })
    filterCollections: Record<string, FilterCollection>;

    render(): TemplateResult {
        if (!this.filterCollections) {
            return html``;
        }

        return html`
            ${Object.values(this.filterCollections).map(c => html`
                <d-search-token
                    .labels=${c.data}
                    .color=${c.color}
                    .param=${c.param}
                    .multi=${c.multi}
                >
                </d-search-token>
            `)}
        `;
    }
}

